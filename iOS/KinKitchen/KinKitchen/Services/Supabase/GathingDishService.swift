//
//  GathingDishService.swift
//  KinKitchen
//
//  Created by Greg Hudler on 9/10/26.
//

import Foundation
import Supabase

enum GatheringDishService {

    // MARK: - Gathering Needs

    static func createNeed(
        gatheringId: UUID,
        name: String,
        category: DishCategory,
        quantityNeeded: Int = 1,
        recipeId: UUID? = nil,
        notes: String? = nil,
        needs: Set<DishNeed> = [],
        otherNeedDescription: String? = nil,
        supplies: Set<DishSupply> = []
    ) async throws -> GatheringNeed {

        let cleanedName = name.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        guard !cleanedName.isEmpty else {
            throw GatheringDishServiceError.invalidName
        }

        guard quantityNeeded > 0 else {
            throw GatheringDishServiceError.invalidQuantity
        }

        let payload = GatheringNeedCreate(
            gatheringId: gatheringId,
            category: category,
            name: cleanedName,
            quantityNeeded: quantityNeeded,
            recipeId: recipeId,
            notes: cleanedOptionalString(notes)
        )

        let createdNeed: GatheringNeed =
            try await SupabaseManager.client
                .from("gathering_needs")
                .insert(payload)
                .select()
                .single()
                .execute()
                .value

        do {
            if !needs.isEmpty {
                let needPayloads = needs.map {
                    GatheringNeedRequirementCreate(
                        gatheringNeedId: createdNeed.id,
                        need: $0,
                        description:
                            $0 == .other
                            ? cleanedOptionalString(
                                otherNeedDescription
                            )
                            : nil
                    )
                }

                try await SupabaseManager.client
                    .from("gathering_need_needs")
                    .insert(needPayloads)
                    .execute()
            }

            if !supplies.isEmpty {
                let supplyPayloads = supplies.map {
                    GatheringNeedSupplyCreate(
                        gatheringNeedId: createdNeed.id,
                        supply: $0
                    )
                }

                try await SupabaseManager.client
                    .from("gathering_need_supplies")
                    .insert(supplyPayloads)
                    .execute()
            }

            return createdNeed

        } catch {

            try? await SupabaseManager.client
                .from("gathering_needs")
                .delete()
                .eq(
                    "id",
                    value: createdNeed.id
                )
                .execute()

            throw error
        }
    }

    static func fetchNeeds(
        gatheringId: UUID
    ) async throws -> [GatheringNeed] {

        let needs: [GatheringNeed] =
            try await SupabaseManager.client
                .from("gathering_needs")
                .select()
                .eq(
                    "gathering_id",
                    value: gatheringId
                )
                .order(
                    "created_at",
                    ascending: true
                )
                .execute()
                .value

        return needs
    }

    static func fetchNeed(
        id needId: UUID
    ) async throws -> GatheringNeed {

        let need: GatheringNeed =
            try await SupabaseManager.client
                .from("gathering_needs")
                .select()
                .eq(
                    "id",
                    value: needId
                )
                .single()
                .execute()
                .value

        return need
    }

    static func updateNeed(
        id needId: UUID,
        name: String,
        category: DishCategory,
        quantityNeeded: Int,
        recipeId: UUID?,
        notes: String?,
        needs: Set<DishNeed>,
        supplies: Set<DishSupply>
    ) async throws -> GatheringNeed {

        let cleanedName = name.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        guard !cleanedName.isEmpty else {
            throw GatheringDishServiceError.invalidName
        }

        guard quantityNeeded > 0 else {
            throw GatheringDishServiceError.invalidQuantity
        }

        let claimedQuantity =
            try await totalClaimedQuantity(
                needId: needId
            )

        guard quantityNeeded >= claimedQuantity else {
            throw GatheringDishServiceError.quantityBelowClaims
        }

        let payload = GatheringNeedUpdate(
            category: category,
            name: cleanedName,
            quantityNeeded: quantityNeeded,
            recipeId: recipeId,
            notes: cleanedOptionalString(notes)
        )

        let updatedNeed: GatheringNeed =
            try await SupabaseManager.client
                .from("gathering_needs")
                .update(payload)
                .eq(
                    "id",
                    value: needId
                )
                .select()
                .single()
                .execute()
                .value

        try await replaceNeedRequirements(
            needId: needId,
            needs: needs
        )

        try await replaceNeedSupplies(
            needId: needId,
            supplies: supplies
        )

        return updatedNeed
    }

    static func deleteNeed(
        id needId: UUID
    ) async throws {

        try await SupabaseManager.client
            .from("gathering_needs")
            .delete()
            .eq(
                "id",
                value: needId
            )
            .execute()
    }
    
    // MARK: - Duplicate Dish Comparison

    static func findPotentialDuplicateNeed(
        gatheringId: UUID,
        proposedName: String
    ) async -> GatheringNeed? {
        let normalizedProposedName =
            normalizedDishName(
                proposedName
            )

        guard !normalizedProposedName.isEmpty else {
            return nil
        }

        do {
            let existingNeeds =
                try await fetchNeeds(
                    gatheringId: gatheringId
                )

            let dishNeeds =
                existingNeeds.filter {
                    !isStandaloneSupplyNeed($0)
                }

            if let exactMatch =
                dishNeeds.first(
                    where: {
                        normalizedDishName(
                            $0.name
                        ) == normalizedProposedName
                    }
                ) {
                return exactMatch
            }

            let proposedWords =
                dishWords(
                    normalizedProposedName
                )

            guard !proposedWords.isEmpty else {
                return nil
            }

            var bestMatch:
                GatheringNeed?

            var bestScore = 0.0

            for existingNeed in dishNeeds {
                let normalizedExistingName =
                    normalizedDishName(
                        existingNeed.name
                    )

                let existingWords =
                    dishWords(
                        normalizedExistingName
                    )

                guard !existingWords.isEmpty else {
                    continue
                }

                let sharedWords =
                    proposedWords.intersection(
                        existingWords
                    )

                guard !sharedWords.isEmpty else {
                    continue
                }

                let longestCount =
                    max(
                        proposedWords.count,
                        existingWords.count
                    )

                let wordScore =
                    Double(sharedWords.count) /
                    Double(longestCount)

                let containsName =
                    normalizedProposedName.contains(
                        normalizedExistingName
                    ) ||
                    normalizedExistingName.contains(
                        normalizedProposedName
                    )

                let score =
                    containsName
                    ? max(wordScore, 0.75)
                    : wordScore

                if score >= 0.60,
                   score > bestScore {
                    bestScore = score
                    bestMatch = existingNeed
                }
            }

            return bestMatch

        } catch {
            return nil
        }
    }

    private static func normalizedDishName(
        _ name: String
    ) -> String {
        name
            .folding(
                options: [
                    .diacriticInsensitive,
                    .caseInsensitive
                ],
                locale: .current
            )
            .lowercased()
            .components(
                separatedBy:
                    CharacterSet
                        .alphanumerics
                        .inverted
            )
            .filter {
                !$0.isEmpty
            }
            .joined(
                separator: " "
            )
    }

    private static func dishWords(
        _ normalizedName: String
    ) -> Set<String> {
        let ignoredWords: Set<String> = [
            "a",
            "an",
            "and",
            "of",
            "the",
            "with"
        ]

        return Set(
            normalizedName
                .split(
                    separator: " "
                )
                .map(String.init)
                .filter {
                    !ignoredWords.contains($0)
                }
        )
    }

    private static func isStandaloneSupplyNeed(
        _ need: GatheringNeed
    ) -> Bool {
        DishSupply.allCases.contains {
            $0.displayName
                .caseInsensitiveCompare(
                    need.name
                ) == .orderedSame
        } &&
        need.category == .other &&
        need.recipeId == nil
    }

    // MARK: - Dish Needs

    static func fetchNeedRequirements(
        needId: UUID
    ) async throws -> [GatheringNeedRequirement] {

        let requirements: [GatheringNeedRequirement] =
            try await SupabaseManager.client
                .from("gathering_need_needs")
                .select()
                .eq(
                    "gathering_need_id",
                    value: needId
                )
                .execute()
                .value

        return requirements
    }

    static func replaceNeedRequirements(
        needId: UUID,
        needs: Set<DishNeed>,
        otherNeedDescription: String? = nil
    ) async throws {
        try await SupabaseManager.client
            .from("gathering_need_needs")
            .delete()
            .eq(
                "gathering_need_id",
                value: needId
            )
            .execute()

        guard !needs.isEmpty else {
            return
        }

        let payloads = needs.map {
            GatheringNeedRequirementCreate(
                gatheringNeedId: needId,
                need: $0,
                description:
                    $0 == .other
                    ? cleanedOptionalString(
                        otherNeedDescription
                    )
                    : nil
            )
        }

        try await SupabaseManager.client
            .from("gathering_need_needs")
            .insert(payloads)
            .execute()
    }

    // MARK: - Dish Supplies

    static func fetchNeedSupplies(
        needId: UUID
    ) async throws -> [GatheringNeedSupply] {

        let supplies: [GatheringNeedSupply] =
            try await SupabaseManager.client
                .from("gathering_need_supplies")
                .select()
                .eq(
                    "gathering_need_id",
                    value: needId
                )
                .execute()
                .value

        return supplies
    }

    static func replaceNeedSupplies(
        needId: UUID,
        supplies: Set<DishSupply>
    ) async throws {

        try await SupabaseManager.client
            .from("gathering_need_supplies")
            .delete()
            .eq(
                "gathering_need_id",
                value: needId
            )
            .execute()

        guard !supplies.isEmpty else {
            return
        }

        let payloads = supplies.map {
            GatheringNeedSupplyCreate(
                gatheringNeedId: needId,
                supply: $0
            )
        }

        try await SupabaseManager.client
            .from("gathering_need_supplies")
            .insert(payloads)
            .execute()
    }

    // MARK: - Claims

    static func fetchClaims(
        needId: UUID
    ) async throws -> [GatheringNeedClaim] {

        let claims: [GatheringNeedClaim] =
            try await SupabaseManager.client
                .from("gathering_need_claims")
                .select()
                .eq(
                    "gathering_need_id",
                    value: needId
                )
                .order(
                    "created_at",
                    ascending: true
                )
                .execute()
                .value

        return claims
    }

    static func fetchClaims(
        gatheringNeedIds: [UUID]
    ) async throws -> [GatheringNeedClaim] {

        var claims: [GatheringNeedClaim] = []

        for needId in gatheringNeedIds {
            let needClaims =
                try await fetchClaims(
                    needId: needId
                )

            claims.append(
                contentsOf: needClaims
            )
        }

        return claims
    }

    static func claimNeed(
        id needId: UUID,
        quantity: Int = 1
    ) async throws -> GatheringNeedClaim {
        guard quantity > 0 else {
            throw GatheringDishServiceError.invalidQuantity
        }

        let params = ClaimNeedParameters(
            needId: needId,
            quantity: quantity
        )

        let claims: [GatheringNeedClaim] =
            try await SupabaseManager.client
                .rpc(
                    "claim_gathering_need",
                    params: params
                )
                .execute()
                .value

        guard let claim = claims.first else {
            throw GatheringDishServiceError.claimNotReturned
        }

        return claim
    }

    static func unclaimNeed(
        id needId: UUID
    ) async throws -> GatheringNeedClaim {
        let params = UnclaimNeedParameters(
            needId: needId
        )

        let claim: GatheringNeedClaim =
            try await SupabaseManager.client
                .rpc(
                    "unclaim_gathering_need",
                    params: params
                )
                .execute()
                .value

        return claim
    }

    static func changeClaim(
        from currentNeedId: UUID,
        to newNeedId: UUID,
        quantity: Int = 1
    ) async throws -> GatheringNeedClaim {
        guard quantity > 0 else {
            throw GatheringDishServiceError.invalidQuantity
        }

        let params = ChangeClaimParameters(
            currentNeedId: currentNeedId,
            newNeedId: newNeedId,
            quantity: quantity
        )

        let claim: GatheringNeedClaim =
            try await SupabaseManager.client
                .rpc(
                    "change_gathering_need_claim",
                    params: params
                )
                .execute()
                .value

        return claim
    }

    static func totalClaimedQuantity(
        needId: UUID
    ) async throws -> Int {

        let claims =
            try await fetchClaims(
                needId: needId
            )

        return claims.reduce(0) {
            $0 + $1.quantity
        }
    }

    static func remainingQuantity(
        for need: GatheringNeed
    ) async throws -> Int {

        let claimed =
            try await totalClaimedQuantity(
                needId: need.id
            )

        return max(
            need.quantityNeeded - claimed,
            0
        )
    }

    // MARK: - Gathering Dishes

    static func createDish(
        gatheringId: UUID,
        name: String,
        category: DishCategory,
        recipeId: UUID? = nil,
        gatheringNeedId: UUID? = nil,
        notes: String? = nil
    ) async throws -> GatheringDish {

        let user =
            try await SupabaseManager.client
                .auth
                .session
                .user

        let cleanedName = name.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        guard !cleanedName.isEmpty else {
            throw GatheringDishServiceError.invalidName
        }

        let payload = GatheringDishCreate(
            gatheringId: gatheringId,
            userId: user.id,
            recipeId: recipeId,
            gatheringNeedId: gatheringNeedId,
            name: cleanedName,
            category: category,
            notes: cleanedOptionalString(notes)
        )

        let dish: GatheringDish =
            try await SupabaseManager.client
                .from("gathering_dishes")
                .insert(payload)
                .select()
                .single()
                .execute()
                .value

        return dish
    }

    static func fetchDishes(
        gatheringId: UUID
    ) async throws -> [GatheringDish] {

        let dishes: [GatheringDish] =
            try await SupabaseManager.client
                .from("gathering_dishes")
                .select()
                .eq(
                    "gathering_id",
                    value: gatheringId
                )
                .order(
                    "created_at",
                    ascending: true
                )
                .execute()
                .value

        return dishes
    }

    static func fetchDish(
        id dishId: UUID
    ) async throws -> GatheringDish {

        let dish: GatheringDish =
            try await SupabaseManager.client
                .from("gathering_dishes")
                .select()
                .eq(
                    "id",
                    value: dishId
                )
                .single()
                .execute()
                .value

        return dish
    }

    static func updateDish(
        id dishId: UUID,
        name: String,
        category: DishCategory,
        recipeId: UUID?,
        gatheringNeedId: UUID?,
        notes: String?
    ) async throws -> GatheringDish {

        let user =
            try await SupabaseManager.client
                .auth
                .session
                .user

        let cleanedName = name.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        guard !cleanedName.isEmpty else {
            throw GatheringDishServiceError.invalidName
        }

        let payload = GatheringDishUpdate(
            recipeId: recipeId,
            gatheringNeedId: gatheringNeedId,
            name: cleanedName,
            category: category,
            notes: cleanedOptionalString(notes)
        )

        let dish: GatheringDish =
            try await SupabaseManager.client
                .from("gathering_dishes")
                .update(payload)
                .eq(
                    "id",
                    value: dishId
                )
                .eq(
                    "user_id",
                    value: user.id
                )
                .select()
                .single()
                .execute()
                .value

        return dish
    }

    static func deleteDish(
        id dishId: UUID
    ) async throws {

        let user =
            try await SupabaseManager.client
                .auth
                .session
                .user

        try await SupabaseManager.client
            .from("gathering_dishes")
            .delete()
            .eq(
                "id",
                value: dishId
            )
            .eq(
                "user_id",
                value: user.id
            )
            .execute()
    }

    // MARK: - Helpers

    private static func cleanedOptionalString(
        _ value: String?
    ) -> String? {

        guard let value else {
            return nil
        }

        let cleaned = value.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        return cleaned.isEmpty
            ? nil
            : cleaned
    }
}

// MARK: - Need Requirement Payload

private struct GatheringNeedRequirementCreate: Encodable {
    let gatheringNeedId: UUID
    let need: DishNeed
    let description: String?

    enum CodingKeys: String, CodingKey {
        case gatheringNeedId = "gathering_need_id"
        case need
        case description
    }
}

// MARK: - Need Supply Payload

private struct GatheringNeedSupplyCreate: Encodable {
    let gatheringNeedId: UUID
    let supply: DishSupply

    enum CodingKeys: String, CodingKey {
        case gatheringNeedId = "gathering_need_id"
        case supply
    }
}

// MARK: - Claim Parameters

private struct ClaimNeedParameters: Encodable {
    let needId: UUID
    let quantity: Int

    enum CodingKeys: String, CodingKey {
        case needId = "p_need_id"
        case quantity = "p_quantity"
    }
}

private struct UnclaimNeedParameters: Encodable {
    let needId: UUID

    enum CodingKeys: String, CodingKey {
        case needId = "p_need_id"
    }
}

private struct ChangeClaimParameters: Encodable {
    let currentNeedId: UUID
    let newNeedId: UUID
    let quantity: Int

    enum CodingKeys: String, CodingKey {
        case currentNeedId = "p_current_need_id"
        case newNeedId = "p_new_need_id"
        case quantity = "p_quantity"
    }
}

// MARK: - Errors

enum GatheringDishServiceError: LocalizedError {
    case invalidName
    case invalidQuantity
    case quantityBelowClaims
    case claimNotReturned

    var errorDescription: String? {
        switch self {
        case .invalidName:
            return "Dish name cannot be empty."

        case .invalidQuantity:
            return "Quantity must be at least 1."

        case .quantityBelowClaims:
            return "Quantity cannot be lower than the amount already claimed."

        case .claimNotReturned:
            return "The dish claim could not be completed."
        }
    }
}

//
//  RecipientDietaryService.swift
//  KinKitchen
//
//  Created by Greg Hudler on 9/20/26.
//

import Foundation
import Supabase

// MARK: - Recipient Dietary Service

enum RecipientDietaryService {
    static func fetchDietaryInformation(
        for recipientId: UUID
    ) async throws -> RecipientDietaryInformation {
        async let allergenResult =
            fetchAllergens(
                for: recipientId
            )

        async let restrictionResult =
            fetchRestrictions(
                for: recipientId
            )

        async let preferenceResult =
            fetchPreferences(
                for: recipientId
            )

        return try await RecipientDietaryInformation(
            userId: recipientId,
            allergens: allergenResult,
            restrictions: restrictionResult,
            preferences: preferenceResult
        )
    }
}

// MARK: - Allergens

private extension RecipientDietaryService {
    static func fetchAllergens(
        for recipientId: UUID
    ) async throws -> [Allergen] {
        let selections: [RecipientAllergenSelection] =
            try await SupabaseManager.client
                .from("user_allergens")
                .select(
                    """
                    allergen:allergens(
                        id,
                        name,
                        created_at
                    )
                    """
                )
                .eq(
                    "user_id",
                    value: recipientId
                )
                .execute()
                .value

        return selections.map(
            \.allergen
        )
    }
}

// MARK: - Restrictions

private extension RecipientDietaryService {
    static func fetchRestrictions(
        for recipientId: UUID
    ) async throws -> [DietaryRestriction] {
        let selections: [RecipientRestrictionSelection] =
            try await SupabaseManager.client
                .from("user_dietary_restrictions")
                .select(
                    """
                    restriction:dietary_restrictions(
                        id,
                        name,
                        created_at
                    )
                    """
                )
                .eq(
                    "user_id",
                    value: recipientId
                )
                .execute()
                .value

        return selections.map(
            \.restriction
        )
    }
}

// MARK: - Preferences

private extension RecipientDietaryService {
    static func fetchPreferences(
        for recipientId: UUID
    ) async throws -> [DietaryPreference] {
        let selections: [RecipientPreferenceSelection] =
            try await SupabaseManager.client
                .from("user_dietary_preferences")
                .select(
                    """
                    preference:dietary_preferences(
                        id,
                        name,
                        created_at
                    )
                    """
                )
                .eq(
                    "user_id",
                    value: recipientId
                )
                .execute()
                .value

        return selections.map(
            \.preference
        )
    }
}

// MARK: - Query Models

private struct RecipientAllergenSelection: Decodable {
    let allergen: Allergen
}

private struct RecipientRestrictionSelection: Decodable {
    let restriction: DietaryRestriction
}

private struct RecipientPreferenceSelection: Decodable {
    let preference: DietaryPreference
}

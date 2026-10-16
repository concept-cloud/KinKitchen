//
//  EventDietaryService.swift
//  KinKitchen
//
//  Created by Greg Hudler on 10/15/26.
//

import Foundation
import Supabase

/// Dietary needs added straight to an event
/// (supabase/REGRESSION-event-dietary-needs).
enum EventDietaryService {

    static func fetchNeeds(
        gatheringId: UUID
    ) async throws -> [EventDietaryNeed] {

        let needs: [EventDietaryNeed] =
            try await SupabaseManager.client
                .from("gathering_dietary_needs")
                .select("kind, catalog_id, name")
                .eq("gathering_id", value: gatheringId)
                .execute()
                .value

        return needs.sortedForDisplay
    }

    /// Replaces the event's list. Host only.
    static func saveNeeds(
        _ needs: [EventDietaryNeed],
        gatheringId: UUID
    ) async throws {

        struct Parameters: Encodable {
            let gatheringId: UUID
            let needs: [EventDietaryNeed]

            enum CodingKeys: String, CodingKey {
                case gatheringId = "p_gathering_id"
                case needs = "p_needs"
            }
        }

        try await SupabaseManager.client
            .rpc(
                "set_gathering_dietary_needs",
                params: Parameters(
                    gatheringId: gatheringId,
                    needs: needs
                )
            )
            .execute()
    }

    /// Checks a recipe against the event's needs. nil when the event
    /// has none.
    static func checkRecipe(
        recipeId: UUID,
        against needs: [EventDietaryNeed],
        gatheringId: UUID
    ) async throws -> RecipientRecipeDietaryCheckResult? {

        guard !needs.isEmpty else {
            return nil
        }

        return try await RecipeDietaryCheckService.checkRecipe(
            recipeId: recipeId,
            against: needs.dietaryInformation(eventId: gatheringId)
        )
    }
}

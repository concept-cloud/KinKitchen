//
//  ProfileStatsService.swift
//  KinKitchen
//
//  Created by Greg Hudler on 10/15/26.
//

import Foundation
import Supabase

/// A user's numbers for their profile (`profile_stats`): how many
/// recipes, cookbooks and shared recipes they have, and the family
/// rating other people gave their recipes.
struct ProfileStats: Decodable, Equatable {

    let recipeCount: Int
    let cookbookCount: Int
    let sharedRecipeCount: Int
    /// nil when there are no ratings yet, or when it's someone else's
    /// private rating.
    let ratingAverage: Double?
    let ratingCount: Int?
    var ratingIsPublic: Bool

    enum CodingKeys: String, CodingKey {
        case recipeCount = "recipe_count"
        case cookbookCount = "cookbook_count"
        case sharedRecipeCount = "shared_recipe_count"
        case ratingAverage = "rating_average"
        case ratingCount = "rating_count"
        case ratingIsPublic = "rating_is_public"
    }
}

enum ProfileStatsService {

    private struct VisibilityUpdate: Encodable {
        let ratingIsPublic: Bool

        enum CodingKeys: String, CodingKey {
            case ratingIsPublic = "rating_is_public"
        }
    }

    /// The signed-in user's stats.
    static func fetchStats() async throws -> ProfileStats? {
        let rows: [ProfileStats] =
            try await SupabaseManager.client
                .rpc("profile_stats")
                .execute()
                .value
        return rows.first
    }

    /// Whether other people may see the user's family rating.
    static func setRatingPublic(
        _ isPublic: Bool
    ) async throws {
        let user =
            try await SupabaseManager.client.auth.session.user

        try await SupabaseManager.client
            .from("profiles")
            .update(VisibilityUpdate(ratingIsPublic: isPublic))
            .eq("id", value: user.id)
            .execute()
    }
}


/// Wording for the profile's numbers.
nonisolated enum ProfileStatsText {

    /// "4.6"
    static func average(
        _ value: Double
    ) -> String {
        String(format: "%.1f", value)
    }

    /// "from 1 rating", "from 23 ratings"
    static func ratingCount(
        _ count: Int
    ) -> String {
        count == 1 ? "from 1 rating" : "from \(count) ratings"
    }

    /// How many of the five stars to fill: rounded to the nearest
    /// half, as (full stars, has a half star).
    static func stars(
        for average: Double
    ) -> (full: Int, half: Bool) {
        let rounded = (min(max(average, 0), 5) * 2).rounded() / 2
        let full = Int(rounded)
        return (full, rounded - Double(full) == 0.5)
    }
}

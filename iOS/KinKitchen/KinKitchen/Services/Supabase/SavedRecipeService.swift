//
//  SavedRecipeService.swift
//  KinKitchen
//
//  Created by Greg Hudler on 10/4/26.
//

import Foundation
import Supabase

// MARK: - Saved Recipe

/// A user's saved link to an original recipe. Row in `saved_recipes`.
struct SavedRecipe: Codable, Hashable {

    let userId: UUID
    let recipeId: UUID
    let shareId: UUID?
    let savedAt: Date

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case recipeId = "recipe_id"
        case shareId = "share_id"
        case savedAt = "saved_at"
    }
}

private struct SavedRecipeCreate: Encodable {

    let userId: UUID
    let recipeId: UUID
    let shareId: UUID?

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case recipeId = "recipe_id"
        case shareId = "share_id"
    }
}

// MARK: - Saved Recipe Service

/// Saving never copies a recipe or changes its owner; it only
/// records that the signed-in user saved the original.
enum SavedRecipeService {

    /// The signed-in user's saved recipes.
    static func fetchSavedRecipes()
        async throws -> [SavedRecipe] {

        let user =
            try await SupabaseManager.client
                .auth
                .session
                .user

        let saved: [SavedRecipe] =
            try await SupabaseManager.client
                .from("saved_recipes")
                .select()
                .eq(
                    "user_id",
                    value: user.id
                )
                .order(
                    "saved_at",
                    ascending: false
                )
                .execute()
                .value

        return saved
    }


    static func isSaved(
        recipeId: UUID
    ) async throws -> Bool {

        try await fetchSavedRecipes()
            .contains {
                $0.recipeId == recipeId
            }
    }


    /// Saves a recipe shared with the user. Saving again is a
    /// no-op rather than a duplicate.
    static func saveRecipe(
        recipeId: UUID,
        shareId: UUID?
    ) async throws {

        let user =
            try await SupabaseManager.client
                .auth
                .session
                .user

        try await SupabaseManager.client
            .from("saved_recipes")
            .upsert(
                SavedRecipeCreate(
                    userId: user.id,
                    recipeId: recipeId,
                    shareId: shareId
                ),
                onConflict: "user_id,recipe_id",
                ignoreDuplicates: true
            )
            .execute()
    }


    static func unsaveRecipe(
        recipeId: UUID
    ) async throws {

        let user =
            try await SupabaseManager.client
                .auth
                .session
                .user

        try await SupabaseManager.client
            .from("saved_recipes")
            .delete()
            .eq(
                "user_id",
                value: user.id
            )
            .eq(
                "recipe_id",
                value: recipeId
            )
            .execute()
    }
}

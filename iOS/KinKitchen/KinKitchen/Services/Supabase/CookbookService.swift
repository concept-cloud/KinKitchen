//
//  CookbookService.swift
//  KinKitchen
//
//  Created by Greg Hudler on 9/23/26.
//

import Foundation
import Supabase

enum CookbookService {

    // MARK: - Create Cookbook

    static func createCookbook(
        name: String,
        description: String? = nil,
        coverPath: String? = nil
    ) async throws -> Cookbook {

        let user =
            try await SupabaseManager.client
                .auth
                .session
                .user

        let cleanName =
            name.trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        guard !cleanName.isEmpty else {
            throw CookbookServiceError.invalidName
        }

        let payload =
            CookbookCreate(
                ownerId: user.id,
                name: cleanName,
                description:
                    cleanedOptionalString(
                        description
                    ),
                coverPath:
                    cleanedOptionalString(
                        coverPath
                    ),
                visibility: .private
            )

        let cookbook: Cookbook =
            try await SupabaseManager.client
                .from("cookbooks")
                .insert(payload)
                .select()
                .single()
                .execute()
                .value

        return cookbook
    }

    // MARK: - Fetch Current User Cookbooks

    static func fetchCurrentUserCookbooks()
        async throws -> [Cookbook] {

        let user =
            try await SupabaseManager.client
                .auth
                .session
                .user

        let cookbooks: [Cookbook] =
            try await SupabaseManager.client
                .from("cookbooks")
                .select()
                .eq(
                    "owner_id",
                    value: user.id
                )
                .eq(
                    "visibility",
                    value: CookbookVisibility.private.rawValue
                )
                .order(
                    "updated_at",
                    ascending: false
                )
                .execute()
                .value

        return cookbooks
    }

    // MARK: - Fetch Cookbook

    static func fetchCookbook(
        id cookbookId: UUID
    ) async throws -> Cookbook {

        let user =
            try await SupabaseManager.client
                .auth
                .session
                .user

        let cookbooks: [Cookbook] =
            try await SupabaseManager.client
                .from("cookbooks")
                .select()
                .eq(
                    "id",
                    value: cookbookId
                )
                .eq(
                    "owner_id",
                    value: user.id
                )
                .eq(
                    "visibility",
                    value: CookbookVisibility.private.rawValue
                )
                .limit(1)
                .execute()
                .value

        guard let cookbook = cookbooks.first else {
            throw CookbookServiceError.cookbookNotFound
        }

        return cookbook
    }

    // MARK: - Update Cookbook

    static func updateCookbook(
        id cookbookId: UUID,
        name: String,
        description: String?,
        coverPath: String?
    ) async throws -> Cookbook {

        let user =
            try await SupabaseManager.client
                .auth
                .session
                .user

        let cleanName =
            name.trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        guard !cleanName.isEmpty else {
            throw CookbookServiceError.invalidName
        }

        let payload =
            CookbookUpdate(
                name: cleanName,
                description:
                    cleanedOptionalString(
                        description
                    ),
                coverPath:
                    cleanedOptionalString(
                        coverPath
                    )
            )

        let cookbook: Cookbook =
            try await SupabaseManager.client
                .from("cookbooks")
                .update(payload)
                .eq(
                    "id",
                    value: cookbookId
                )
                .eq(
                    "owner_id",
                    value: user.id
                )
                .select()
                .single()
                .execute()
                .value

        return cookbook
    }

    // MARK: - Delete Cookbook

    static func deleteCookbook(
        id cookbookId: UUID
    ) async throws {

        let user =
            try await SupabaseManager.client
                .auth
                .session
                .user

        try await SupabaseManager.client
            .from("cookbooks")
            .delete()
            .eq(
                "id",
                value: cookbookId
            )
            .eq(
                "owner_id",
                value: user.id
            )
            .execute()
    }

    // MARK: - Add Recipe

    static func addRecipe(
        recipeId: UUID,
        to cookbookId: UUID
    ) async throws -> CookbookRecipe {

        _ =
            try await fetchCookbook(
                id: cookbookId
            )

        let payload =
            CookbookRecipeCreate(
                cookbookId: cookbookId,
                recipeId: recipeId,
                sortOrder: 0
            )

        let relationship: CookbookRecipe =
            try await SupabaseManager.client
                .from("cookbook_recipes")
                .insert(payload)
                .select()
                .single()
                .execute()
                .value

        return relationship
    }

    // MARK: - Remove Recipe

    static func removeRecipe(
        recipeId: UUID,
        from cookbookId: UUID
    ) async throws {

        _ =
            try await fetchCookbook(
                id: cookbookId
            )

        try await SupabaseManager.client
            .from("cookbook_recipes")
            .delete()
            .eq(
                "cookbook_id",
                value: cookbookId
            )
            .eq(
                "recipe_id",
                value: recipeId
            )
            .execute()
    }

    // MARK: - Fetch Recipe Relationships

    static func fetchRecipeRelationships(
        cookbookId: UUID
    ) async throws -> [CookbookRecipe] {

        _ =
            try await fetchCookbook(
                id: cookbookId
            )

        let relationships: [CookbookRecipe] =
            try await SupabaseManager.client
                .from("cookbook_recipes")
                .select()
                .eq(
                    "cookbook_id",
                    value: cookbookId
                )
                .order(
                    "sort_order",
                    ascending: true
                )
                .execute()
                .value

        return relationships
    }

    // MARK: - Fetch Cookbook Recipes

    static func fetchRecipes(
        cookbookId: UUID
    ) async throws -> [Recipe] {

        let relationships =
            try await fetchRecipeRelationships(
                cookbookId: cookbookId
            )

        var recipes: [Recipe] = []

        for relationship in relationships {
            let recipe =
                try await RecipeService.fetchRecipe(
                    id: relationship.recipeId
                )

            recipes.append(recipe)
        }

        return recipes
    }

    // MARK: - Optional String Cleanup

    private static func cleanedOptionalString(
        _ value: String?
    ) -> String? {

        guard let value else {
            return nil
        }

        let cleaned =
            value.trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        return cleaned.isEmpty
            ? nil
            : cleaned
    }
}

// MARK: - Cookbook Service Error

enum CookbookServiceError: LocalizedError {
    case invalidName
    case cookbookNotFound

    var errorDescription: String? {
        switch self {
        case .invalidName:
            return "Cookbook name cannot be empty."

        case .cookbookNotFound:
            return "Cookbook could not be found."
        }
    }
}

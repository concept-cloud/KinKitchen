//
//  RecipeService.swift
//  KinKitchen
//
//  Created by Greg Hudler on 9/7/26.
//

import Foundation
import Supabase

enum RecipeService {

    // MARK: - Create Recipe

    static func createRecipe(
        name: String,
        description: String?,
        instructions: String?,
        servings: Int?,
        prepTimeMinutes: Int?,
        cookTimeMinutes: Int?,
        photoPath: String?,
        category: String?
    ) async throws -> Recipe {

        let user =
            try await SupabaseManager.client
                .auth
                .session
                .user

        let cleanName =
            name.trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        let recipeCreate =
            RecipeCreate(
                ownerId: user.id,
                name: cleanName,
                description:
                    cleanedOptionalString(
                        description
                    ),
                instructions:
                    cleanedOptionalString(
                        instructions
                    ),
                servings: servings,
                prepTimeMinutes:
                    prepTimeMinutes,
                cookTimeMinutes:
                    cookTimeMinutes,
                photoPath:
                    cleanedOptionalString(
                        photoPath
                    ),
                category:
                    cleanedOptionalString(
                        category
                    ),
                sourceRecipeId: nil,
                originalRecipeId: nil
            )

        let recipe: Recipe =
            try await SupabaseManager.client
                .from("recipes")
                .insert(recipeCreate)
                .select()
                .single()
                .execute()
                .value

        return recipe
    }


    // MARK: - Fetch Current User Recipes

    static func fetchCurrentUserRecipes()
        async throws -> [Recipe] {

        let user =
            try await SupabaseManager.client
                .auth
                .session
                .user

        let recipes: [Recipe] =
            try await SupabaseManager.client
                .from("recipes")
                .select()
                .eq(
                    "owner_id",
                    value: user.id
                )
                .order(
                    "updated_at",
                    ascending: false
                )
                .execute()
                .value

        return recipes
    }


    // MARK: - Fetch Recipe

    static func fetchRecipe(
        id recipeId: UUID
    ) async throws -> Recipe {

        let recipe: Recipe =
            try await SupabaseManager.client
                .from("recipes")
                .select()
                .eq(
                    "id",
                    value: recipeId
                )
                .single()
                .execute()
                .value

        return recipe
    }


    // MARK: - Fetch Recipe With Ingredients

    static func fetchRecipeWithIngredients(
        id recipeId: UUID
    ) async throws -> RecipeWithIngredients {

        async let recipe =
            fetchRecipe(
                id: recipeId
            )

        async let ingredients =
            fetchIngredients(
                recipeId: recipeId
            )

        return try await RecipeWithIngredients(
            recipe: recipe,
            ingredients: ingredients
        )
    }


    // MARK: - Update Recipe

    static func updateRecipe(
        id recipeId: UUID,
        name: String,
        description: String?,
        instructions: String?,
        servings: Int?,
        prepTimeMinutes: Int?,
        cookTimeMinutes: Int?,
        photoPath: String?,
        category: String?
    ) async throws -> Recipe {

        let user =
            try await SupabaseManager.client
                .auth
                .session
                .user

        let updates =
            RecipeUpdate(
                name:
                    name.trimmingCharacters(
                        in: .whitespacesAndNewlines
                    ),
                description:
                    cleanedOptionalString(
                        description
                    ),
                instructions:
                    cleanedOptionalString(
                        instructions
                    ),
                servings: servings,
                prepTimeMinutes:
                    prepTimeMinutes,
                cookTimeMinutes:
                    cookTimeMinutes,
                photoPath:
                    cleanedOptionalString(
                        photoPath
                    ),
                category:
                    cleanedOptionalString(
                        category
                    )
            )

        let recipe: Recipe =
            try await SupabaseManager.client
                .from("recipes")
                .update(updates)
                .eq(
                    "id",
                    value: recipeId
                )
                .eq(
                    "owner_id",
                    value: user.id
                )
                .select()
                .single()
                .execute()
                .value

        return recipe
    }

    // MARK: - Fetch Recipe Ratings

    static func fetchRecipeRatings(
        recipeId: UUID
    ) async throws -> [RecipeRating] {

        let ratings: [RecipeRating] =
            try await SupabaseManager.client
                .from("recipe_ratings")
                .select()
                .eq("recipe_id", value: recipeId)
                .execute()
                .value

        return ratings
    }


    // MARK: - Fetch Current User Rating

    static func fetchCurrentUserRating(
        recipeId: UUID
    ) async throws -> RecipeRating? {

        let user =
            try await SupabaseManager.client
                .auth
                .session
                .user

        let ratings: [RecipeRating] =
            try await SupabaseManager.client
                .from("recipe_ratings")
                .select()
                .eq("recipe_id", value: recipeId)
                .eq("user_id", value: user.id)
                .limit(1)
                .execute()
                .value

        return ratings.first
    }


    // MARK: - Fetch Rating Summary

    static func fetchRecipeRatingSummary(
        recipeId: UUID
    ) async throws -> RecipeRatingSummary {

        async let ratings =
            fetchRecipeRatings(
                recipeId: recipeId
            )

        async let currentUserRating =
            fetchCurrentUserRating(
                recipeId: recipeId
            )

        let allRatings =
            try await ratings

        let personalRating =
            try await currentUserRating

        let averageRating: Double?

        if allRatings.isEmpty {
            averageRating = nil
        } else {
            let total =
                allRatings.reduce(0) {
                    $0 + $1.rating
                }

            averageRating =
                Double(total) /
                Double(allRatings.count)
        }

        return RecipeRatingSummary(
            averageRating: averageRating,
            ratingCount: allRatings.count,
            currentUserRating:
                personalRating?.rating
        )
    }


    // MARK: - Set Current User Rating

    static func setCurrentUserRating(
        recipeId: UUID,
        rating: Int
    ) async throws -> RecipeRating {

        guard (1...5).contains(rating) else {
            throw RecipeServiceError.invalidRating
        }

        let user =
            try await SupabaseManager.client
                .auth
                .session
                .user

        struct RatingUpsert: Encodable {
            let recipeId: UUID
            let userId: UUID
            let rating: Int

            enum CodingKeys:
                String,
                CodingKey {

                case recipeId =
                    "recipe_id"

                case userId =
                    "user_id"

                case rating
            }
        }

        let payload =
            RatingUpsert(
                recipeId: recipeId,
                userId: user.id,
                rating: rating
            )

        let savedRating: RecipeRating =
            try await SupabaseManager.client
                .from("recipe_ratings")
                .upsert(
                    payload,
                    onConflict:
                        "recipe_id,user_id"
                )
                .select()
                .single()
                .execute()
                .value

        return savedRating
    }


    // MARK: - Delete Current User Rating

    static func deleteCurrentUserRating(
        recipeId: UUID
    ) async throws {

        let user =
            try await SupabaseManager.client
                .auth
                .session
                .user

        try await SupabaseManager.client
            .from("recipe_ratings")
            .delete()
            .eq(
                "recipe_id",
                value: recipeId
            )
            .eq(
                "user_id",
                value: user.id
            )
            .execute()
    }
    
    
    // MARK: - Fetch Original Recipe

    static func fetchOriginalRecipe(
        for recipe: Recipe
    ) async throws -> Recipe? {
        guard let originalRecipeId = recipe.originalRecipeId else {
            return nil
        }

        return try await fetchRecipe(
            id: originalRecipeId
        )
    }


    // MARK: - Fetch Recipe Versions

    static func fetchRecipeVersions(
        for recipe: Recipe
    ) async throws -> [Recipe] {
        let rootRecipeId =
            recipe.originalRecipeId ?? recipe.id

        let versions: [Recipe] =
            try await SupabaseManager.client
                .from("recipes")
                .select()
                .eq(
                    "original_recipe_id",
                    value: rootRecipeId
                )
                .order(
                    "created_at",
                    ascending: true
                )
                .execute()
                .value

        return versions
    }


    // MARK: - Fetch Version Count

    static func fetchVersionCount(
        for recipe: Recipe
    ) async throws -> Int {
        let versions =
            try await fetchRecipeVersions(
                for: recipe
            )

        return versions.count
    }


    // MARK: - Create Version

    static func createVersion(
        from sourceRecipe: Recipe
    ) async throws -> Recipe {
        let user =
            try await SupabaseManager.client
                .auth
                .session
                .user

        let sourceWithIngredients =
            try await fetchRecipeWithIngredients(
                id: sourceRecipe.id
            )

        let originalRecipeId =
            sourceRecipe.originalRecipeId
            ?? sourceRecipe.id

        let newRecipeCreate =
            RecipeCreate(
                ownerId: user.id,
                name: sourceRecipe.name,
                description: sourceRecipe.description,
                instructions: sourceRecipe.instructions,
                servings: sourceRecipe.servings,
                prepTimeMinutes:
                    sourceRecipe.prepTimeMinutes,
                cookTimeMinutes:
                    sourceRecipe.cookTimeMinutes,
                photoPath:
                    sourceRecipe.photoPath,
                category:
                    sourceRecipe.category,
                sourceRecipeId:
                    sourceRecipe.id,
                originalRecipeId:
                    originalRecipeId
            )

        let newRecipe: Recipe =
            try await SupabaseManager.client
                .from("recipes")
                .insert(newRecipeCreate)
                .select()
                .single()
                .execute()
                .value

        let ingredientInputs =
            sourceWithIngredients
                .orderedIngredients
                .map { ingredient in
                    RecipeIngredientInput(
                        name: ingredient.name,
                        quantity:
                            ingredient.quantity,
                        unit:
                            ingredient.unit,
                        offProductId:
                            ingredient.offProductId
                    )
                }

        _ =
            try await createIngredients(
                recipeId: newRecipe.id,
                ingredients:
                    ingredientInputs
            )

        return newRecipe
    }
    
    // MARK: - Delete Recipe

    static func deleteRecipe(
        id recipeId: UUID
    ) async throws {

        let user =
            try await SupabaseManager.client
                .auth
                .session
                .user

        try await SupabaseManager.client
            .from("recipes")
            .delete()
            .eq(
                "id",
                value: recipeId
            )
            .eq(
                "owner_id",
                value: user.id
            )
            .execute()
    }


    // MARK: - Create Ingredient

    static func createIngredient(
        recipeId: UUID,
        name: String,
        quantity: Double?,
        unit: String?,
        offProductId: String?,
        sortOrder: Int
    ) async throws -> RecipeIngredient {

        try await verifyRecipeOwnership(
            recipeId: recipeId
        )

        let ingredientCreate =
            RecipeIngredientCreate(
                recipeId: recipeId,
                name:
                    name.trimmingCharacters(
                        in: .whitespacesAndNewlines
                    ),
                quantity: quantity,
                unit:
                    cleanedOptionalString(
                        unit
                    ),
                offProductId:
                    cleanedOptionalString(
                        offProductId
                    ),
                sortOrder: sortOrder
            )

        let ingredient:
            RecipeIngredient =
                try await SupabaseManager.client
                    .from(
                        "recipe_ingredients"
                    )
                    .insert(
                        ingredientCreate
                    )
                    .select()
                    .single()
                    .execute()
                    .value

        return ingredient
    }


    // MARK: - Create Ingredients

    static func createIngredients(
        recipeId: UUID,
        ingredients: [
            RecipeIngredientInput
        ]
    ) async throws -> [RecipeIngredient] {

        try await verifyRecipeOwnership(
            recipeId: recipeId
        )

        guard !ingredients.isEmpty else {

            return []
        }

        let creates =
            ingredients.enumerated().map {
                index,
                ingredient in

                RecipeIngredientCreate(
                    recipeId: recipeId,
                    name:
                        ingredient.name
                            .trimmingCharacters(
                                in:
                                    .whitespacesAndNewlines
                            ),
                    quantity:
                        ingredient.quantity,
                    unit:
                        cleanedOptionalString(
                            ingredient.unit
                        ),
                    offProductId:
                        cleanedOptionalString(
                            ingredient
                                .offProductId
                        ),
                    sortOrder: index
                )
            }

        let createdIngredients:
            [RecipeIngredient] =
                try await SupabaseManager.client
                    .from(
                        "recipe_ingredients"
                    )
                    .insert(creates)
                    .select()
                    .execute()
                    .value

        return createdIngredients.sorted {

            $0.sortOrder <
            $1.sortOrder
        }
    }


    // MARK: - Fetch Ingredients

    static func fetchIngredients(
        recipeId: UUID
    ) async throws -> [RecipeIngredient] {

        let ingredients:
            [RecipeIngredient] =
                try await SupabaseManager.client
                    .from(
                        "recipe_ingredients"
                    )
                    .select()
                    .eq(
                        "recipe_id",
                        value: recipeId
                    )
                    .order(
                        "sort_order",
                        ascending: true
                    )
                    .execute()
                    .value

        return ingredients
    }


    // MARK: - Replace Ingredients

    static func replaceIngredients(
        recipeId: UUID,
        ingredients: [
            RecipeIngredientInput
        ]
    ) async throws -> [RecipeIngredient] {

        try await verifyRecipeOwnership(
            recipeId: recipeId
        )

        try await SupabaseManager.client
            .from(
                "recipe_ingredients"
            )
            .delete()
            .eq(
                "recipe_id",
                value: recipeId
            )
            .execute()

        guard !ingredients.isEmpty else {

            return []
        }

        return try await createIngredients(
            recipeId: recipeId,
            ingredients: ingredients
        )
    }


    // MARK: - Delete Ingredient

    static func deleteIngredient(
        id ingredientId: UUID,
        recipeId: UUID
    ) async throws {

        try await verifyRecipeOwnership(
            recipeId: recipeId
        )

        try await SupabaseManager.client
            .from(
                "recipe_ingredients"
            )
            .delete()
            .eq(
                "id",
                value: ingredientId
            )
            .eq(
                "recipe_id",
                value: recipeId
            )
            .execute()
    }


    // MARK: - Verify Recipe Ownership

    private static func verifyRecipeOwnership(
        recipeId: UUID
    ) async throws {

        let user =
            try await SupabaseManager.client
                .auth
                .session
                .user

        let recipes: [Recipe] =
            try await SupabaseManager.client
                .from("recipes")
                .select()
                .eq(
                    "id",
                    value: recipeId
                )
                .eq(
                    "owner_id",
                    value: user.id
                )
                .limit(1)
                .execute()
                .value

        guard !recipes.isEmpty else {

            throw RecipeServiceError
                .recipeNotOwnedByCurrentUser
        }
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
    
    // MARK: - Fetch Recipe Stories

    static func fetchRecipeStories(
        recipeId: UUID
    ) async throws -> [RecipeStory] {
        let stories: [RecipeStory] =
            try await SupabaseManager.client
                .from("recipe_stories")
                .select()
                .eq("recipe_id", value: recipeId)
                .order("created_at", ascending: false)
                .execute()
                .value

        return stories
    }


    // MARK: - Create Recipe Story

    static func createRecipeStory(
        recipeId: UUID,
        story: String
    ) async throws -> RecipeStory {
        let user =
            try await SupabaseManager.client
                .auth
                .session
                .user

        let cleanStory =
            story.trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        let payload =
            RecipeStoryCreate(
                recipeId: recipeId,
                story: cleanStory,
                contributorUserId: user.id
            )

        let createdStory: RecipeStory =
            try await SupabaseManager.client
                .from("recipe_stories")
                .insert(payload)
                .select()
                .single()
                .execute()
                .value

        return createdStory
    }
}


// MARK: - Recipe Ingredient Input

struct RecipeIngredientInput {

    let name: String
    let quantity: Double?
    let unit: String?
    let offProductId: String?


    init(
        name: String,
        quantity: Double? = nil,
        unit: String? = nil,
        offProductId: String? = nil
    ) {

        self.name = name
        self.quantity = quantity
        self.unit = unit
        self.offProductId = offProductId
    }
}


// MARK: - Recipe Service Error

enum RecipeServiceError:
    LocalizedError {
    
    case recipeNotOwnedByCurrentUser
    case invalidRating
    
    var errorDescription: String? {
        
        switch self {
            
        case .recipeNotOwnedByCurrentUser:
            
            return
            "The current user does not own this recipe."
            
        case .invalidRating:
            
            return
            "Recipe ratings must be between 1 and 5."
        }
    }
}

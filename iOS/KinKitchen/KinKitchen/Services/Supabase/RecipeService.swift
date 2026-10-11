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
        story: String? = nil,
        originalContributor: String? = nil,
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
                story:
                    cleanedOptionalString(
                        story
                    ),
                originalContributor:
                    cleanedOptionalString(
                        originalContributor
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
                // Archived recipes were deleted by the owner.
                .filter(
                    "archived_at",
                    operator: "is",
                    value: "null"
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
        story: String? = nil,
        originalContributor: String? = nil,
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
                story:
                    cleanedOptionalString(
                        story
                    ),
                originalContributor:
                    cleanedOptionalString(
                        originalContributor
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


    // MARK: - Fetch Recipe Family

    /// The family's original plus every version of it that the user
    /// can open (RLS decides), excluding recipes their owners have
    /// deleted (archived).
    static func fetchRecipeFamily(
        for recipe: Recipe
    ) async throws -> [Recipe] {
        let rootRecipeId =
            (recipe.originalRecipeId ?? recipe.id)
                .uuidString
                .lowercased()

        let family: [Recipe] =
            try await SupabaseManager.client
                .from("recipes")
                .select()
                .or(
                    "id.eq.\(rootRecipeId),original_recipe_id.eq.\(rootRecipeId)"
                )
                .filter(
                    "archived_at",
                    operator: "is",
                    value: "null"
                )
                .execute()
                .value

        return family
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

    /// Creates a new recipe owned by the current user from a recipe
    /// they can view (see supabase/KINKIT-186). The recipe, its
    /// ingredients, allergen associations and dietary tags are copied
    /// in one database transaction; the source is never changed.
    static func createVersion(
        from sourceRecipe: Recipe
    ) async throws -> Recipe {

        let version: Recipe =
            try await SupabaseManager.client
                .rpc(
                    "create_recipe_version",
                    params: [
                        "p_source_recipe_id":
                            sourceRecipe.id
                    ]
                )
                .single()
                .execute()
                .value

        return await ensureOwnPhoto(
            for: version
        )
    }


    /// Whether a recipe uses a photo file stored under another recipe,
    /// e.g. a version made before versions got their own copy.
    static func sharesAnotherRecipesPhoto(
        _ recipe: Recipe
    ) -> Bool {
        guard
            let photoPath = recipe.photoPath,
            !photoPath.isEmpty
        else {
            return false
        }

        return photoPath !=
            recipePhotoPath(
                ownerId: recipe.ownerId,
                recipeId: recipe.id
            )
    }


    /// Gives a version its own copy of the photo. The original's owner
    /// replaces their photo in place, which would otherwise change the
    /// version's photo too. Returns the recipe unchanged when there's
    /// nothing to copy or the copy fails; the shared photo still shows.
    static func ensureOwnPhoto(
        for recipe: Recipe
    ) async -> Recipe {

        guard
            recipe.isVersion,
            sharesAnotherRecipesPhoto(recipe),
            let sharedPhotoPath = recipe.photoPath,
            let userId =
                try? await SupabaseManager.client
                    .auth
                    .session
                    .user
                    .id,
            userId == recipe.ownerId
        else {
            return recipe
        }

        let ownPhotoPath =
            recipePhotoPath(
                ownerId: recipe.ownerId,
                recipeId: recipe.id
            )

        do {
            try await SupabaseManager.client.storage
                .from("recipe-photos")
                .copy(
                    from: sharedPhotoPath,
                    to: ownPhotoPath
                )
        } catch {
            // Already copied by an earlier attempt that didn't finish
            // saving the path; reuse that file.
            let existing =
                try? await SupabaseManager.client.storage
                    .from("recipe-photos")
                    .download(path: ownPhotoPath)

            guard existing != nil else {
                print(
                    "VERSION PHOTO COPY ERROR:",
                    error.localizedDescription
                )
                return recipe
            }
        }

        do {
            return try await SupabaseManager.client
                .from("recipes")
                .update(
                    ["photo_path": ownPhotoPath]
                )
                .eq("id", value: recipe.id)
                .eq("owner_id", value: userId)
                .select()
                .single()
                .execute()
                .value
        } catch {
            print(
                "VERSION PHOTO PATH UPDATE ERROR:",
                error.localizedDescription
            )
            return recipe
        }
    }


    /// Friendly message for a failed Make My Version.
    static func versionFailureMessage(
        for error: Error
    ) -> String {

        let description =
            String(describing: error)

        if description.contains("SOURCE_RECIPE_UNAVAILABLE") {
            return "This recipe is no longer available, so a version can't be made from it."
        }

        if description.contains("CANNOT_VERSION_OWN_RECIPE") {
            return "This is already your recipe. Edit it instead."
        }

        return "Your version couldn't be created. Nothing was changed. Please try again."
    }


    static func recipePhotoPath(
        ownerId: UUID,
        recipeId: UUID
    ) -> String {
        "\(ownerId.uuidString.lowercased())/\(recipeId.uuidString.lowercased())/recipe.jpg"
    }
    
    // MARK: - Delete Recipe

    /// Deletes a recipe the user owns, or archives it when it has to be
    /// kept for others (see supabase/KINKIT-181). Runs as one database
    /// transaction, so a failure changes nothing.
    @discardableResult
    static func deleteRecipe(
        id recipeId: UUID
    ) async throws -> RecipeDeletionOutcome {

        let result: RecipeDeletionResult =
            try await SupabaseManager.client
                .rpc(
                    "delete_recipe",
                    params: ["p_recipe_id": recipeId]
                )
                .execute()
                .value

        if result.outcome == "archived" {
            return .archived(
                reason:
                    result.reason == "versions"
                        ? .versions
                        : .pastGathering
            )
        }

        // The recipe is already gone; a leftover photo file shouldn't
        // turn a successful delete into an error.
        if let photoPath = result.photoPath {
            _ = try? await SupabaseManager.client.storage
                .from("recipe-photos")
                .remove(paths: [photoPath])
        }

        return .deleted
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


    // MARK: - Fetch Recipes By ID

    /// Loads many recipes in one request. Recipes that no longer
    /// exist or aren't visible to the user are simply missing.
    static func fetchRecipes(
        ids: [UUID]
    ) async throws -> [Recipe] {

        guard !ids.isEmpty else {
            return []
        }

        let recipes: [Recipe] =
            try await SupabaseManager.client
                .from("recipes")
                .select()
                .in(
                    "id",
                    values: Array(Set(ids))
                )
                .execute()
                .value

        return recipes
    }


    // MARK: - Fetch Ingredients For Recipes

    /// Loads ingredients for many recipes in one request.
    static func fetchIngredients(
        recipeIds: [UUID]
    ) async throws -> [RecipeIngredient] {

        guard !recipeIds.isEmpty else {
            return []
        }

        let ingredients:
            [RecipeIngredient] =
                try await SupabaseManager.client
                    .from(
                        "recipe_ingredients"
                    )
                    .select()
                    .in(
                        "recipe_id",
                        values: recipeIds
                    )
                    .order(
                        "sort_order",
                        ascending: true
                    )
                    .execute()
                    .value

        return ingredients
    }


    // MARK: - Fetch Dietary Restriction Tags

    /// Restriction IDs each recipe's owner has tagged it with.
    static func fetchDietaryRestrictionTags(
        recipeIds: [UUID]
    ) async throws -> [UUID: Set<UUID>] {

        guard !recipeIds.isEmpty else {
            return [:]
        }

        let tags:
            [RecipeDietaryRestrictionTag] =
                try await SupabaseManager.client
                    .from(
                        "recipe_dietary_restrictions"
                    )
                    .select(
                        "recipe_id, restriction_id"
                    )
                    .in(
                        "recipe_id",
                        values: recipeIds
                    )
                    .execute()
                    .value

        return Dictionary(
            grouping: tags,
            by: \.recipeId
        )
        .mapValues {
            Set($0.map(\.restrictionId))
        }
    }


    // MARK: - Replace Dietary Restriction Tags

    static func replaceDietaryRestrictionTags(
        recipeId: UUID,
        restrictionIds: Set<UUID>
    ) async throws {

        try await SupabaseManager.client
            .from(
                "recipe_dietary_restrictions"
            )
            .delete()
            .eq(
                "recipe_id",
                value: recipeId
            )
            .execute()

        guard !restrictionIds.isEmpty else {
            return
        }

        let tags =
            restrictionIds.map {
                RecipeDietaryRestrictionTag(
                    recipeId: recipeId,
                    restrictionId: $0
                )
            }

        try await SupabaseManager.client
            .from(
                "recipe_dietary_restrictions"
            )
            .insert(
                tags
            )
            .execute()
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

    static func uploadRecipePhoto(
        recipeId: UUID,
        imageData: Data
    ) async throws -> String {

        let user =
            try await SupabaseManager.client.auth.session.user

        let path =
            recipePhotoPath(
                ownerId: user.id,
                recipeId: recipeId
            )

        try await SupabaseManager.client.storage
            .from("recipe-photos")
            .upload(
                path,
                data: imageData,
                options: FileOptions(
                    contentType: "image/jpeg",
                    upsert: true
                )
            )

        return path
    }


    static func fetchRecipePhoto(
        path: String
    ) async throws -> Data {

        try await SupabaseManager.client.storage
            .from("recipe-photos")
            .download(
                path: path
            )
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


// MARK: - Recipe Deletion Result

/// What `delete_recipe` returns.
private struct RecipeDeletionResult: Decodable {

    let outcome: String
    let reason: String?
    let photoPath: String?

    enum CodingKeys: String, CodingKey {
        case outcome
        case reason
        case photoPath = "photo_path"
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
            
            return "The current user does not own this recipe."

        case .invalidRating:

            return "Recipe ratings must be between 1 and 5."
        }
    }
}

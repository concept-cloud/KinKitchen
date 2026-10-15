//
//  RecipeDietaryCheckService.swift
//  KinKitchen
//
//  Created by Greg Hudler on 9/9/26.
//

import Foundation

// MARK: - Recipe Dietary Check Service

enum RecipeDietaryCheckService {

    static func checkRecipe(
        recipeId: UUID
    ) async throws -> RecipeDietaryCheckResult {
        async let selectedAllergenRequest =
            DietaryService.fetchSelectedAllergens()

        async let availableAllergenRequest =
            DietaryService.fetchAllergens()

        let selectedAllergenIds =
            Set(
                try await selectedAllergenRequest
            )

        let availableAllergens =
            try await availableAllergenRequest

        // The user's own allergens are always on. A failure here
        // shouldn't hide the built-in warnings.
        let customAllergens =
            (try? await CustomDietaryService.fetchItems())?
                .allergens ?? []

        let selectedAllergens =
            availableAllergens
                .filter {
                    selectedAllergenIds.contains(
                        $0.id
                    )
                }
            + customAllergens

        return try await evaluateRecipe(
            recipeId: recipeId,
            allergens: selectedAllergens
        ).result
    }

    static func checkRecipe(
        recipeId: UUID,
        for recipientId: UUID
    ) async throws -> RecipientRecipeDietaryCheckResult {
        let dietaryInformation =
            try await RecipientDietaryService
                .fetchDietaryInformation(
                    for: recipientId
                )

        let evaluation =
            try await evaluateRecipe(
                recipeId: recipeId,
                allergens: dietaryInformation.allergens
            )

        let allergenResult =
            evaluation.result

        let restrictionConflicts =
            restrictionConflicts(
                dietaryInformation.restrictions,
                ingredientNames:
                    evaluation.ingredientNames,
                allergenResult:
                    evaluation.allergenAssociations
            )

        let preferenceConflicts =
            evaluatePreferences(
                dietaryInformation.preferences,
                ingredientNames: evaluation.ingredientNames
            )

        return RecipientRecipeDietaryCheckResult(
            recipeId: recipeId,
            recipientId: recipientId,
            state: allergenResult.state,
            dietaryInformation: dietaryInformation,
            allergenConflicts: allergenResult.conflicts,
            restrictionConflicts: restrictionConflicts,
            preferenceConflicts: preferenceConflicts,
            unknownIngredients: allergenResult.unknownIngredients,
            knownIngredientsWithoutMappedAllergens:
                allergenResult
                    .knownIngredientsWithoutMappedAllergens
        )
    }


    /// Evaluates all allergens in already-loaded ingredients.
    /// Used by recipe lists, which load ingredients in bulk.
    static func evaluateAllergens(
        ingredients: [RecipeIngredient]
    ) async throws -> RecipeAllergenAssociationResult {

        // Refreshing stored classifications writes to the
        // ingredients, which can fail for recipes shared with
        // the user. Evaluation itself doesn't depend on it.
        try? await IngredientAllergenService
            .refreshRecipeClassificationsIfNeeded(
                ingredients: ingredients
            )

        return try await IngredientAllergenService
            .evaluateRecipe(
                ingredients:
                    ingredients.map {
                        IngredientAllergenInput(
                            id: $0.id,
                            name: $0.name,
                            offProductId: $0.offProductId
                        )
                    }
            )
    }


    /// Known conflicts between a recipe and dietary restrictions.
    ///
    /// Pass `allergenResult` as nil when allergens haven't been
    /// evaluated yet; only ingredient keywords are checked then.
    static func restrictionConflicts(
        _ restrictions: [DietaryRestriction],
        ingredientNames: [String],
        allergenResult: RecipeAllergenAssociationResult?
    ) -> [RecipeDietaryRestrictionConflict] {

        restrictions.compactMap {
            restriction in

            let ingredients =
                DietaryRestrictionRules
                    .conflictingIngredients(
                        for: restriction,
                        ingredientNames: ingredientNames,
                        allergenAssociations:
                            allergenResult?
                                .allergenAssociations
                                ?? []
                    )

            guard !ingredients.isEmpty else {
                return nil
            }

            return RecipeDietaryRestrictionConflict(
                restriction: restriction,
                ingredientNames: ingredients
            )
        }
    }
}

// MARK: - Recipe Evaluation

private extension RecipeDietaryCheckService {

    struct RecipeEvaluation {
        let result: RecipeDietaryCheckResult
        let allergenAssociations: RecipeAllergenAssociationResult
        let ingredientNames: [String]
    }


    static func evaluateRecipe(
        recipeId: UUID,
        allergens: [Allergen]
    ) async throws -> RecipeEvaluation {
        let ingredients =
            try await RecipeService.fetchIngredients(
                recipeId: recipeId
            )

        try await IngredientAllergenService
            .refreshRecipeClassificationsIfNeeded(
                ingredients: ingredients
            )

        let inputs =
            ingredients.map {
                ingredient in

                IngredientAllergenInput(
                    id: ingredient.id,
                    name: ingredient.name,
                    offProductId: ingredient.offProductId
                )
            }

        let recipeEvaluation =
            try await IngredientAllergenService
                .evaluateRecipe(
                    ingredients: inputs
                )

        let selectedAllergenIds =
            Set(
                allergens.map(
                    \.id
                )
            )

        let selectedAllergens =
            allergens.sorted {
                $0.name.localizedCaseInsensitiveCompare(
                    $1.name
                ) == .orderedAscending
            }

        var conflicts:
            [RecipeAllergenConflict] = []

        for association in
            recipeEvaluation.allergenAssociations {

            guard
                selectedAllergenIds.contains(
                    association.allergen.id
                )
            else {
                continue
            }

            conflicts.append(
                RecipeAllergenConflict(
                    allergen: association.allergen,
                    ingredientNames:
                        association.ingredientNames
                )
            )
        }

        // The user's own allergens aren't in the catalog, so they're
        // matched by name.
        for allergen in allergens where allergen.isCustom {

            let matches =
                CustomDietaryMatcher.matchingIngredients(
                    for: allergen.name,
                    in: ingredients.map(\.name)
                )

            if !matches.isEmpty {
                conflicts.append(
                    RecipeAllergenConflict(
                        allergen: allergen,
                        ingredientNames: matches
                    )
                )
            }
        }

        conflicts.sort {
            $0.allergen.name.localizedCaseInsensitiveCompare(
                $1.allergen.name
            ) == .orderedAscending
        }

        let state:
            RecipeDietaryCheckState

        if !conflicts.isEmpty {
            state = .conflict
        } else if recipeEvaluation.hasUnknownIngredients {
            state = .incomplete
        } else {
            state = .noKnownConflict
        }

        let result =
            RecipeDietaryCheckResult(
                recipeId: recipeId,
                state: state,
                selectedAllergens: selectedAllergens,
                conflicts: conflicts,
                unknownIngredients:
                    recipeEvaluation.unknownIngredients,
                knownIngredientsWithoutMappedAllergens:
                    recipeEvaluation
                        .knownIngredientsWithoutMappedAllergens
            )

        return RecipeEvaluation(
            result: result,
            allergenAssociations: recipeEvaluation,
            ingredientNames: ingredients.map(\.name)
        )
    }
}

// MARK: - Dietary Preferences

private extension RecipeDietaryCheckService {

    /// Preferences are matched by name against every ingredient,
    /// e.g. "No Mushrooms" finds "sliced mushrooms". Ones that can't
    /// be judged from ingredients (like "Low Carb") never match.
    static func evaluatePreferences(
        _ preferences: [DietaryPreference],
        ingredientNames: [String]
    ) -> [RecipeDietaryPreferenceConflict] {
        preferences.compactMap {
            preference in

            let matchingIngredients =
                CustomDietaryMatcher.matchingIngredients(
                    for: preference.name,
                    in: ingredientNames
                )

            guard !matchingIngredients.isEmpty else {
                return nil
            }

            return RecipeDietaryPreferenceConflict(
                preference: preference,
                ingredientNames: matchingIngredients
            )
        }
    }
}

// MARK: - Result

struct RecipeDietaryCheckResult:
    Hashable {

    let recipeId:
        UUID

    let state:
        RecipeDietaryCheckState

    let selectedAllergens:
        [Allergen]

    let conflicts:
        [RecipeAllergenConflict]

    let unknownIngredients:
        [String]

    let knownIngredientsWithoutMappedAllergens:
        [String]

    var hasConflict: Bool {
        !conflicts.isEmpty
    }

    var hasIncompleteInformation: Bool {
        !unknownIngredients.isEmpty
    }

    var conflictingAllergens:
        [Allergen] {

        conflicts.map(
            \.allergen
        )
    }

    var conflictingIngredientNames:
        [String] {

        var seen:
            Set<String> = []

        return conflicts
            .flatMap(
                \.ingredientNames
            )
            .filter {
                ingredient in

                let key =
                    IngredientAllergenService
                        .normalizeIngredientName(
                            ingredient
                        )

                return seen
                    .insert(
                        key
                    )
                    .inserted
            }
    }
}

// MARK: - Recipient Result

struct RecipientRecipeDietaryCheckResult:
    Hashable {

    let recipeId:
        UUID

    let recipientId:
        UUID

    let state:
        RecipeDietaryCheckState

    let dietaryInformation:
        RecipientDietaryInformation

    let allergenConflicts:
        [RecipeAllergenConflict]

    let restrictionConflicts:
        [RecipeDietaryRestrictionConflict]

    let preferenceConflicts:
        [RecipeDietaryPreferenceConflict]

    let unknownIngredients:
        [String]

    let knownIngredientsWithoutMappedAllergens:
        [String]

    var hasConflict: Bool {
        !allergenConflicts.isEmpty ||
        !restrictionConflicts.isEmpty ||
        !preferenceConflicts.isEmpty
    }

    var hasIncompleteInformation: Bool {
        !unknownIngredients.isEmpty
    }

    var hasDietaryInformation: Bool {
        dietaryInformation.hasDietaryInformation
    }
}

// MARK: - Allergen Conflict

struct RecipeAllergenConflict:
    Identifiable,
    Hashable {

    var id: UUID {
        allergen.id
    }

    let allergen:
        Allergen

    let ingredientNames:
        [String]
}

// MARK: - Restriction Conflict

struct RecipeDietaryRestrictionConflict:
    Identifiable,
    Hashable {

    var id: UUID {
        restriction.id
    }

    let restriction:
        DietaryRestriction

    let ingredientNames:
        [String]
}

// MARK: - Preference Conflict

struct RecipeDietaryPreferenceConflict:
    Identifiable,
    Hashable {

    var id: UUID {
        preference.id
    }

    let preference:
        DietaryPreference

    let ingredientNames:
        [String]
}

// MARK: - State

enum RecipeDietaryCheckState:
    String,
    Codable,
    Hashable {

    case conflict
    case noKnownConflict
    case incomplete
}

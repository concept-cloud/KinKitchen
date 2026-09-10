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
    ) async throws
        -> RecipeDietaryCheckResult {

        async let ingredientRequest =
            RecipeService.fetchIngredients(
                recipeId:
                    recipeId
            )

        async let selectedAllergenRequest =
            DietaryService
                .fetchSelectedAllergens()

        async let allergenRequest =
            DietaryService
                .fetchAllergens()


        let ingredients =
            try await ingredientRequest


        // MARK: Refresh stale classification data

        try await IngredientAllergenService
            .refreshRecipeClassificationsIfNeeded(
                ingredients:
                    ingredients
            )


        let selectedAllergenIds =
            Set(
                try await
                    selectedAllergenRequest
            )

        let availableAllergens =
            try await
                allergenRequest


        // MARK: Evaluate Current Recipe

        let inputs =
            ingredients.map {
                ingredient in

                IngredientAllergenInput(
                    id:
                        ingredient.id,
                    name:
                        ingredient.name,
                    offProductId:
                        ingredient
                            .offProductId
                )
            }

        let recipeEvaluation =
            try await
                IngredientAllergenService
                    .evaluateRecipe(
                        ingredients:
                            inputs
                    )


        // MARK: Resolve User Allergens

        let selectedAllergens =
            availableAllergens
                .filter {

                    selectedAllergenIds
                        .contains(
                            $0.id
                        )
                }
                .sorted {

                    $0.name
                        .localizedCaseInsensitiveCompare(
                            $1.name
                        )
                        ==
                        .orderedAscending
                }


        // MARK: Find Conflicts

        var conflicts:
            [RecipeAllergenConflict] = []


        for association in
            recipeEvaluation
                .allergenAssociations {

            guard
                selectedAllergenIds
                    .contains(
                        association
                            .allergen
                            .id
                    )
            else {
                continue
            }


            conflicts.append(
                RecipeAllergenConflict(
                    allergen:
                        association.allergen,
                    ingredientNames:
                        association
                            .ingredientNames
                )
            )
        }


        conflicts.sort {

            $0.allergen.name
                .localizedCaseInsensitiveCompare(
                    $1.allergen.name
                )
                ==
                .orderedAscending
        }


        // MARK: Determine State

        let state:
            RecipeDietaryCheckState


        if !conflicts.isEmpty {

            state =
                .conflict

        } else if
            recipeEvaluation
                .hasUnknownIngredients {

            state =
                .incomplete

        } else {

            state =
                .noKnownConflict
        }


        return RecipeDietaryCheckResult(
            recipeId:
                recipeId,
            state:
                state,
            selectedAllergens:
                selectedAllergens,
            conflicts:
                conflicts,
            unknownIngredients:
                recipeEvaluation
                    .unknownIngredients,
            knownIngredientsWithoutMappedAllergens:
                recipeEvaluation
                    .knownIngredientsWithoutMappedAllergens
        )
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


// MARK: - Conflict

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


// MARK: - State

enum RecipeDietaryCheckState:
    String,
    Codable,
    Hashable {

    case conflict

    case noKnownConflict

    case incomplete
}

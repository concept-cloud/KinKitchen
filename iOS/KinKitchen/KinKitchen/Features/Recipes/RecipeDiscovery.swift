//
//  RecipeDiscovery.swift
//  KinKitchen
//
//  Created by Greg Hudler on 10/4/26.
//

import Foundation

// MARK: - Recipe Discovery Criteria

/// Search and filter state for the Recipes screen.
///
/// Results are always recalculated from the loaded
/// recipe collection, which is never modified.
struct RecipeDiscoveryCriteria:
    Equatable {

    var searchText = ""

    /// Selected categories. A recipe matches when it belongs
    /// to any of them.
    var categories: Set<RecipeCategory> = []

    /// Selected dietary restriction IDs. A recipe is hidden
    /// when it has a known conflict with any of them.
    var restrictionIds: Set<UUID> = []


    var trimmedSearchText: String {

        searchText.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
    }


    var isSearching: Bool {

        !trimmedSearchText.isEmpty
    }


    /// Number of active filters, not counting search.
    var activeFilterCount: Int {

        categories.count
            + restrictionIds.count
    }


    /// Selected restrictions in display order.
    func selectedRestrictions(
        from restrictions: [DietaryRestriction]
    ) -> [DietaryRestriction] {

        restrictions.filter {
            restrictionIds.contains($0.id)
        }
    }


    /// Selected categories in display order.
    var sortedCategories: [RecipeCategory] {

        RecipeCategory.allCases.filter {
            categories.contains($0)
        }
    }


    var hasActiveFilters: Bool {

        activeFilterCount > 0
    }


    func matches(
        _ recipe: Recipe,
        context: RecipeDiscoveryContext
    ) -> Bool {

        if isSearching,
           !recipe.name
            .localizedCaseInsensitiveContains(
                trimmedSearchText
            ) {
            return false
        }

        if !categories.isEmpty {

            guard
                let recipeCategory =
                    recipe.recipeCategory,
                categories.contains(
                    recipeCategory
                )
            else {
                return false
            }
        }

        // Only known conflicts hide a recipe. Unverified
        // recipes stay visible with a label.
        for restriction in selectedRestrictions(
            from: context.restrictions
        ) {

            if case .conflict =
                context.restrictionStatus(
                    of: recipe,
                    for: restriction
                ) {
                return false
            }
        }

        return true
    }


    func apply(
        to recipes: [Recipe],
        context: RecipeDiscoveryContext
    ) -> [Recipe] {

        recipes.filter {
            matches(
                $0,
                context: context
            )
        }
    }
}

// MARK: - Recipe Dietary Insight

/// Dietary information loaded for one recipe in the list.
struct RecipeDietaryInsight {

    var ingredientNames: [String] = []

    /// Nil while the allergen check is running or if it failed.
    var allergenResult: RecipeAllergenAssociationResult?

    var allergenCheckFailed = false

    /// Restrictions the owner marked the recipe with.
    var taggedRestrictionIds: Set<UUID> = []


    var isCheckingAllergens: Bool {

        allergenResult == nil
            && !allergenCheckFailed
    }
}

// MARK: - Restriction Status

enum RecipeRestrictionStatus:
    Equatable {

    /// A known ingredient or allergen conflicts.
    case conflict

    /// Still checking allergens; no conflict found yet.
    case checking

    /// No known conflict and the owner marked it.
    case markedByOwner

    /// No known conflict and no owner mark.
    case notVerified
}

// MARK: - Discovery Context

/// Loaded data the criteria are evaluated against.
struct RecipeDiscoveryContext {

    var restrictions: [DietaryRestriction] = []

    var insights: [UUID: RecipeDietaryInsight] = [:]


    func restrictionStatus(
        of recipe: Recipe,
        for restriction: DietaryRestriction
    ) -> RecipeRestrictionStatus {

        guard
            let insight =
                insights[recipe.id]
        else {
            return .notVerified
        }

        let conflicts =
            RecipeDietaryCheckService
                .restrictionConflicts(
                    [restriction],
                    ingredientNames:
                        insight.ingredientNames,
                    allergenResult:
                        insight.allergenResult
                )

        if !conflicts.isEmpty {
            return .conflict
        }

        if insight.isCheckingAllergens {
            return .checking
        }

        return insight.taggedRestrictionIds
            .contains(restriction.id)
                ? .markedByOwner
                : .notVerified
    }
}

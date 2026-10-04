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

    /// Selected allergen IDs. A recipe is hidden when it is
    /// known to contain any of them.
    var allergenIds: Set<UUID> = []


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
            + allergenIds.count
    }


    /// Selected allergens in display order.
    func selectedAllergens(
        from allergens: [Allergen]
    ) -> [Allergen] {

        allergens.filter {
            allergenIds.contains($0.id)
        }
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


    /// True when search or any filter is narrowing the results.
    var isActive: Bool {

        isSearching || hasActiveFilters
    }


    /// Clears search and every filter. Only interface state
    /// changes; nothing stored is touched.
    mutating func reset() {

        self = RecipeDiscoveryCriteria()
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

        // Same for allergens: only a known allergen hides a
        // recipe. Incomplete information stays visible.
        for allergen in selectedAllergens(
            from: context.allergens
        ) {

            if case .contains =
                context.allergenStatus(
                    of: recipe,
                    for: allergen
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

// MARK: - Allergen Status

enum RecipeAllergenStatus:
    Equatable {

    /// An ingredient is known to contain the allergen.
    case contains

    /// Still checking; nothing found yet.
    case checking

    /// Some ingredients couldn't be evaluated (or there are none),
    /// so the allergen can't be ruled out.
    case incomplete

    /// Every ingredient was evaluated and none contain it.
    /// Not a guarantee of safety.
    case noKnownAllergen
}

// MARK: - Discovery Context

/// Loaded data the criteria are evaluated against.
struct RecipeDiscoveryContext {

    var restrictions: [DietaryRestriction] = []

    var allergens: [Allergen] = []

    /// The signed-in user's Dietary Profile selections.
    var profileAllergenIds: Set<UUID> = []

    var profileRestrictionIds: Set<UUID> = []

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


    /// Uses the existing allergen evaluation. Unknown
    /// ingredients are never treated as allergen-free.
    func allergenStatus(
        of recipe: Recipe,
        for allergen: Allergen
    ) -> RecipeAllergenStatus {

        guard
            let insight =
                insights[recipe.id]
        else {
            return .incomplete
        }

        if insight.isCheckingAllergens {
            return .checking
        }

        guard
            let result =
                insight.allergenResult
        else {
            // The check failed.
            return .incomplete
        }

        if result.allergenAssociations.contains(where: {
            $0.allergen.id == allergen.id
        }) {
            return .contains
        }

        if insight.ingredientNames.isEmpty
            || result.hasUnknownIngredients {
            return .incomplete
        }

        return .noKnownAllergen
    }


    /// Compares a recipe against the user's Dietary Profile using
    /// the same allergen and restriction checks as the filters.
    func profileConflict(
        of recipe: Recipe
    ) -> RecipeProfileConflict {

        let profileAllergens =
            allergens.filter {
                profileAllergenIds.contains($0.id)
            }

        let profileRestrictions =
            restrictions.filter {
                profileRestrictionIds.contains($0.id)
            }

        guard
            !profileAllergens.isEmpty
                || !profileRestrictions.isEmpty
        else {
            return RecipeProfileConflict()
        }

        let allergenStatuses =
            profileAllergens.map {
                ($0, allergenStatus(of: recipe, for: $0))
            }

        let restrictionStatuses =
            profileRestrictions.map {
                ($0, restrictionStatus(of: recipe, for: $0))
            }

        return RecipeProfileConflict(
            allergens:
                allergenStatuses
                    .filter { $0.1 == .contains }
                    .map(\.0),
            restrictions:
                restrictionStatuses
                    .filter { $0.1 == .conflict }
                    .map(\.0),
            isChecking:
                allergenStatuses.contains { $0.1 == .checking }
                || restrictionStatuses.contains { $0.1 == .checking },
            isIncomplete:
                allergenStatuses.contains { $0.1 == .incomplete }
        )
    }
}

// MARK: - Profile Conflict

/// Known conflicts between a recipe and the user's Dietary Profile.
/// An empty result is never a confirmation of safety.
struct RecipeProfileConflict:
    Equatable {

    var allergens: [Allergen] = []

    var restrictions: [DietaryRestriction] = []

    /// Still checking; more conflicts may appear.
    var isChecking = false

    /// Some ingredients couldn't be checked against the
    /// user's allergies.
    var isIncomplete = false


    var hasConflict: Bool {

        !allergens.isEmpty
            || !restrictions.isEmpty
    }


    /// e.g. "Milk, Egg, Vegan"
    var summary: String {

        (allergens.map(\.name) + restrictions.map(\.name))
            .joined(separator: ", ")
    }
}

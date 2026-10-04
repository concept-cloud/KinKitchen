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
        _ recipe: Recipe
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

        return true
    }


    func apply(
        to recipes: [Recipe]
    ) -> [Recipe] {

        recipes.filter {
            matches($0)
        }
    }
}

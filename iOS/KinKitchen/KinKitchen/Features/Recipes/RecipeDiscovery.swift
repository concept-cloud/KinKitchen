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


    var trimmedSearchText: String {

        searchText.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
    }


    var isSearching: Bool {

        !trimmedSearchText.isEmpty
    }


    func matches(
        _ recipe: Recipe
    ) -> Bool {

        guard isSearching else {
            return true
        }

        return recipe.name
            .localizedCaseInsensitiveContains(
                trimmedSearchText
            )
    }


    func apply(
        to recipes: [Recipe]
    ) -> [Recipe] {

        recipes.filter {
            matches($0)
        }
    }
}

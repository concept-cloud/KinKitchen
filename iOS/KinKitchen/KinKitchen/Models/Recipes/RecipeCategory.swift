//
//  RecipeCategory.swift
//  KinKitchen
//
//  Created by Greg Hudler on 10/4/26.
//

import Foundation

// MARK: - Recipe Category

/// Categories a recipe can be assigned. Stored on the recipe
/// as the raw value in `recipes.category`.
enum RecipeCategory:
    String,
    CaseIterable,
    Identifiable,
    Hashable {

    case breakfast = "Breakfast"
    case lunch = "Lunch"
    case dinner = "Dinner"
    case sideDish = "Side Dish"
    case dessert = "Dessert"
    case snack = "Snack"
    case drink = "Drink"
    case other = "Other"

    var id: String {
        rawValue
    }


    /// Matches stored text case-insensitively so recipes saved
    /// before categories were standardized still resolve.
    init?(
        matching value: String?
    ) {

        guard
            let value =
                value?.trimmingCharacters(
                    in: .whitespacesAndNewlines
                ),
            !value.isEmpty,
            let match =
                RecipeCategory.allCases.first(where: {
                    $0.rawValue
                        .caseInsensitiveCompare(value)
                        == .orderedSame
                })
        else {
            return nil
        }

        self = match
    }
}

// MARK: - Recipe Category Lookup

extension Recipe {

    /// The recipe's standard category, or nil when it has none
    /// or uses older free-text that isn't a standard category.
    var recipeCategory: RecipeCategory? {

        RecipeCategory(
            matching: category
        )
    }
}

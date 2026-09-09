//
//  Recipe.swift
//  KinKitchen
//
//  Created by Greg Hudler on 9/7/26.
//

import Foundation

struct Recipe: Codable, Identifiable, Hashable {

    let id: UUID
    let ownerId: UUID

    var name: String
    var description: String?
    var instructions: String?
    var servings: Int?

    var prepTimeMinutes: Int?
    var cookTimeMinutes: Int?

    var photoPath: String?
    var category: String?
    
    var sourceRecipeId: UUID?
    var originalRecipeId: UUID?
    
    let createdAt: String
    var updatedAt: String


    enum CodingKeys: String, CodingKey {

        case id
        case ownerId = "owner_id"
        case name
        case description
        case instructions
        case servings
        case prepTimeMinutes = "prep_time_minutes"
        case cookTimeMinutes = "cook_time_minutes"
        case photoPath = "photo_path"
        case category
        case sourceRecipeId = "source_recipe_id"
        case originalRecipeId = "original_recipe_id"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}


// MARK: - Recipe Create

struct RecipeCreate: Encodable {
    let ownerId: UUID
    let name: String
    let description: String?
    let instructions: String?
    let servings: Int?
    let prepTimeMinutes: Int?
    let cookTimeMinutes: Int?
    let photoPath: String?
    let category: String?
    let sourceRecipeId: UUID?
    let originalRecipeId: UUID?

    init(
        ownerId: UUID,
        name: String,
        description: String?,
        instructions: String?,
        servings: Int?,
        prepTimeMinutes: Int?,
        cookTimeMinutes: Int?,
        photoPath: String?,
        category: String?,
        sourceRecipeId: UUID?,
        originalRecipeId: UUID?
    ) {
        self.ownerId = ownerId
        self.name = name
        self.description = description
        self.instructions = instructions
        self.servings = servings
        self.prepTimeMinutes = prepTimeMinutes
        self.cookTimeMinutes = cookTimeMinutes
        self.photoPath = photoPath
        self.category = category
        self.sourceRecipeId = sourceRecipeId
        self.originalRecipeId = originalRecipeId
    }

    enum CodingKeys: String, CodingKey {
        case ownerId = "owner_id"
        case name
        case description
        case instructions
        case servings
        case prepTimeMinutes = "prep_time_minutes"
        case cookTimeMinutes = "cook_time_minutes"
        case photoPath = "photo_path"
        case category
        case sourceRecipeId = "source_recipe_id"
        case originalRecipeId = "original_recipe_id"
    }
}


// MARK: - Recipe Update

struct RecipeUpdate: Encodable {

    let name: String

    let description: String?
    let instructions: String?
    let servings: Int?

    let prepTimeMinutes: Int?
    let cookTimeMinutes: Int?

    let photoPath: String?
    let category: String?


    enum CodingKeys: String, CodingKey {

        case name

        case description

        case instructions

        case servings

        case prepTimeMinutes =
            "prep_time_minutes"

        case cookTimeMinutes =
            "cook_time_minutes"

        case photoPath =
            "photo_path"

        case category
    }
}


// MARK: - Display Helpers

extension Recipe {

    var totalTimeMinutes: Int {

        (prepTimeMinutes ?? 0) +
        (cookTimeMinutes ?? 0)
    }


    var formattedTotalTime: String {

        formatMinutes(
            totalTimeMinutes
        )
    }


    var formattedPrepTime: String {

        formatMinutes(
            prepTimeMinutes ?? 0
        )
    }


    var formattedCookTime: String {

        formatMinutes(
            cookTimeMinutes ?? 0
        )
    }


    private func formatMinutes(
        _ minutes: Int
    ) -> String {

        guard minutes > 0 else {

            return "—"
        }

        let hours =
            minutes / 60

        let remainingMinutes =
            minutes % 60

        if hours > 0 &&
            remainingMinutes > 0 {

            return "\(hours) hr \(remainingMinutes) min"
        }

        if hours > 0 {

            return hours == 1
                ? "1 hr"
                : "\(hours) hrs"
        }

        return "\(remainingMinutes) min"
    }
}


// MARK: - Recipe With Ingredients

struct RecipeWithIngredients {

    let recipe: Recipe
    let ingredients: [RecipeIngredient]


    var orderedIngredients:
        [RecipeIngredient] {

        ingredients.sorted {

            $0.sortOrder <
            $1.sortOrder
        }
    }
}

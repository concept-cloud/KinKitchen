//
//  RecipeRating.swift
//  KinKitchen
//
//  Created by Greg Hudler on 9/7/26.
//

import Foundation

struct RecipeRating: Codable, Identifiable, Hashable {
    let id: UUID
    let recipeId: UUID
    let userId: UUID
    let rating: Int
    let createdAt: String
    let updatedAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case recipeId = "recipe_id"
        case userId = "user_id"
        case rating
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct RecipeRatingSummary {
    let averageRating: Double?
    let ratingCount: Int
    let currentUserRating: Int?
}

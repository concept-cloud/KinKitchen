//
//  RecipeStory.swift
//  KinKitchen
//

import Foundation

struct RecipeStory: Codable, Identifiable, Hashable {
    let id: UUID
    let recipeId: UUID
    var story: String?
    var originalContributor: String?
    var contributorUserId: UUID?
    let createdAt: String
    var updatedAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case recipeId = "recipe_id"
        case story
        case originalContributor = "original_contributor"
        case contributorUserId = "contributor_user_id"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct RecipeStoryCreate: Encodable {
    let recipeId: UUID
    let story: String
    let contributorUserId: UUID

    enum CodingKeys: String, CodingKey {
        case recipeId = "recipe_id"
        case story
        case contributorUserId = "contributor_user_id"
    }
}

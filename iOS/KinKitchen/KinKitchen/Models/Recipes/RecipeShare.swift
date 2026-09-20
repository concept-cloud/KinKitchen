//
//  RecipeShare.swift
//  KinKitchen
//
//  Created by Greg Hudler on 9/20/26.
//

import Foundation

struct RecipeShare: Codable, Identifiable, Hashable {
    let id: UUID
    let recipeId: UUID
    let senderId: UUID
    let recipientId: UUID
    let createdAt: Date
    let savedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case recipeId = "recipe_id"
        case senderId = "sender_id"
        case recipientId = "recipient_id"
        case createdAt = "created_at"
        case savedAt = "saved_at"
    }
}

struct RecipeShareCreate: Encodable {
    let recipeId: UUID
    let senderId: UUID
    let recipientId: UUID

    enum CodingKeys: String, CodingKey {
        case recipeId = "recipe_id"
        case senderId = "sender_id"
        case recipientId = "recipient_id"
    }
}

//
//  GatheringDish.swift
//  KinKitchen
//
//  Created by Greg Hudler on 9/10/26.
//

import Foundation

struct GatheringDish: Codable, Identifiable, Hashable {
    let id: UUID
    let gatheringId: UUID
    let userId: UUID
    var recipeId: UUID?
    var gatheringNeedId: UUID?
    var name: String
    var category: DishCategory
    var notes: String?
    let createdAt: Date
    var updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case gatheringId = "gathering_id"
        case userId = "user_id"
        case recipeId = "recipe_id"
        case gatheringNeedId = "gathering_need_id"
        case name
        case category
        case notes
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// MARK: - Create Payload

struct GatheringDishCreate: Encodable {
    let gatheringId: UUID
    let userId: UUID
    let recipeId: UUID?
    let gatheringNeedId: UUID?
    let name: String
    let category: DishCategory
    let notes: String?

    enum CodingKeys: String, CodingKey {
        case gatheringId = "gathering_id"
        case userId = "user_id"
        case recipeId = "recipe_id"
        case gatheringNeedId = "gathering_need_id"
        case name
        case category
        case notes
    }
}

// MARK: - Update Payload

struct GatheringDishUpdate: Encodable {
    let recipeId: UUID?
    let gatheringNeedId: UUID?
    let name: String
    let category: DishCategory
    let notes: String?

    enum CodingKeys: String, CodingKey {
        case recipeId = "recipe_id"
        case gatheringNeedId = "gathering_need_id"
        case name
        case category
        case notes
    }
}

//
//  Cookbook.swift
//  KinKitchen
//
//  Created by Greg Hudler on 9/23/26.
//

import Foundation

// MARK: - Cookbook Visibility

enum CookbookVisibility: String, Codable, CaseIterable {
    case `private`
    case shared
}

// MARK: - Cookbook

struct Cookbook: Codable, Identifiable, Hashable {
    let id: UUID
    let ownerId: UUID
    var name: String
    var description: String?
    var coverPath: String?
    var visibility: CookbookVisibility
    let createdAt: Date
    var updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case ownerId = "owner_id"
        case name
        case description
        case coverPath = "cover_path"
        case visibility
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// MARK: - Cookbook Create

struct CookbookCreate: Encodable {
    let ownerId: UUID
    let name: String
    let description: String?
    let coverPath: String?
    let visibility: CookbookVisibility

    enum CodingKeys: String, CodingKey {
        case ownerId = "owner_id"
        case name
        case description
        case coverPath = "cover_path"
        case visibility
    }
}

// MARK: - Cookbook Update

struct CookbookUpdate: Encodable {
    let name: String
    let description: String?
    let coverPath: String?

    enum CodingKeys: String, CodingKey {
        case name
        case description
        case coverPath = "cover_path"
    }
}

// MARK: - Cookbook Recipe

struct CookbookRecipe: Codable, Hashable {
    let cookbookId: UUID
    let recipeId: UUID
    let sectionId: UUID?
    let sortOrder: Int

    enum CodingKeys: String, CodingKey {
        case cookbookId = "cookbook_id"
        case recipeId = "recipe_id"
        case sectionId = "section_id"
        case sortOrder = "sort_order"
    }
}

// MARK: - Cookbook Recipe Order

extension CookbookRecipe {

    /// Saved position first. Recipes added before ordering existed
    /// all share position 0, so ties fall back to the recipe ID to
    /// keep the order stable between loads.
    static func displayOrder(
        _ first: CookbookRecipe,
        _ second: CookbookRecipe
    ) -> Bool {
        if first.sortOrder != second.sortOrder {
            return first.sortOrder < second.sortOrder
        }
        return first.recipeId.uuidString
            < second.recipeId.uuidString
    }
}

// MARK: - Cookbook Section

/// A named group of recipes inside one cookbook, e.g. "Desserts".
/// Row in `cookbook_sections`.
struct CookbookSection: Codable, Identifiable, Hashable {
    let id: UUID
    let cookbookId: UUID
    var name: String
    var sortOrder: Int

    /// Longest allowed section name (matches the database check).
    static let maxNameLength = 60

    enum CodingKeys: String, CodingKey {
        case id
        case cookbookId = "cookbook_id"
        case name
        case sortOrder = "sort_order"
    }
}

// MARK: - Cookbook Section Create

struct CookbookSectionCreate: Encodable {
    let cookbookId: UUID
    let name: String
    let sortOrder: Int

    enum CodingKeys: String, CodingKey {
        case cookbookId = "cookbook_id"
        case name
        case sortOrder = "sort_order"
    }
}

// MARK: - Cookbook Recipe Placement

/// Where a recipe sits in a cookbook: its section (nil = Unsorted)
/// and position. Only these columns are updated; the recipe itself
/// is never touched.
struct CookbookRecipePlacement: Encodable {
    let sectionId: UUID?
    let sortOrder: Int

    enum CodingKeys: String, CodingKey {
        case sectionId = "section_id"
        case sortOrder = "sort_order"
    }

    // Always send section_id, including null, so moving a recipe
    // back to Unsorted actually clears it.
    func encode(to encoder: Encoder) throws {
        var container =
            encoder.container(keyedBy: CodingKeys.self)
        try container.encode(sectionId, forKey: .sectionId)
        try container.encode(sortOrder, forKey: .sortOrder)
    }
}

// MARK: - Cookbook Recipe Create

struct CookbookRecipeCreate: Encodable {
    let cookbookId: UUID
    let recipeId: UUID
    let sortOrder: Int

    enum CodingKeys: String, CodingKey {
        case cookbookId = "cookbook_id"
        case recipeId = "recipe_id"
        case sortOrder = "sort_order"
    }
}

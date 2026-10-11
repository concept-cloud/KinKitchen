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
    /// Price in cents. 0 = free, which every cookbook is for now;
    /// stored so cookbooks can be sold later.
    var priceCents: Int = 0
    var currency: String = "USD"
    let createdAt: Date
    var updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case ownerId = "owner_id"
        case name
        case description
        case coverPath = "cover_path"
        case visibility
        case priceCents = "price_cents"
        case currency
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

extension Cookbook {

    /// Price and currency default to free/USD when missing, so
    /// cookbooks load the same before and after the price columns.
    init(from decoder: Decoder) throws {
        let container =
            try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(UUID.self, forKey: .id)
        ownerId = try container.decode(UUID.self, forKey: .ownerId)
        name = try container.decode(String.self, forKey: .name)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        coverPath = try container.decodeIfPresent(String.self, forKey: .coverPath)
        visibility = try container.decode(CookbookVisibility.self, forKey: .visibility)
        priceCents = try container.decodeIfPresent(Int.self, forKey: .priceCents) ?? 0
        currency = try container.decodeIfPresent(String.self, forKey: .currency) ?? "USD"
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
    }

    var isFree: Bool {
        priceCents == 0
    }

    /// "Free", or e.g. "$12.99".
    var displayPrice: String {
        guard !isFree else {
            return "Free"
        }

        return (Double(priceCents) / 100)
            .formatted(.currency(code: currency))
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
    /// Shown in full in the cookbook preview. Up to
    /// `CookbookRecipe.maxFeaturedPerSection` per section.
    var isFeatured: Bool = false

    static let maxFeaturedPerSection = 3

    enum CodingKeys: String, CodingKey {
        case cookbookId = "cookbook_id"
        case recipeId = "recipe_id"
        case sectionId = "section_id"
        case sortOrder = "sort_order"
        case isFeatured = "is_featured"
    }
}

extension CookbookRecipe {

    /// `is_featured` defaults to false when missing.
    init(from decoder: Decoder) throws {
        let container =
            try decoder.container(keyedBy: CodingKeys.self)

        cookbookId = try container.decode(UUID.self, forKey: .cookbookId)
        recipeId = try container.decode(UUID.self, forKey: .recipeId)
        sectionId = try container.decodeIfPresent(UUID.self, forKey: .sectionId)
        sortOrder = try container.decode(Int.self, forKey: .sortOrder)
        isFeatured = try container.decodeIfPresent(Bool.self, forKey: .isFeatured) ?? false
    }

    /// Whether another recipe can be featured in this section.
    static func canFeature(
        in sectionId: UUID?,
        relationships: [CookbookRecipe]
    ) -> Bool {
        relationships
            .filter {
                $0.sectionId == sectionId && $0.isFeatured
            }
            .count < maxFeaturedPerSection
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

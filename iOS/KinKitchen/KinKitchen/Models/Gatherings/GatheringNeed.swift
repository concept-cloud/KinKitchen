import Foundation

struct GatheringNeed: Codable, Identifiable, Hashable {
    let id: UUID
    let gatheringId: UUID
    var category: DishCategory
    var name: String
    var quantityNeeded: Int
    var recipeId: UUID?
    var notes: String?
    let createdAt: Date
    var updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case gatheringId = "gathering_id"
        case category
        case name
        case quantityNeeded = "quantity_needed"
        case recipeId = "recipe_id"
        case notes
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// MARK: - Dish Category

enum DishCategory: String, Codable, CaseIterable, Hashable {
    case entree
    case side
    case dessert
    case drink
    case supplies
    case other

    var displayName: String {
        switch self {
        case .entree:
            return "Entrée"
        case .side:
            return "Side Dish"
        case .dessert:
            return "Dessert"
        case .drink:
            return "Drink"
        case .supplies:
            return "Supplies"
        case .other:
            return "Other"
        }
    }
}

// MARK: - Dish Need

enum DishNeed: String, Codable, CaseIterable, Hashable {
    case electricity
    case refrigeration
    case freezer
    case oven
    case stovetop
    case microwave
    case grill
    case keepWarm = "keep_warm"
    case keepCold = "keep_cold"
    case prepSpace = "prep_space"

    var displayName: String {
        switch self {
        case .electricity:
            return "Electricity"
        case .refrigeration:
            return "Refrigeration"
        case .freezer:
            return "Freezer"
        case .oven:
            return "Oven"
        case .stovetop:
            return "Stovetop"
        case .microwave:
            return "Microwave"
        case .grill:
            return "Grill"
        case .keepWarm:
            return "Keep Warm"
        case .keepCold:
            return "Keep Cold"
        case .prepSpace:
            return "Prep Space"
        }
    }
}

// MARK: - Dish Supply

enum DishSupply: String, Codable, CaseIterable, Hashable {
    case servingSpoon = "serving_spoon"
    case servingFork = "serving_fork"
    case servingTongs = "serving_tongs"
    case servingKnife = "serving_knife"
    case ladle
    case plates
    case bowls
    case cups
    case napkins
    case utensils
    case ice
    case extensionCord = "extension_cord"
    case powerStrip = "power_strip"

    var displayName: String {
        switch self {
        case .servingSpoon:
            return "Serving Spoon"
        case .servingFork:
            return "Serving Fork"
        case .servingTongs:
            return "Serving Tongs"
        case .servingKnife:
            return "Serving Knife"
        case .ladle:
            return "Ladle"
        case .plates:
            return "Plates"
        case .bowls:
            return "Bowls"
        case .cups:
            return "Cups"
        case .napkins:
            return "Napkins"
        case .utensils:
            return "Utensils"
        case .ice:
            return "Ice"
        case .extensionCord:
            return "Extension Cord"
        case .powerStrip:
            return "Power Strip"
        }
    }
}

// MARK: - Gathering Need Claim

struct GatheringNeedClaim: Codable, Identifiable, Hashable {
    let id: UUID
    let gatheringNeedId: UUID
    let userId: UUID
    var quantity: Int
    let createdAt: Date
    var updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case gatheringNeedId = "gathering_need_id"
        case userId = "user_id"
        case quantity
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// MARK: - Gathering Need Requirement

struct GatheringNeedRequirement: Codable, Hashable {
    let gatheringNeedId: UUID
    let need: DishNeed

    enum CodingKeys: String, CodingKey {
        case gatheringNeedId = "gathering_need_id"
        case need
    }
}

// MARK: - Gathering Need Supply

struct GatheringNeedSupply: Codable, Hashable {
    let gatheringNeedId: UUID
    let supply: DishSupply

    enum CodingKeys: String, CodingKey {
        case gatheringNeedId = "gathering_need_id"
        case supply
    }
}

// MARK: - Create Payload

struct GatheringNeedCreate: Encodable {
    let gatheringId: UUID
    let category: DishCategory
    let name: String
    let quantityNeeded: Int
    let recipeId: UUID?
    let notes: String?

    enum CodingKeys: String, CodingKey {
        case gatheringId = "gathering_id"
        case category
        case name
        case quantityNeeded = "quantity_needed"
        case recipeId = "recipe_id"
        case notes
    }
}

// MARK: - Update Payload

struct GatheringNeedUpdate: Encodable {
    let category: DishCategory
    let name: String
    let quantityNeeded: Int
    let recipeId: UUID?
    let notes: String?

    enum CodingKeys: String, CodingKey {
        case category
        case name
        case quantityNeeded = "quantity_needed"
        case recipeId = "recipe_id"
        case notes
    }
}

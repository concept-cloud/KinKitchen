//
//  RecipeIngredient.swift
//  KinKitchen
//
//  Created by Greg Hudler on 9/7/26.
//

import Foundation

struct RecipeIngredient:
    Codable,
    Identifiable,
    Hashable {

    let id: UUID

    let recipeId: UUID

    var name: String

    var quantity: Double?

    var unit: String?

    var offProductId: String?

    var allergenClassificationVersion: Int

    var sortOrder: Int

    let createdAt: String


    enum CodingKeys:
        String,
        CodingKey {

        case id

        case recipeId =
            "recipe_id"

        case name

        case quantity

        case unit

        case offProductId =
            "off_product_id"

        case allergenClassificationVersion =
            "allergen_classification_version"

        case sortOrder =
            "sort_order"

        case createdAt =
            "created_at"
    }
}


// MARK: - Ingredient Create

struct RecipeIngredientCreate:
    Encodable {

    let recipeId: UUID

    let name: String

    let quantity: Double?

    let unit: String?

    let offProductId: String?

    let sortOrder: Int


    enum CodingKeys:
        String,
        CodingKey {

        case recipeId =
            "recipe_id"

        case name

        case quantity

        case unit

        case offProductId =
            "off_product_id"

        case sortOrder =
            "sort_order"
    }
}


// MARK: - Ingredient Update

struct RecipeIngredientUpdate:
    Encodable {

    let name: String

    let quantity: Double?

    let unit: String?

    let offProductId: String?

    let sortOrder: Int


    enum CodingKeys:
        String,
        CodingKey {

        case name

        case quantity

        case unit

        case offProductId =
            "off_product_id"

        case sortOrder =
            "sort_order"
    }
}

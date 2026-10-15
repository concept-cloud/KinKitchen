//
//  DietaryRestriction.swift
//  KinKitchen
//
//  Created by Greg Hudler on 8/28/26.
//

import Foundation

struct DietaryRestriction: Codable, Identifiable, Hashable {
    let id: UUID
    let name: String
    let createdAt: Date

    /// Added by the user themselves (`custom_dietary_items`) rather
    /// than picked from the built-in list. Matched against ingredient
    /// names by word, since the allergen catalog doesn't know it.
    var isCustom = false

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case createdAt = "created_at"
    }
}

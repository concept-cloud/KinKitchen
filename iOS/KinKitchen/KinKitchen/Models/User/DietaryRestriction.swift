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

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case createdAt = "created_at"
    }
}

//
//  DietaryProfile.swift
//  KinKitchen
//
//  Created by Greg Hudler on 8/30/26.
//

import Foundation

struct DietaryProfile: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    var visibility: DietaryVisibility
    var notes: String?
    let createdAt: Date
    var updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case visibility
        case notes
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

enum DietaryVisibility: String, Codable, CaseIterable {
    case `private`
    case connections
    case gatherings
    case `public`
}

//
//  Profile.swift
//  KinKitchen
//
//  Created by Greg Hudler on 8/27/26.
//

import Foundation

struct Profile: Codable, Identifiable {

    let id: UUID

    var username: String?
    var displayName: String?
    var firstName: String?
    var lastName: String?
    var location: String?
    var birthDate: String?
    var bio: String?
    var profilePhotoPath: String?

    let createdAt: Date
    var updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case username
        case displayName = "display_name"
        case firstName = "first_name"
        case lastName = "last_name"
        case location
        case birthDate = "birth_date"
        case bio
        case profilePhotoPath = "profile_photo_path"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

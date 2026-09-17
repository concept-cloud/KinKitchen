//
//  ProfileSearchResult.swift
//  KinKitchen
//
//  Created by Greg Hudler on 9/17/26.
//

import Foundation

// MARK: - Profile Search Result

struct ProfileSearchResult:
    Codable,
    Identifiable,
    Hashable {

    let id: UUID
    let username: String?
    let displayName: String?
    let firstName: String?
    let lastName: String?
    let profilePhotoPath: String?

    enum CodingKeys:
        String,
        CodingKey {

        case id
        case username
        case displayName =
            "display_name"
        case firstName =
            "first_name"
        case lastName =
            "last_name"
        case profilePhotoPath =
            "profile_photo_path"
    }
}

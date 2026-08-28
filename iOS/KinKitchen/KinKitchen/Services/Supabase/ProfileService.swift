//
//  ProfileService.swift
//  KinKitchen
//
//  Created by Greg Hudler on 8/27/26.
//

import Foundation
import Supabase

enum ProfileService {

    static func fetchCurrentProfile() async throws -> Profile {
        let user = try await SupabaseManager.client.auth.session.user

        let profile: Profile = try await SupabaseManager.client
            .from("profiles")
            .select()
            .eq("id", value: user.id)
            .single()
            .execute()
            .value

        return profile
    }

    static func updateProfile(
        displayName: String,
        username: String,
        bio: String
    ) async throws {
        let user = try await SupabaseManager.client.auth.session.user

        let updates = ProfileUpdate(
            displayName: displayName,
            username: username,
            bio: bio
        )

        try await SupabaseManager.client
            .from("profiles")
            .update(updates)
            .eq("id", value: user.id)
            .execute()
    }
}

private struct ProfileUpdate: Encodable {
    let displayName: String
    let username: String
    let bio: String

    enum CodingKeys: String, CodingKey {
        case displayName = "display_name"
        case username
        case bio
    }
}

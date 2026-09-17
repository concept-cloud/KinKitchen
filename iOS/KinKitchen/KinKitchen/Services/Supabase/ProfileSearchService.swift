//
//  Untitled.swift
//  KinKitchen
//
//  Created by Greg Hudler on 9/17/26.
//

import Foundation
import Supabase

// MARK: - Profile Search Service

enum ProfileSearchService {

    // MARK: - Search Users

    // MARK: - Search Users

    static func searchUsers(
        query: String
    ) async throws -> [ProfileSearchResult] {

        let search =
            query.trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        guard !search.isEmpty else {
            return []
        }

        let user =
            try await SupabaseManager.client
                .auth
                .session
                .user

        let filter =
            "username.ilike.%\(search)%,display_name.ilike.%\(search)%,first_name.ilike.%\(search)%,last_name.ilike.%\(search)%"

        let results: [ProfileSearchResult] =
            try await SupabaseManager.client
                .from("profiles")
                .select(
                    """
                    id,
                    username,
                    display_name,
                    first_name,
                    last_name,
                    profile_photo_path
                    """
                )
                .or(filter)
                .neq(
                    "id",
                    value: user.id
                )
                .limit(20)
                .execute()
                .value

        return results
    }
}

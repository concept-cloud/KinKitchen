//
//  DietaryBackgroundSync.swift
//  KinKitchen
//
//  Created by Greg Hudler on 10/14/26.
//

import Foundation
import Supabase

/// Keeps the Dietary Profile background on the account
/// (`profiles.dietary_background`), so it follows the user to a new
/// phone. The phone's copy is used for display, so the screen never
/// waits on the network.
enum DietaryBackgroundSync {

    private struct Row: Codable {
        let dietaryBackground: String?

        enum CodingKeys: String, CodingKey {
            case dietaryBackground = "dietary_background"
        }
    }

    private static var defaults: UserDefaults { .standard }

    /// Saves on this phone right away, then on the account.
    static func choose(
        _ background: KinDietaryBackground
    ) async {

        defaults.set(
            background.rawValue,
            forKey: KinDietaryBackground.storageKey
        )

        do {
            try await upload(background)
        } catch {
            print(
                "DIETARY BACKGROUND SAVE ERROR:",
                error.localizedDescription
            )
        }
    }

    /// After sign-in: the account's choice wins. If the account has
    /// none yet but this phone does (picked before syncing existed),
    /// the phone's choice is saved to the account.
    static func pull() async {

        do {
            let user =
                try await SupabaseManager.client.auth.session.user

            let row: Row =
                try await SupabaseManager.client
                    .from("profiles")
                    .select("dietary_background")
                    .eq("id", value: user.id)
                    .single()
                    .execute()
                    .value

            if let value = row.dietaryBackground {

                // A value from a newer app version is left alone.
                if let background =
                    KinDietaryBackground(databaseValue: value) {
                    defaults.set(
                        background.rawValue,
                        forKey: KinDietaryBackground.storageKey
                    )
                }

            } else if
                let local = defaults.string(
                    forKey: KinDietaryBackground.storageKey
                ),
                let background = KinDietaryBackground(rawValue: local)
            {
                try await upload(background)
            }

        } catch {
            print(
                "DIETARY BACKGROUND LOAD ERROR:",
                error.localizedDescription
            )
        }
    }

    /// On sign-out, so the next account doesn't inherit it.
    static func clearLocal() {
        defaults.removeObject(
            forKey: KinDietaryBackground.storageKey
        )
    }

    private static func upload(
        _ background: KinDietaryBackground
    ) async throws {

        let user =
            try await SupabaseManager.client.auth.session.user

        try await SupabaseManager.client
            .from("profiles")
            .update(Row(dietaryBackground: background.databaseValue))
            .eq("id", value: user.id)
            .execute()
    }
}

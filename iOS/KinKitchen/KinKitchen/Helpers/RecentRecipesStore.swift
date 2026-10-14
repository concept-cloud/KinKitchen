//
//  RecentRecipesStore.swift
//  KinKitchen
//
//  Created by Greg Hudler on 10/13/26.
//

import Foundation

/// Remembers which recipes the signed-in user opened most recently, on
/// this device only. Stores IDs, not recipes: Home always reloads them
/// through Supabase, so anything the user can no longer access drops out.
nonisolated struct RecentRecipesStore {

    static let maxCount = 12

    let defaults: UserDefaults

    init(
        defaults: UserDefaults = .standard
    ) {

        self.defaults = defaults
    }


    /// Most recent first.
    func recipeIds(
        for userId: UUID
    ) -> [UUID] {

        (defaults.stringArray(
            forKey: key(for: userId)
        ) ?? [])
        .compactMap(UUID.init(uuidString:))
    }


    func recordView(
        of recipeId: UUID,
        by userId: UUID
    ) {

        let updated =
            Self.recording(
                recipeId,
                in: recipeIds(for: userId)
            )

        defaults.set(
            updated.map(\.uuidString),
            forKey: key(for: userId)
        )
    }


    /// Moves `recipeId` to the front, without duplicates, keeping at
    /// most `maxCount`.
    static func recording(
        _ recipeId: UUID,
        in ids: [UUID]
    ) -> [UUID] {

        Array(
            ([recipeId] + ids.filter { $0 != recipeId })
                .prefix(maxCount)
        )
    }


    /// Recently viewed first, then the user's own newest recipes, with
    /// no duplicates. Viewed IDs the user can no longer load (deleted,
    /// unshared, archived) are skipped.
    static func merged(
        viewedIds: [UUID],
        viewed: [Recipe],
        own: [Recipe],
        limit: Int
    ) -> [Recipe] {

        let viewedById =
            Dictionary(
                viewed.map { ($0.id, $0) },
                uniquingKeysWith: { first, _ in first }
            )

        var result: [Recipe] = []
        var seen = Set<UUID>()

        let ordered =
            viewedIds.compactMap { viewedById[$0] }
                .filter { $0.archivedAt == nil }
            + own

        for recipe in ordered
        where !seen.contains(recipe.id) {

            seen.insert(recipe.id)
            result.append(recipe)

            if result.count == limit {
                break
            }
        }

        return result
    }


    private func key(
        for userId: UUID
    ) -> String {

        "recentRecipeIds.\(userId.uuidString)"
    }
}

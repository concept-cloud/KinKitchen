//
//  RecipeAttribution.swift
//  KinKitchen
//
//  Created by Greg Hudler on 10/4/26.
//

import Foundation

// MARK: - Recipe Attribution

/// Who created a recipe versus who passed it along.
///
/// Authorship always comes from the recipe and its lineage
/// (`owner_id`, `original_recipe_id`, `original_contributor`).
/// Senders always come from `recipe_shares`. Saving a recipe
/// touches neither, so a saved recipe keeps its original
/// attribution no matter how many people it passed through.
enum RecipeAttribution {

    /// The user who created the original recipe.
    ///
    /// For someone's version of a recipe, that's the owner of
    /// the original. Returns nil when the original can't be
    /// loaded, rather than crediting the version's owner.
    static func originalAuthorId(
        of recipe: Recipe,
        originalOwners: [UUID: UUID]
    ) -> UUID? {

        guard
            let originalId =
                recipe.originalRecipeId
        else {
            return recipe.ownerId
        }

        return originalOwners[originalId]
    }


    /// Everyone who shared the recipe with the user, newest
    /// share first, each listed once.
    static func senderIds(
        of recipeId: UUID,
        in shares: [RecipeShare]
    ) -> [UUID] {

        var seen: Set<UUID> = []

        return shares
            .filter { $0.recipeId == recipeId }
            .sorted { $0.createdAt > $1.createdAt }
            .map(\.senderId)
            .filter { seen.insert($0).inserted }
    }


    /// e.g. "Sam", "Sam and Alex", "Sam and 2 others".
    static func senderSummary(
        _ names: [String]
    ) -> String? {

        switch names.count {
        case 0:
            return nil
        case 1:
            return names[0]
        case 2:
            return "\(names[0]) and \(names[1])"
        default:
            return "\(names[0]) and \(names.count - 1) others"
        }
    }


    /// e.g. "By Rose · version by Sam · originally from Grandma Rose".
    static func authorLine(
        for recipe: Recipe,
        authorId: UUID?,
        name: (UUID) -> String
    ) -> String? {

        var parts: [String] = []

        if let authorId {
            parts.append(
                "By \(name(authorId))"
            )

            // Someone's version of the original.
            if recipe.ownerId != authorId {
                parts.append(
                    "version by \(name(recipe.ownerId))"
                )
            }
        }

        // Story & Legacy contributor, kept as entered.
        if let contributor =
            recipe.originalContributor?
                .trimmingCharacters(
                    in: .whitespacesAndNewlines
                ),
           !contributor.isEmpty {
            parts.append(
                "originally from \(contributor)"
            )
        }

        guard !parts.isEmpty else {
            return nil
        }

        let line =
            parts.joined(separator: " · ")

        return line.prefix(1).uppercased()
            + line.dropFirst()
    }
}

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
    /// the original, saved on the version when it was made, so the
    /// credit survives the original being unshared or deleted.
    /// Older versions without it fall back to the loaded original,
    /// and return nil rather than crediting the version's owner.
    static func originalAuthorId(
        of recipe: Recipe,
        originalOwners: [UUID: UUID]
    ) -> UUID? {

        if let savedOwner = recipe.originalOwnerId {
            return savedOwner
        }

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


    /// Where a version came from, from the lineage saved when it was
    /// made, so it reads the same after the original is gone.
    /// e.g. "Adapted from “Sunday Gravy” by Rose". Nil for recipes
    /// that aren't versions.
    static func versionOrigin(
        for recipe: Recipe,
        name: (UUID) -> String
    ) -> String? {

        guard recipe.isVersion else {
            return nil
        }

        guard let title = recipe.originalTitle else {
            return "Adapted from another recipe"
        }

        guard let authorId = recipe.originalOwnerId else {
            return "Adapted from \u{201C}\(title)\u{201D}"
        }

        return "Adapted from \u{201C}\(title)\u{201D} by \(name(authorId))"
    }


    /// For a version of someone else's version, the cook whose
    /// version it was copied from. e.g. "Made from the version by
    /// Sam, “Sam's Gravy”". Nil when copied straight from the
    /// original.
    static func versionSource(
        for recipe: Recipe,
        name: (UUID) -> String
    ) -> String? {

        guard
            let sourceOwnerId = recipe.sourceOwnerId,
            sourceOwnerId != recipe.originalOwnerId
        else {
            return nil
        }

        guard let sourceName = recipe.sourceRecipeName else {
            return "Made from the version by \(name(sourceOwnerId))"
        }

        return "Made from the version by \(name(sourceOwnerId)), \u{201C}\(sourceName)\u{201D}"
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

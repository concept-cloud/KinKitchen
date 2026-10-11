//
//  VersionSuggestionService.swift
//  KinKitchen
//
//  Created by Greg Hudler on 10/11/26.
//

import Foundation

// MARK: - Version Suggestion

/// Another recipe in the same family (the original or a version of
/// it) where the existing dietary check found none of the user's
/// conflicts. Never a promise that the recipe is allergy-safe.
nonisolated struct VersionSuggestion:
    Identifiable,
    Hashable {

    let recipe: Recipe
    let fit: Fit

    var id: UUID {
        recipe.id
    }

    enum Fit:
        Int,
        Hashable,
        Comparable {

        /// Every ingredient was checked and nothing in the user's
        /// Dietary Profile was detected.
        case noDetectedConflict = 0

        /// Nothing detected, but some ingredients couldn't be
        /// checked.
        case maySuit = 1

        static func < (lhs: Fit, rhs: Fit) -> Bool {
            lhs.rawValue < rhs.rawValue
        }

        var label: String {
            switch self {
            case .noDetectedConflict:
                "No detected conflict"
            case .maySuit:
                "May be suitable · some ingredients unchecked"
            }
        }
    }
}


// MARK: - Version Suggestions

nonisolated struct VersionSuggestions:
    Hashable {

    /// What the user's Dietary Profile flagged in the recipe being
    /// viewed, e.g. ["Peanuts", "Vegan"].
    let conflictNames: [String]

    let suggestions: [VersionSuggestion]
}


// MARK: - Service

enum VersionSuggestionService {

    /// Most family members checked per recipe view.
    static let candidateLimit = 12

    /// Checks the recipe and the other accessible recipes in its
    /// family against the user's Dietary Profile, using the same
    /// allergen and restriction detection as everywhere else.
    /// Returns nil when the recipe has no detected conflict or no
    /// alternative qualifies, so only the normal warning shows.
    static func suggestions(
        for recipe: Recipe,
        userId: UUID
    ) async -> VersionSuggestions? {

        guard
            let current =
                try? await RecipeDietaryCheckService
                    .checkRecipe(
                        recipeId: recipe.id,
                        for: userId
                    )
        else {
            return nil
        }

        let currentConflicts =
            conflictKeys(current)

        guard !currentConflicts.isEmpty else {
            return nil
        }

        // RLS limits this to recipes the user can already open.
        let family =
            (try? await RecipeService
                .fetchRecipeFamily(for: recipe)) ?? []

        let candidates =
            family
                .filter { $0.id != recipe.id }
                .prefix(candidateLimit)

        guard !candidates.isEmpty else {
            return nil
        }

        let suggestions =
            await withTaskGroup(
                of: VersionSuggestion?.self
            ) { group in

                for candidate in candidates {
                    group.addTask {
                        // A recipe that can't be checked is never
                        // suggested.
                        guard
                            let result =
                                try? await RecipeDietaryCheckService
                                    .checkRecipe(
                                        recipeId: candidate.id,
                                        for: userId
                                    ),
                            let fit =
                                fit(
                                    currentConflicts: currentConflicts,
                                    candidateConflicts:
                                        conflictKeys(result),
                                    candidateIsIncomplete:
                                        !result.unknownIngredients.isEmpty
                                )
                        else {
                            return nil
                        }

                        return VersionSuggestion(
                            recipe: candidate,
                            fit: fit
                        )
                    }
                }

                var found: [VersionSuggestion] = []

                for await suggestion in group {
                    if let suggestion {
                        found.append(suggestion)
                    }
                }

                return found
            }

        guard !suggestions.isEmpty else {
            return nil
        }

        return VersionSuggestions(
            conflictNames: conflictNames(current),
            suggestions: ranked(suggestions)
        )
    }


    // MARK: - Rules

    /// Allergen and restriction conflicts, as comparable keys.
    /// Preferences (dislikes) don't count; they aren't a safety
    /// concern and shouldn't drive suggestions.
    nonisolated static func conflictKeys(
        _ result: RecipientRecipeDietaryCheckResult
    ) -> Set<String> {

        Set(
            result.allergenConflicts.map {
                "allergen:\($0.allergen.id)"
            }
            + result.restrictionConflicts.map {
                "restriction:\($0.restriction.id)"
            }
        )
    }


    nonisolated static func conflictNames(
        _ result: RecipientRecipeDietaryCheckResult
    ) -> [String] {

        result.allergenConflicts.map(\.allergen.name)
            + result.restrictionConflicts.map(\.restriction.name)
    }


    /// Whether a family member is worth suggesting.
    ///
    /// Only when the viewed recipe has a detected conflict, and only
    /// candidates with no detected allergen or restriction conflict
    /// at all: one sharing the same conflict isn't an alternative,
    /// and one with a different conflict isn't a better match.
    nonisolated static func fit(
        currentConflicts: Set<String>,
        candidateConflicts: Set<String>,
        candidateIsIncomplete: Bool
    ) -> VersionSuggestion.Fit? {

        guard
            !currentConflicts.isEmpty,
            candidateConflicts.isEmpty
        else {
            return nil
        }

        return candidateIsIncomplete
            ? .maySuit
            : .noDetectedConflict
    }


    /// Fully checked first, then most recently updated.
    nonisolated static func ranked(
        _ suggestions: [VersionSuggestion]
    ) -> [VersionSuggestion] {

        suggestions.sorted {
            if $0.fit != $1.fit {
                return $0.fit < $1.fit
            }

            return $0.recipe.updatedAt > $1.recipe.updatedAt
        }
    }
}

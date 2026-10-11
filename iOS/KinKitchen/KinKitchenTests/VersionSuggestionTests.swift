//
//  VersionSuggestionTests.swift
//  KinKitchenTests
//
//  Created by Greg Hudler on 10/11/26.
//

import Foundation
import Testing
@testable import KinKitchen

/// KINKIT-190: dietary-compatible recipe versions.
struct VersionSuggestionTests {

    let peanuts = "allergen:peanuts"
    let vegan = "restriction:vegan"

    @Test func versionWithoutTheConflictIsSuggested() {
        #expect(
            VersionSuggestionService.fit(
                currentConflicts: [peanuts],
                candidateConflicts: [],
                candidateIsIncomplete: false
            ) == .noDetectedConflict
        )
    }

    @Test func versionWithTheSameConflictIsNotSuggested() {
        #expect(
            VersionSuggestionService.fit(
                currentConflicts: [peanuts],
                candidateConflicts: [peanuts],
                candidateIsIncomplete: false
            ) == nil
        )
    }

    @Test func versionTradingOneConflictForAnotherIsNotSuggested() {
        #expect(
            VersionSuggestionService.fit(
                currentConflicts: [peanuts],
                candidateConflicts: [vegan],
                candidateIsIncomplete: false
            ) == nil
        )
    }

    @Test func recipeWithoutAConflictGetsNoSuggestions() {
        #expect(
            VersionSuggestionService.fit(
                currentConflicts: [],
                candidateConflicts: [],
                candidateIsIncomplete: false
            ) == nil
        )
    }

    @Test func uncheckedIngredientsOnlyMayBeSuitable() {
        #expect(
            VersionSuggestionService.fit(
                currentConflicts: [peanuts, vegan],
                candidateConflicts: [],
                candidateIsIncomplete: true
            ) == .maySuit
        )
    }

    @Test func wordingNeverClaimsAllergySafe() {
        for fit in [
            VersionSuggestion.Fit.noDetectedConflict,
            .maySuit
        ] {
            #expect(!fit.label.localizedCaseInsensitiveContains("safe"))
            #expect(!fit.label.localizedCaseInsensitiveContains("guarantee"))
        }

        #expect(
            VersionSuggestion.Fit.noDetectedConflict.label
                == "No detected conflict"
        )
        #expect(
            VersionSuggestion.Fit.maySuit.label
                .hasPrefix("May be suitable")
        )
    }

    @Test func fullyCheckedVersionsComeFirstThenNewest() {
        let older = Self.suggestion(fit: .noDetectedConflict, updated: "2026-01-01T00:00:00Z")
        let newer = Self.suggestion(fit: .noDetectedConflict, updated: "2026-09-01T00:00:00Z")
        let unchecked = Self.suggestion(fit: .maySuit, updated: "2026-10-01T00:00:00Z")

        let ranked =
            VersionSuggestionService.ranked(
                [unchecked, older, newer]
            )

        #expect(ranked.map(\.id) == [newer.id, older.id, unchecked.id])
    }

    @Test func multipleCompatibleVersionsAreKept() {
        let suggestions =
            (0..<3).map { _ in
                Self.suggestion(fit: .noDetectedConflict, updated: "2026-01-01T00:00:00Z")
            }

        #expect(
            VersionSuggestionService.ranked(suggestions).count == 3
        )
    }
}

private extension VersionSuggestionTests {

    static func suggestion(
        fit: VersionSuggestion.Fit,
        updated: String
    ) -> VersionSuggestion {
        VersionSuggestion(
            recipe: Recipe(
                id: UUID(),
                ownerId: UUID(),
                name: "Sunday Gravy",
                originalRecipeId: UUID(),
                createdAt: "2026-01-01T00:00:00Z",
                updatedAt: updated
            ),
            fit: fit
        )
    }
}

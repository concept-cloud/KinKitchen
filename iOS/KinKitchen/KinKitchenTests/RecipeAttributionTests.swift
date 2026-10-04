//
//  RecipeAttributionTests.swift
//  KinKitchenTests
//
//  Created by Greg Hudler on 10/4/26.
//

import Foundation
import Testing
@testable import KinKitchen

/// KINKIT-150: attribution survives sharing, saving and versions.
struct RecipeAttributionTests {

    // MARK: - People

    static let rose = UUID()   // original author
    static let sam = UUID()    // shares it, later makes a version
    static let alex = UUID()   // receives and saves it

    static let names = [
        rose: "Rose",
        sam: "Sam",
        alex: "Alex"
    ]

    func name(_ id: UUID) -> String {
        Self.names[id] ?? "?"
    }

    // MARK: - Recipes

    /// Rose's original, with a legacy contributor.
    static let original = recipe(
        owner: rose,
        contributor: "Grandma Rose"
    )

    /// Sam's version of Rose's recipe.
    static let samsVersion = recipe(
        owner: sam,
        contributor: "Grandma Rose",
        source: original.id,
        original: original.id
    )

    static let originalOwners = [
        original.id: rose
    ]

    // MARK: - Author

    @Test func authorIsTheOwnerOfAnOriginalRecipe() {
        #expect(
            RecipeAttribution.originalAuthorId(
                of: Self.original,
                originalOwners: [:]
            ) == Self.rose
        )
    }

    @Test func authorOfAVersionIsTheOriginalsOwner() {
        #expect(
            RecipeAttribution.originalAuthorId(
                of: Self.samsVersion,
                originalOwners: Self.originalOwners
            ) == Self.rose
        )
    }

    @Test func missingOriginalDoesNotCreditTheVersionOwner() {
        #expect(
            RecipeAttribution.originalAuthorId(
                of: Self.samsVersion,
                originalOwners: [:]
            ) == nil
        )
    }

    // MARK: - Saving

    @Test func savedRecipeStillPointsAtTheOriginal() {
        let share = Self.share(
            of: Self.original,
            from: Self.sam,
            to: Self.alex
        )

        let saved = SavedRecipe(
            userId: Self.alex,
            recipeId: share.recipeId,
            shareId: share.id,
            savedAt: Date()
        )

        #expect(saved.recipeId == Self.original.id)
        #expect(saved.shareId == share.id)
    }

    @Test func savingDoesNotMakeTheSaverTheAuthor() {
        // Alex saving Rose's recipe changes nothing on the recipe.
        let authorId =
            RecipeAttribution.originalAuthorId(
                of: Self.original,
                originalOwners: [:]
            )

        #expect(authorId == Self.rose)
        #expect(authorId != Self.alex)
        #expect(Self.original.ownerId == Self.rose)
    }

    // MARK: - Sender vs Author

    @Test func senderStaysSeparateFromAuthor() {
        let shares = [
            Self.share(
                of: Self.original,
                from: Self.sam,
                to: Self.alex
            )
        ]

        let senders =
            RecipeAttribution.senderIds(
                of: Self.original.id,
                in: shares
            )

        #expect(senders == [Self.sam])
        #expect(
            RecipeAttribution.originalAuthorId(
                of: Self.original,
                originalOwners: [:]
            ) == Self.rose
        )
    }

    @Test func authorCanAlsoBeTheSender() {
        let shares = [
            Self.share(
                of: Self.original,
                from: Self.rose,
                to: Self.alex
            )
        ]

        #expect(
            RecipeAttribution.senderIds(
                of: Self.original.id,
                in: shares
            ) == [Self.rose]
        )
    }

    @Test func multipleSendersNewestFirstWithoutDuplicates() {
        let older = Self.share(
            of: Self.original,
            from: Self.rose,
            to: Self.alex,
            daysAgo: 3
        )
        let newer = Self.share(
            of: Self.original,
            from: Self.sam,
            to: Self.alex,
            daysAgo: 1
        )
        let repeatShare = Self.share(
            of: Self.original,
            from: Self.rose,
            to: Self.alex,
            daysAgo: 2
        )

        let senders =
            RecipeAttribution.senderIds(
                of: Self.original.id,
                in: [older, newer, repeatShare]
            )

        #expect(senders == [Self.sam, Self.rose])
        #expect(
            RecipeAttribution.senderSummary(
                senders.map(name)
            ) == "Sam and Rose"
        )
    }

    // MARK: - Multiple Users

    @Test func attributionSurvivesPassingThroughSeveralUsers() {
        // Rose → Sam makes a version → Sam shares it with Alex.
        let line =
            RecipeAttribution.authorLine(
                for: Self.samsVersion,
                authorId:
                    RecipeAttribution.originalAuthorId(
                        of: Self.samsVersion,
                        originalOwners: Self.originalOwners
                    ),
                name: name
            )

        #expect(
            line == "By Rose · version by Sam · originally from Grandma Rose"
        )
    }

    @Test func legacyContributorIsKept() {
        let line =
            RecipeAttribution.authorLine(
                for: Self.original,
                authorId: Self.rose,
                name: name
            )

        #expect(
            line == "By Rose · originally from Grandma Rose"
        )
    }
}

// MARK: - Builders

private extension RecipeAttributionTests {

    static func recipe(
        owner: UUID,
        contributor: String? = nil,
        source: UUID? = nil,
        original: UUID? = nil
    ) -> Recipe {
        Recipe(
            id: UUID(),
            ownerId: owner,
            name: "Sunday Gravy",
            originalContributor: contributor,
            sourceRecipeId: source,
            originalRecipeId: original,
            createdAt: "2026-10-04T00:00:00Z",
            updatedAt: "2026-10-04T00:00:00Z"
        )
    }

    static func share(
        of recipe: Recipe,
        from sender: UUID,
        to recipient: UUID,
        daysAgo: Int = 0
    ) -> RecipeShare {
        RecipeShare(
            id: UUID(),
            recipeId: recipe.id,
            senderId: sender,
            recipientId: recipient,
            createdAt:
                Date().addingTimeInterval(
                    Double(-daysAgo) * 86_400
                ),
            savedAt: nil
        )
    }
}

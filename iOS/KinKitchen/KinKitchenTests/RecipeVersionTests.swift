//
//  RecipeVersionTests.swift
//  KinKitchenTests
//
//  Created by Greg Hudler on 10/11/26.
//

import Foundation
import Testing
@testable import KinKitchen

/// B6: recipe versions.
struct RecipeVersionTests {

    struct DatabaseError: Error, CustomStringConvertible {
        let description: String
    }

    // MARK: - KINKIT-186 Create Personal Version

    @Test func versionPhotoLivesInTheNewOwnersOwnFolder() {
        let ownerId = UUID()
        let versionId = UUID()

        let path =
            RecipeService.recipePhotoPath(
                ownerId: ownerId,
                recipeId: versionId
            )

        #expect(
            path ==
                "\(ownerId.uuidString.lowercased())/\(versionId.uuidString.lowercased())/recipe.jpg"
        )
    }

    @Test func unavailableSourceExplainsWhy() {
        #expect(
            RecipeService.versionFailureMessage(
                for: DatabaseError(description: "SOURCE_RECIPE_UNAVAILABLE")
            ).contains("no longer available")
        )
    }

    @Test func ownRecipeSuggestsEditing() {
        #expect(
            RecipeService.versionFailureMessage(
                for: DatabaseError(description: "CANNOT_VERSION_OWN_RECIPE")
            ).contains("Edit it instead")
        )
    }

    @Test func unknownFailureSaysNothingChanged() {
        #expect(
            RecipeService.versionFailureMessage(
                for: DatabaseError(description: "boom")
            ).contains("Nothing was changed")
        )
    }

    // MARK: - KINKIT-187 Relationship & Attribution

    @Test func savedOriginalAuthorIsCreditedWhenOriginalIsUnavailable() {
        let rose = UUID()
        let sam = UUID()

        // Original deleted: links cleared, saved credit remains.
        let version =
            Self.version(
                owner: sam,
                original: nil,
                originalOwner: rose,
                originalName: "Sunday Gravy"
            )

        #expect(
            RecipeAttribution.originalAuthorId(
                of: version,
                originalOwners: [:]
            ) == rose
        )
        #expect(version.isVersion)
    }

    @Test func savedCreditWinsOverAWrongLoadedOwner() {
        let rose = UUID()
        let originalId = UUID()

        let version =
            Self.version(
                owner: UUID(),
                original: originalId,
                originalOwner: rose,
                originalName: "Sunday Gravy"
            )

        #expect(
            RecipeAttribution.originalAuthorId(
                of: version,
                originalOwners: [originalId: UUID()]
            ) == rose
        )
    }

    @Test func renamingAVersionKeepsTheOriginalTitle() {
        var version =
            Self.version(
                owner: UUID(),
                original: UUID(),
                originalOwner: UUID(),
                originalName: "Sunday Gravy"
            )

        version.name = "Sam's Spicy Gravy"

        #expect(version.originalTitle == "Sunday Gravy")
        #expect(version.isVersion)
    }

    @Test func versionCreditLineNamesBothCooks() {
        let rose = UUID()
        let sam = UUID()

        let version =
            Self.version(
                owner: sam,
                original: UUID(),
                originalOwner: rose,
                originalName: "Sunday Gravy"
            )

        let line =
            RecipeAttribution.authorLine(
                for: version,
                authorId:
                    RecipeAttribution.originalAuthorId(
                        of: version,
                        originalOwners: [:]
                    ),
                name: { $0 == rose ? "Rose" : "Sam" }
            )

        #expect(line == "By Rose · version by Sam")
    }

    @Test func normalRecipeIsNotAVersion() {
        let recipe =
            Recipe(
                id: UUID(),
                ownerId: UUID(),
                name: "Sunday Gravy",
                createdAt: "2026-10-11T00:00:00Z",
                updatedAt: "2026-10-11T00:00:00Z"
            )

        #expect(!recipe.isVersion)
        #expect(recipe.originalTitle == nil)
    }

    @Test func savedLineageDecodes() throws {
        let rose = UUID()

        let json = """
        {
            "id": "\(UUID().uuidString)",
            "owner_id": "\(UUID().uuidString)",
            "name": "Sam's Gravy",
            "source_recipe_name": "Sunday Gravy",
            "source_owner_id": "\(rose.uuidString)",
            "original_recipe_name": "Sunday Gravy",
            "original_owner_id": "\(rose.uuidString)",
            "created_at": "2026-10-11T00:00:00Z",
            "updated_at": "2026-10-11T00:00:00Z"
        }
        """

        let version =
            try JSONDecoder().decode(
                Recipe.self,
                from: Data(json.utf8)
            )

        #expect(version.originalOwnerId == rose)
        #expect(version.sourceOwnerId == rose)
        #expect(version.originalTitle == "Sunday Gravy")
    }

    // MARK: - KINKIT-188 Edit Independently

    @Test func olderVersionUsingTheOriginalsPhotoIsDetected() {
        let rose = UUID()
        let originalId = UUID()

        var version =
            Self.version(
                owner: UUID(),
                original: originalId,
                originalOwner: rose,
                originalName: "Sunday Gravy"
            )

        version.photoPath =
            RecipeService.recipePhotoPath(
                ownerId: rose,
                recipeId: originalId
            )

        #expect(RecipeService.sharesAnotherRecipesPhoto(version))
    }

    @Test func versionWithItsOwnPhotoIsLeftAlone() {
        var version =
            Self.version(
                owner: UUID(),
                original: UUID(),
                originalOwner: UUID(),
                originalName: "Sunday Gravy"
            )

        version.photoPath =
            RecipeService.recipePhotoPath(
                ownerId: version.ownerId,
                recipeId: version.id
            )

        #expect(!RecipeService.sharesAnotherRecipesPhoto(version))
    }

    @Test func recipeWithoutAPhotoHasNothingToCopy() {
        let version =
            Self.version(
                owner: UUID(),
                original: UUID(),
                originalOwner: UUID(),
                originalName: "Sunday Gravy"
            )

        #expect(!RecipeService.sharesAnotherRecipesPhoto(version))
    }

    // MARK: - KINKIT-189 Display Relationship

    @Test func versionShowsOriginalTitleAndAuthor() {
        let rose = UUID()

        var version =
            Self.version(
                owner: UUID(),
                original: UUID(),
                originalOwner: rose,
                originalName: "Sunday Gravy"
            )
        version.name = "Sam's Spicy Gravy"

        #expect(
            RecipeAttribution.versionOrigin(
                for: version,
                name: { _ in "Rose" }
            ) == "Adapted from \u{201C}Sunday Gravy\u{201D} by Rose"
        )
    }

    @Test func versionStillExplainsItsOriginAfterOriginalIsDeleted() {
        // Links cleared by the delete; saved lineage remains.
        let version =
            Self.version(
                owner: UUID(),
                original: nil,
                originalOwner: UUID(),
                originalName: "Sunday Gravy"
            )

        #expect(
            RecipeAttribution.versionOrigin(
                for: version,
                name: { _ in "Rose" }
            )?.contains("Sunday Gravy") == true
        )
    }

    @Test func normalRecipeShowsNoVersionInformation() {
        let recipe =
            Recipe(
                id: UUID(),
                ownerId: UUID(),
                name: "Sunday Gravy",
                createdAt: "2026-10-11T00:00:00Z",
                updatedAt: "2026-10-11T00:00:00Z"
            )

        #expect(
            RecipeAttribution.versionOrigin(
                for: recipe,
                name: { _ in "Rose" }
            ) == nil
        )
        #expect(
            RecipeAttribution.versionSource(
                for: recipe,
                name: { _ in "Rose" }
            ) == nil
        )
    }

    @Test func olderVersionWithoutSavedLineageStillReadsAsAVersion() {
        let recipe =
            Recipe(
                id: UUID(),
                ownerId: UUID(),
                name: "Sunday Gravy",
                sourceRecipeId: UUID(),
                originalRecipeId: UUID(),
                createdAt: "2026-10-11T00:00:00Z",
                updatedAt: "2026-10-11T00:00:00Z"
            )

        #expect(
            RecipeAttribution.versionOrigin(
                for: recipe,
                name: { _ in "Rose" }
            ) == "Adapted from another recipe"
        )
    }

    @Test func versionOfAVersionNamesTheCookItWasCopiedFrom() {
        let rose = UUID()
        let sam = UUID()

        var version =
            Self.version(
                owner: UUID(),
                original: UUID(),
                originalOwner: rose,
                originalName: "Sunday Gravy"
            )
        version.sourceOwnerId = sam
        version.sourceRecipeName = "Sam's Gravy"

        #expect(
            RecipeAttribution.versionSource(
                for: version,
                name: { $0 == sam ? "Sam" : "Rose" }
            ) == "Made from the version by Sam, \u{201C}Sam's Gravy\u{201D}"
        )
    }

    @Test func versionCopiedStraightFromTheOriginalHasNoSourceLine() {
        let version =
            Self.version(
                owner: UUID(),
                original: UUID(),
                originalOwner: UUID(),
                originalName: "Sunday Gravy"
            )

        #expect(
            RecipeAttribution.versionSource(
                for: version,
                name: { _ in "Rose" }
            ) == nil
        )
    }

    @Test func versionLineageDecodes() throws {
        let sourceId = UUID()
        let originalId = UUID()

        let json = """
        {
            "id": "\(UUID().uuidString)",
            "owner_id": "\(UUID().uuidString)",
            "name": "Sunday Gravy",
            "source_recipe_id": "\(sourceId.uuidString)",
            "original_recipe_id": "\(originalId.uuidString)",
            "created_at": "2026-10-11T00:00:00Z",
            "updated_at": "2026-10-11T00:00:00Z"
        }
        """

        let version =
            try JSONDecoder().decode(
                Recipe.self,
                from: Data(json.utf8)
            )

        #expect(version.sourceRecipeId == sourceId)
        #expect(version.originalRecipeId == originalId)
    }
}

private extension RecipeVersionTests {

    static func version(
        owner: UUID,
        original: UUID?,
        originalOwner: UUID,
        originalName: String
    ) -> Recipe {
        Recipe(
            id: UUID(),
            ownerId: owner,
            name: originalName,
            sourceRecipeId: original,
            originalRecipeId: original,
            sourceRecipeName: originalName,
            sourceOwnerId: originalOwner,
            originalRecipeName: originalName,
            originalOwnerId: originalOwner,
            createdAt: "2026-10-11T00:00:00Z",
            updatedAt: "2026-10-11T00:00:00Z"
        )
    }
}

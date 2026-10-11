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

//
//  ContentDeletionTests.swift
//  KinKitchenTests
//
//  Created by Greg Hudler on 10/11/26.
//

import Foundation
import Testing
@testable import KinKitchen

/// B5: content deletion and management.
struct ContentDeletionTests {

    // MARK: - KINKIT-181 Delete Recipes

    @Test func deletedRecipeNeedsNoExplanation() {
        #expect(RecipeDeletionOutcome.deleted.message == nil)
    }

    @Test func archivedRecipesExplainWhyTheyWereKept() throws {
        let pastGathering =
            try #require(
                RecipeDeletionOutcome
                    .archived(reason: .pastGathering)
                    .message
            )
        let versions =
            try #require(
                RecipeDeletionOutcome
                    .archived(reason: .versions)
                    .message
            )

        #expect(pastGathering.contains("past gathering"))
        #expect(versions.contains("versions"))
    }

    // MARK: - KINKIT-183 Gatherings

    struct DatabaseError: Error, CustomStringConvertible {
        let description: String
    }

    @Test func occurredGatheringExplainsItsKeptInHistory() {
        let message =
            GatheringService.friendlyMessage(
                for: DatabaseError(description: "GATHERING_ALREADY_OCCURRED"),
                fallback: "fallback"
            )

        #expect(message.contains("Gathering History"))
    }

    @Test func nonHostIsToldOnlyTheHostCan() {
        #expect(
            GatheringService.friendlyMessage(
                for: DatabaseError(description: "NOT_GATHERING_HOST"),
                fallback: "fallback"
            ) == "Only the host can do this."
        )
    }

    @Test func unknownFailureUsesFallback() {
        #expect(
            GatheringService.friendlyMessage(
                for: DatabaseError(description: "network down"),
                fallback: "Try again."
            ) == "Try again."
        )
    }

    // MARK: - KINKIT-184 Standard failure handling

    @Test func ownershipFailuresNameWhoCanDelete() {
        #expect(
            KinDeletion.failureMessage(
                for: DatabaseError(description: "NOT_RECIPE_OWNER"),
                deleting: .recipe
            ) == "Only the person who created this recipe can delete it."
        )
        #expect(
            KinDeletion.failureMessage(
                for: DatabaseError(description: "NOT_COOKBOOK_OWNER"),
                deleting: .cookbook
            ) == "Only the owner can delete this cookbook."
        )
        #expect(
            KinDeletion.failureMessage(
                for: DatabaseError(description: "NOT_GATHERING_HOST"),
                deleting: .gathering
            ) == "Only the host can do this."
        )
    }

    @Test func occurredGatheringFailureExplainsHistory() {
        #expect(
            KinDeletion.failureMessage(
                for: DatabaseError(description: "GATHERING_ALREADY_OCCURRED"),
                deleting: .gathering
            ).contains("Gathering History")
        )
    }

    @Test func offlineFailureSaysNothingWasDeleted() {
        let message =
            KinDeletion.failureMessage(
                for: URLError(.notConnectedToInternet),
                deleting: .cookbook
            )

        #expect(message.contains("offline"))
        #expect(message.contains("cookbook was not deleted"))
    }

    @Test func unknownFailureNamesTheContentAndSaysNothingChanged() {
        for content in [
            KinDeletion.Content.recipe,
            .cookbook,
            .gathering
        ] {
            let message =
                KinDeletion.failureMessage(
                    for: DatabaseError(description: "boom"),
                    deleting: content
                )

            #expect(message.contains(content.noun))
            #expect(message.contains("Nothing was changed"))
        }
    }

    @Test func archivedFieldDecodesAndDefaultsToActive() throws {
        let base = """
        "id": "\(UUID().uuidString)",
        "owner_id": "\(UUID().uuidString)",
        "name": "Sunday Gravy",
        "created_at": "2026-10-11T00:00:00Z",
        "updated_at": "2026-10-11T00:00:00Z"
        """

        let active =
            try JSONDecoder().decode(
                Recipe.self,
                from: Data("{\(base)}".utf8)
            )
        let archived =
            try JSONDecoder().decode(
                Recipe.self,
                from: Data(
                    "{\(base), \"archived_at\": \"2026-10-11T12:00:00Z\"}".utf8
                )
            )

        #expect(active.archivedAt == nil)
        #expect(archived.archivedAt != nil)
    }
}

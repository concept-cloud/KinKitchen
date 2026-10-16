//
//  EventDietaryNeedsTests.swift
//  KinKitchenTests
//
//  Created by Greg Hudler on 10/15/26.
//

import Foundation
import Testing
@testable import KinKitchen

/// Regression: dietary needs on an event
/// (supabase/REGRESSION-event-dietary-needs).
struct EventDietaryNeedsTests {

    static let peanutId = UUID()
    static let veganId = UUID()

    static let peanuts = EventDietaryNeed(kind: .allergen, catalogId: peanutId, name: "Peanuts")
    static let vegan = EventDietaryNeed(kind: .restriction, catalogId: veganId, name: "Vegan")
    static let strawberry = EventDietaryNeed(kind: .allergen, catalogId: nil, name: "Strawberry")
    static let cilantro = EventDietaryNeed(kind: .preference, catalogId: nil, name: "Cilantro")

    @Test func builtInItemsKeepTheirCatalogIdForTheChecks() {
        let info = [Self.peanuts, Self.vegan, Self.strawberry, Self.cilantro]
            .dietaryInformation(eventId: UUID())

        #expect(info.allergens.map(\.name) == ["Peanuts", "Strawberry"])
        #expect(info.allergens.first?.id == Self.peanutId)
        #expect(info.allergens.first?.isCustom == false)
        #expect(info.allergens.last?.isCustom == true)
        #expect(info.restrictions.map(\.name) == ["Vegan"])
        #expect(info.preferences.map(\.name) == ["Cilantro"])
        #expect(info.preferences.first?.isCustom == true)
    }

    @Test func typedInItemsGetTheSameIdEveryTime() {
        let first = [Self.strawberry].dietaryInformation(eventId: UUID())
        let second = [Self.strawberry].dietaryInformation(eventId: UUID())
        #expect(first.allergens.first?.id == second.allergens.first?.id)
    }

    @Test func showsAllergensFirstThenRestrictionsThenPreferences() {
        let sorted = [Self.cilantro, Self.vegan, Self.strawberry, Self.peanuts].sortedForDisplay
        #expect(sorted.map(\.name) == ["Peanuts", "Strawberry", "Vegan", "Cilantro"])
    }

    @Test func typingABuiltInNameChoosesTheBuiltInItem() {
        let draft = EventDietaryDraft.adding(
            "  peanuts ", kind: .allergen, to: [], builtIn: [Self.peanuts]
        )
        #expect(draft == [Self.peanuts])
    }

    @Test func typingANewNameAddsItTidied() {
        let draft = EventDietaryDraft.adding(
            "  kiwi   fruit ", kind: .allergen, to: [Self.peanuts], builtIn: [Self.peanuts]
        )
        #expect(draft.count == 2)
        #expect(draft.last?.name == "Kiwi fruit")
        #expect(draft.last?.isCustom == true)
    }

    @Test func typingSomethingAlreadyChosenOrBlankChangesNothing() {
        let draft = [Self.strawberry]
        #expect(EventDietaryDraft.adding("STRAWBERRY", kind: .allergen, to: draft, builtIn: []) == draft)
        #expect(EventDietaryDraft.adding("   ", kind: .allergen, to: draft, builtIn: []) == draft)
    }

    @Test func savesAsTheDatabaseRowShape() throws {
        let data = try JSONEncoder().encode([Self.strawberry])
        let json = try #require(
            JSONSerialization.jsonObject(with: data) as? [[String: Any]]
        )
        #expect(json.first?["kind"] as? String == "allergen")
        #expect(json.first?["name"] as? String == "Strawberry")
        #expect(json.first?["catalog_id"] == nil)

        let decoded = try JSONDecoder().decode(
            [EventDietaryNeed].self,
            from: Data(#"[{"kind":"restriction","catalog_id":"\#(Self.veganId)","name":"Vegan"}]"#.utf8)
        )
        #expect(decoded == [Self.vegan])
    }

    @Test func mealTrainsExplainItsForSomeoneNotOnTheApp() {
        #expect(EventDietaryText.hint(for: .mealTrain).contains("isn't on Kin Kitchen"))
        #expect(!EventDietaryText.hint(for: .potluck).contains("isn't on Kin Kitchen"))
    }

    @Test func updateNotificationHighlightsDietaryNeeds() {
        let notification = KinNotification(
            id: UUID(), userId: UUID(), type: .gatheringUpdated,
            title: "Gathering Updated",
            message: "Meals for the Smiths: dietary needs updated.",
            relatedType: "gathering", relatedId: UUID(),
            isRead: false, createdAt: .now
        )
        #expect(notification.changedGatheringFields == [.dietaryNeeds])
    }
}

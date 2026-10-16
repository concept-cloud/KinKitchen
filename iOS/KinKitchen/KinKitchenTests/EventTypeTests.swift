//
//  EventTypeTests.swift
//  KinKitchenTests
//
//  Created by Greg Hudler on 10/15/26.
//

import Foundation
import Testing
@testable import KinKitchen

/// Regression: event types (supabase/REGRESSION-event-types).
struct EventTypeTests {

    @Test func valuesMatchTheDatabaseEnum() {
        #expect(KinEventType.allCases.map(\.rawValue) == [
            "backyard_bbq", "potluck", "buffet", "dinner_party",
            "meal_train", "holiday", "brunch", "celebration", "other"
        ])
    }

    @Test func everyTypeHasATitleSubtitleAndIcon() {
        for type in KinEventType.allCases {
            #expect(!type.title.isEmpty)
            #expect(!type.subtitle.isEmpty)
            #expect(!type.symbol.isEmpty)
        }
    }

    @Test func decodesKnownTypesAndTreatsUnknownAsOther() throws {
        let data = Data(#"["meal_train", "buffet", "picnic"]"#.utf8)
        let types = try JSONDecoder().decode([KinEventType].self, from: data)
        #expect(types == [.mealTrain, .buffet, .other])
    }

    @Test func encodesTheDatabaseValue() throws {
        let data = try JSONEncoder().encode([KinEventType.backyardBBQ])
        #expect(String(decoding: data, as: UTF8.self) == #"["backyard_bbq"]"#)
    }

    @Test func eventsWithoutATypeStillDecode() throws {
        let json = #"""
        {"id":"\#(UUID())","host_id":"\#(UUID())","name":"Supper",
         "starts_at":0,"status":"upcoming","created_at":0,"updated_at":0}
        """#
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        let event = try decoder.decode(Gathering.self, from: Data(json.utf8))
        #expect(event.eventType == nil)

        let typed = json.replacingOccurrences(
            of: #""name":"Supper","#,
            with: #""name":"Supper","event_type":"backyard_bbq","#
        )
        let typedEvent = try decoder.decode(Gathering.self, from: Data(typed.utf8))
        #expect(typedEvent.eventType == .backyardBBQ)
    }

    @Test func updateNotificationHighlightsTheType() {
        let notification = KinNotification(
            id: UUID(), userId: UUID(), type: .gatheringUpdated,
            title: "Gathering Updated",
            message: "Supper: event type changed to Meal Train, theme changed to Fall.",
            relatedType: "gathering", relatedId: UUID(),
            isRead: false, createdAt: .now
        )
        #expect(notification.changedGatheringFields == [.eventType, .theme])
    }
}

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


/// Regression: Add Event quick dates, times and theme ideas.
struct EventFormChoiceTests {

    static var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/Chicago")!
        return calendar
    }

    static func day(_ day: Int, hour: Int = 9) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: 10, day: day, hour: hour))!
    }

    @Test func midweekOffersTodayTomorrowAndTheWeekend() {
        // Wednesday, October 14.
        let choices = EventDateChoices.quickDates(now: Self.day(14), calendar: Self.calendar)
        #expect(choices.count == 4)
        #expect(choices.map(\.title).prefix(2) == ["Today", "Tomorrow"])
        #expect(Self.calendar.component(.day, from: choices[2].date) == 17)
        #expect(Self.calendar.component(.day, from: choices[3].date) == 18)
    }

    @Test func fridayDoesNotRepeatSaturdayAsTomorrow() {
        // Friday, October 16: tomorrow is already Saturday.
        let choices = EventDateChoices.quickDates(now: Self.day(16), calendar: Self.calendar)
        let days = choices.map { Self.calendar.component(.day, from: $0.date) }
        #expect(days == [16, 17, 18])
    }

    @Test func defaultsToSixTonightOrTomorrowWhenTooLate() {
        let morning = EventDateChoices.defaultStart(now: Self.day(14, hour: 9), calendar: Self.calendar)
        #expect(Self.calendar.component(.day, from: morning) == 14)
        #expect(Self.calendar.component(.hour, from: morning) == 18)

        let evening = EventDateChoices.defaultStart(now: Self.day(14, hour: 17), calendar: Self.calendar)
        #expect(Self.calendar.component(.day, from: evening) == 15)
        #expect(Self.calendar.component(.hour, from: evening) == 18)
    }

    @Test func everyTypeHasThemeIdeas() {
        for type in KinEventType.allCases {
            #expect(type.themeSuggestions.count == 4)
        }
        #expect(KinEventType.mealTrain.themeSuggestions.contains("New Baby"))
    }
}

extension EventFormChoiceTests {

    @Test func saturdayOffersTodayTomorrowOnly() {
        // Saturday, October 17: today and tomorrow are the weekend.
        let choices = EventDateChoices.quickDates(now: Self.day(17), calendar: Self.calendar)
        #expect(choices.map(\.title) == ["Today", "Tomorrow"])
    }
}

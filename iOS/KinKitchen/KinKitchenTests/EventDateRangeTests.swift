//
//  EventDateRangeTests.swift
//  KinKitchenTests
//
//  Created by Greg Hudler on 10/15/26.
//

import Foundation
import Testing
@testable import KinKitchen

/// Regression: Meal Train date ranges
/// (supabase/REGRESSION-meal-train-dates).
struct EventDateRangeTests {

    static var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/Chicago")!
        calendar.locale = Locale(identifier: "en_US")
        return calendar
    }

    static func date(_ month: Int, _ day: Int, year: Int = 2026, hour: Int = 17) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour))!
    }

    @Test func countsBothTheFirstAndLastDay() {
        #expect(EventDateRange.dayCount(from: Self.date(10, 20), to: Self.date(10, 26), calendar: Self.calendar) == 7)
        #expect(EventDateRange.dayCount(from: Self.date(10, 20), to: Self.date(10, 20), calendar: Self.calendar) == 1)
    }

    @Test func lastDayKeepsTheDropOffTime() {
        let last = EventDateRange.lastDay(from: Self.date(10, 20), days: 14, calendar: Self.calendar)
        #expect(last == Self.date(11, 2))
    }

    @Test func lengthsReadAsWeeksWhenTheyCan() {
        #expect(EventDateRange.lengthText(7) == "1 week")
        #expect(EventDateRange.lengthText(14) == "2 weeks")
        #expect(EventDateRange.lengthText(30) == "30 days")
        #expect(EventDateRange.lengthText(1) == "1 day")
    }

    @Test func rangesSkipRepeatedMonthsAndYears() {
        #expect(EventDateRange.rangeText(from: Self.date(10, 20), to: Self.date(10, 26), calendar: Self.calendar) == "Oct 20 – 26")
        #expect(EventDateRange.rangeText(from: Self.date(10, 20), to: Self.date(11, 2), calendar: Self.calendar) == "Oct 20 – Nov 2")
        #expect(
            EventDateRange.rangeText(from: Self.date(12, 28), to: Self.date(1, 3, year: 2027), calendar: Self.calendar)
                == "Dec 28, 2026 – Jan 3, 2027"
        )
    }

    /// iOS puts a narrow no-break space before AM/PM.
    static func plain(_ text: String) -> String {
        text.replacingOccurrences(of: "\u{202F}", with: " ")
    }

    @Test func summaryCountsDaysWhileRunning() {
        let running = EventDateRange.summary(
            from: Self.date(10, 20), to: Self.date(11, 2),
            now: Self.date(10, 22, hour: 9), calendar: Self.calendar
        )
        #expect(Self.plain(running) == "Day 3 of 14 · 5:00 PM drop-off")

        let upcoming = EventDateRange.summary(
            from: Self.date(10, 20), to: Self.date(11, 2),
            now: Self.date(10, 15), calendar: Self.calendar
        )
        #expect(Self.plain(upcoming) == "Oct 20 – Nov 2 · 5:00 PM drop-off")
    }

    static func mealTrain(endsAt: Date?) -> Gathering {
        Gathering(
            id: UUID(), hostId: UUID(), name: "Meals for the Smiths",
            theme: nil, eventType: .mealTrain, coverImagePath: nil,
            description: nil, location: nil,
            startsAt: date(10, 20), endsAt: endsAt,
            guestLimit: nil, status: .upcoming,
            createdAt: date(10, 1), updatedAt: date(10, 1)
        )
    }

    @Test func runningMealTrainStaysActiveUntilItsLastDay() {
        let train = Self.mealTrain(endsAt: Self.date(11, 2))
        let midway = Self.date(10, 28)

        #expect(train.isActive(asOf: midway))
        #expect(!train.isHistorical(asOf: midway))
        #expect(!train.canBeCancelled(asOf: midway))
        #expect(train.isHistorical(asOf: Self.date(11, 3, hour: 12)))
    }

    @Test func oneDayEventsStillEndTheSameDay() {
        let dinner = Self.mealTrain(endsAt: nil)
        #expect(dinner.activeThrough == dinner.startsAt)
        #expect(dinner.isHistorical(asOf: Self.date(10, 22)))
    }
}

//
//  HomeTests.swift
//  KinKitchenTests
//
//  Created by Greg Hudler on 10/13/26.
//

import Foundation
import Testing
@testable import KinKitchen

/// C1: Home screen redesign.
struct HomeTests {

    // MARK: - C1.4 Event dates

    static let calendar = Calendar.current

    /// Wednesday, Oct 14 2026, 9:00 AM local time.
    static let now =
        calendar.date(
            from: DateComponents(
                year: 2026,
                month: 10,
                day: 14,
                hour: 9
            )
        )!

    static func date(
        daysFromNow days: Int,
        hour: Int = 18
    ) -> Date {

        let day =
            calendar.date(
                byAdding: .day,
                value: days,
                to: now
            )!

        return calendar.date(
            bySettingHour: hour,
            minute: 0,
            second: 0,
            of: day
        )!
    }

    static func text(_ date: Date) -> String {

        HomeView.eventDateText(
            date,
            now: now,
            calendar: calendar
        )
    }

    @Test func todayAndTomorrowAreNamed() {
        #expect(Self.text(Self.date(daysFromNow: 0)).hasPrefix("Today · "))
        #expect(Self.text(Self.date(daysFromNow: 1)).hasPrefix("Tomorrow · "))
    }

    @Test func thisWeekShowsTheWeekday() {
        // Oct 18, 2026 is a Sunday.
        #expect(Self.text(Self.date(daysFromNow: 4)).hasPrefix("Sunday · "))
    }

    @Test func laterEventsShowTheDate() {
        // A week or more out must include the date, not just "Wednesday".
        let text = Self.text(Self.date(daysFromNow: 7))

        #expect(text.contains("Oct"))
        #expect(text.contains("21"))
    }

    @Test func includesTheTime() {
        #expect(Self.text(Self.date(daysFromNow: 0, hour: 18)).contains("6:00"))
    }
}

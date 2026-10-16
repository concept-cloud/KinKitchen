//
//  EventDateRange.swift
//  KinKitchen
//
//  Created by Greg Hudler on 10/15/26.
//

import Foundation

/// Words for events that run over several days, like a Meal Train
/// from Oct 20 to Nov 2 with a 5 PM drop-off each day.
nonisolated enum EventDateRange {

    /// Lengths offered as chips on Add Event, in days.
    static let quickLengths = [7, 14, 21, 30]

    /// Days from the first to the last, counting both: Oct 20 to
    /// Oct 26 is 7.
    static func dayCount(
        from start: Date,
        to end: Date,
        calendar: Calendar = .current
    ) -> Int {
        let days = calendar.dateComponents(
            [.day],
            from: calendar.startOfDay(for: start),
            to: calendar.startOfDay(for: end)
        ).day ?? 0
        return max(days, 0) + 1
    }

    /// The last day of a range that starts on `start` and runs
    /// `days` days, at the same time of day.
    static func lastDay(
        from start: Date,
        days: Int,
        calendar: Calendar = .current
    ) -> Date {
        calendar.date(byAdding: .day, value: max(days, 1) - 1, to: start) ?? start
    }

    /// "1 week", "2 weeks", "30 days", "10 days".
    static func lengthText(_ days: Int) -> String {
        if days == 1 {
            return "1 day"
        }
        if days % 7 == 0 {
            let weeks = days / 7
            return weeks == 1 ? "1 week" : "\(weeks) weeks"
        }
        return "\(days) days"
    }

    /// "Oct 20 – 26", "Oct 20 – Nov 2", or with years when they differ:
    /// "Dec 28, 2026 – Jan 3, 2027".
    static func rangeText(
        from start: Date,
        to end: Date,
        calendar: Calendar = .current
    ) -> String {

        var monthDay = Date.FormatStyle.dateTime.month(.abbreviated).day()
        monthDay.calendar = calendar
        monthDay.timeZone = calendar.timeZone

        var dayOnly = Date.FormatStyle.dateTime.day()
        dayOnly.calendar = calendar
        dayOnly.timeZone = calendar.timeZone

        let startYear = calendar.component(.year, from: start)
        let endYear = calendar.component(.year, from: end)

        if startYear != endYear {
            let withYear = monthDay.year()
            return "\(start.formatted(withYear)) – \(end.formatted(withYear))"
        }

        if calendar.isDate(start, equalTo: end, toGranularity: .month) {
            return "\(start.formatted(monthDay)) – \(end.formatted(dayOnly))"
        }

        return "\(start.formatted(monthDay)) – \(end.formatted(monthDay))"
    }

    /// For cards and search. While it's running: "Day 3 of 14 ·
    /// 5:00 PM drop-off"; otherwise "Oct 20 – Nov 2 · 5:00 PM drop-off".
    static func summary(
        from start: Date,
        to end: Date,
        now: Date = .now,
        calendar: Calendar = .current
    ) -> String {

        var time = Date.FormatStyle(date: .omitted, time: .shortened)
        time.calendar = calendar
        time.timeZone = calendar.timeZone

        let dropOff = "\(start.formatted(time)) drop-off"
        let total = dayCount(from: start, to: end, calendar: calendar)
        let today = calendar.startOfDay(for: now)

        if today >= calendar.startOfDay(for: start),
           today <= calendar.startOfDay(for: end) {
            let day = dayCount(from: start, to: now, calendar: calendar)
            return "Day \(day) of \(total) · \(dropOff)"
        }

        return "\(rangeText(from: start, to: end, calendar: calendar)) · \(dropOff)"
    }
}

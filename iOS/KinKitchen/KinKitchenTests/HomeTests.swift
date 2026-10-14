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

    // MARK: - C1.5 Recent recipes

    static func recipe(
        _ name: String,
        id: UUID = UUID(),
        archived: Bool = false
    ) throws -> Recipe {

        let archivedField =
            archived
                ? ", \"archived_at\": \"2026-10-11T12:00:00Z\""
                : ""

        let json = """
        {
        "id": "\(id.uuidString)",
        "owner_id": "\(UUID().uuidString)",
        "name": "\(name)",
        "created_at": "2026-10-11T00:00:00Z",
        "updated_at": "2026-10-11T00:00:00Z"\(archivedField)
        }
        """

        return try JSONDecoder().decode(
            Recipe.self,
            from: Data(json.utf8)
        )
    }

    @Test func viewingMovesARecipeToTheFrontWithoutDuplicates() {
        let a = UUID(), b = UUID(), c = UUID()

        #expect(
            RecentRecipesStore.recording(b, in: [a, b, c]) == [b, a, c]
        )
    }

    @Test func recentListIsCapped() {
        let ids = (0..<RecentRecipesStore.maxCount).map { _ in UUID() }
        let updated = RecentRecipesStore.recording(UUID(), in: ids)

        #expect(updated.count == RecentRecipesStore.maxCount)
        #expect(!updated.contains(ids.last!))
    }

    @Test func recentlyViewedComeFirstThenOwnRecipes() throws {
        let viewed = try Self.recipe("Shared Gravy")
        let ownOld = try Self.recipe("Meatballs")
        let ownViewed = try Self.recipe("Lasagna")

        let result =
            RecentRecipesStore.merged(
                viewedIds: [ownViewed.id, viewed.id],
                viewed: [viewed, ownViewed],
                own: [ownOld, ownViewed],
                limit: 10
            )

        #expect(result.map(\.name) == ["Lasagna", "Shared Gravy", "Meatballs"])
    }

    @Test func recipesNoLongerAccessibleAreSkipped() throws {
        // A viewed ID that Supabase didn't return (deleted or unshared)
        // and one the owner archived must not appear.
        let gone = UUID()
        let archived = try Self.recipe("Old Stew", archived: true)
        let own = try Self.recipe("Tacos")

        let result =
            RecentRecipesStore.merged(
                viewedIds: [gone, archived.id],
                viewed: [archived],
                own: [own],
                limit: 10
            )

        #expect(result.map(\.name) == ["Tacos"])
    }

    @Test func mergedRespectsTheLimit() throws {
        let own = try (0..<15).map { try Self.recipe("Recipe \($0)") }

        #expect(
            RecentRecipesStore.merged(
                viewedIds: [],
                viewed: [],
                own: own,
                limit: 10
            ).count == 10
        )
    }

    @Test func recipeDetailsCombineTimeAndCategory() {
        #expect(
            HomeView.recipeDetails(minutes: 30, formattedTime: "30 min", category: "Dinner")
                == "30 min · Dinner"
        )
        #expect(
            HomeView.recipeDetails(minutes: 0, formattedTime: "0 min", category: "Dessert")
                == "Dessert"
        )
        #expect(
            HomeView.recipeDetails(minutes: 0, formattedTime: "0 min", category: "  ")
                == nil
        )
    }
}

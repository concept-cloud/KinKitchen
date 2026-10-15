//
//  HomeTests.swift
//  KinKitchenTests
//
//  Created by Greg Hudler on 10/13/26.
//

import Foundation
import Testing
import SwiftUI
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

    // MARK: - Home search

    struct Item: Identifiable {
        let id = UUID()
        let name: String
        var detail: String? = nil
    }

    static func search(_ items: [Item], _ query: String) -> [String] {
        HomeSearch.filter(items, query: query) { [$0.name, $0.detail] }
            .map(\.name)
    }

    @Test func searchIgnoresCaseAndAccents() {
        let items = [Item(name: "Crème Brûlée"), Item(name: "Tacos")]

        #expect(Self.search(items, "creme brulee") == ["Crème Brûlée"])
        #expect(Self.search(items, "TACO") == ["Tacos"])
    }

    @Test func everyWordMustMatchSomewhere() {
        let items = [
            Item(name: "Sunday Gravy", detail: "Dinner"),
            Item(name: "Sunday Pancakes", detail: "Breakfast")
        ]

        #expect(Self.search(items, "sunday dinner") == ["Sunday Gravy"])
    }

    @Test func blankSearchShowsNothing() {
        #expect(Self.search([Item(name: "Tacos")], "   ").isEmpty)
    }

    @Test func duplicatesAreRemoved() {
        let item = Item(name: "Tacos")

        #expect(HomeSearch.uniqueById([item, item]).count == 1)
    }

    // MARK: - C3.2 Seasonal themes

    static func day(month: Int, day: Int = 15) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: month, day: day))!
    }

    @Test func goldenKitchenIsTheDefaultAllYear() {
        for month in 1...12 {
            #expect(
                KinHomeTheme.current(
                    choice: .goldenKitchen,
                    on: Self.day(month: month),
                    calendar: Self.calendar
                ) == .goldenKitchen
            )
        }
    }

    @Test func seasonalFollowsTheDate() {
        func theme(_ month: Int) -> KinHomeTheme {
            KinHomeTheme.current(
                choice: .seasonal,
                on: Self.day(month: month),
                calendar: Self.calendar
            )
        }

        #expect(theme(4) == .spring)
        #expect(theme(7) == .summer)
        #expect(theme(10) == .autumn)
        #expect(theme(1) == .winter)
    }

    @Test func seasonsChangeOnTheFirstOfTheMonth() {
        #expect(KinHomeTheme.season(of: Self.day(month: 2, day: 28), calendar: Self.calendar) == .winter)
        #expect(KinHomeTheme.season(of: Self.day(month: 3, day: 1), calendar: Self.calendar) == .spring)
        #expect(KinHomeTheme.season(of: Self.day(month: 11, day: 30), calendar: Self.calendar) == .autumn)
        #expect(KinHomeTheme.season(of: Self.day(month: 12, day: 1), calendar: Self.calendar) == .winter)
    }

    @Test func everyThemeHasItsOwnLook() {
        let symbols = KinHomeTheme.allCases.map(\.accentSymbol)
        #expect(Set(symbols).count == KinHomeTheme.allCases.count)
    }

    // MARK: - Profile: App Info

    @Test func appInfoReadsTheBundleVersionAndBuild() {
        let info = AppBuildInfo()

        #expect(!info.version.isEmpty)
        #expect(!info.build.isEmpty)
        #expect(info.releaseStatus.hasPrefix("Pre-release"))
    }
}


// MARK: - Dietary Profile Text

struct DietaryProfileTextTests {

    @Test func allergenCountIsHiddenAtZeroAndPluralized() {
        #expect(DietaryProfileText.allergenCount(0) == nil)
        #expect(DietaryProfileText.allergenCount(1) == "1 allergen")
        #expect(DietaryProfileText.allergenCount(4) == "4 allergens")
    }

    @Test func lastUpdatedSpellsOutTheMonth() {
        let date = Calendar(identifier: .gregorian).date(
            from: DateComponents(year: 2026, month: 9, day: 11, hour: 12)
        )!
        #expect(
            DietaryProfileText.lastUpdated(date, locale: Locale(identifier: "en_US"))
                == "Last updated September 11, 2026"
        )
        #expect(DietaryProfileText.lastUpdated(nil) == "Last updated unavailable")
    }
}


// MARK: - Dietary Background

struct DietaryBackgroundTests {

    @Test func savedChoiceFallsBackToSunnyKitchen() {
        #expect(KinDietaryBackground.saved("eveningAmbience") == .eveningAmbience)
        #expect(KinDietaryBackground.saved("gone") == .sunnyKitchen)
        #expect(KinDietaryBackground.saved("") == .sunnyKitchen)
    }

    @Test func databaseValuesMatchTheSupabaseEnum() {
        #expect(
            KinDietaryBackground.allCases.map(\.databaseValue) == [
                "sunny_kitchen",
                "evening_ambience",
                "modern_marble",
                "rustic_table",
                "farmhouse",
                "herb_garden",
                "autumn_harvest"
            ]
        )
        for background in KinDietaryBackground.allCases {
            #expect(KinDietaryBackground(databaseValue: background.databaseValue) == background)
        }
        #expect(KinDietaryBackground(databaseValue: "winter_comfort") == nil)
    }

    @Test func everyBackgroundHasItsImageInTheBundle() {
        for background in KinDietaryBackground.allCases {
            #expect(background.imageName.hasPrefix("DietaryBg"))
            #expect(
                UIImage(named: background.imageName) != nil,
                "Missing asset \(background.imageName)"
            )
        }
    }
}


// MARK: - Appearance

struct KinAppearanceTests {

    @Test func savedModesMapToColorSchemes() {
        #expect(KinAppearance.saved("light").colorScheme == .light)
        #expect(KinAppearance.saved("dark").colorScheme == .dark)
        #expect(KinAppearance.saved("system").colorScheme == nil)
    }

    @Test func unknownModeFallsBackToLight() {
        #expect(KinAppearance.saved("") == .light)
        #expect(KinAppearance.saved("sepia") == .light)
    }
}


// MARK: - Custom Dietary Items

struct CustomDietaryItemTests {

    @Test func keywordDropsNoAndFreeAndPlurals() {
        #expect(CustomDietaryMatcher.keyword(from: "No Mushrooms") == "mushroom")
        #expect(CustomDietaryMatcher.keyword(from: "Corn-Free") == "corn")
        #expect(CustomDietaryMatcher.keyword(from: "Strawberries") == "strawberry")
        #expect(CustomDietaryMatcher.keyword(from: "Tomatoes") == "tomato")
        #expect(CustomDietaryMatcher.keyword(from: "Cilantro") == "cilantro")
        // Odd plurals still match the ingredient itself.
        #expect(
            CustomDietaryMatcher.matchingIngredients(for: "Molasses", in: ["Dark molasses"])
                == ["Dark molasses"]
        )
    }

    @Test func matchesWholeWordsAndPlurals() {
        let ingredients = [
            "2 cups fresh strawberries",
            "Peanut butter",
            "Sliced mushrooms",
            "Cilantro, chopped"
        ]
        #expect(
            CustomDietaryMatcher.matchingIngredients(for: "Strawberry", in: ingredients)
                == ["2 cups fresh strawberries"]
        )
        #expect(
            CustomDietaryMatcher.matchingIngredients(for: "No Mushrooms", in: ingredients)
                == ["Sliced mushrooms"]
        )
        #expect(
            CustomDietaryMatcher.matchingIngredients(for: "Cilantro", in: ingredients)
                == ["Cilantro, chopped"]
        )
        // "Pea" isn't "peanut".
        #expect(CustomDietaryMatcher.matchingIngredients(for: "Pea", in: ingredients).isEmpty)
        // Can't be judged from ingredients.
        #expect(CustomDietaryMatcher.matchingIngredients(for: "Low Carb", in: ingredients).isEmpty)
    }

    @Test func customRestrictionIsMatchedByName() {
        let restriction = DietaryRestriction(
            id: UUID(), name: "No Pork", createdAt: .now, isCustom: true
        )
        #expect(
            DietaryRestrictionRules.conflictingIngredients(
                for: restriction,
                ingredientNames: ["Pork shoulder", "Salt"],
                allergenAssociations: []
            ) == ["Pork shoulder"]
        )
    }

    @Test func typedNamesAreTidiedAndDeduplicated() {
        #expect(CustomDietaryText.cleaned("  tree   nuts ") == "Tree nuts")
        #expect(CustomDietaryText.cleaned(String(repeating: "a", count: 60)).count == 40)
        #expect(CustomDietaryText.existingMatch(for: "tree NUT", in: ["Egg", "Tree Nut"]) == "Tree Nut")
        #expect(CustomDietaryText.existingMatch(for: "Kiwi", in: ["Egg"]) == nil)
    }

    @Test func savingSplitsBuiltInAndCustomChanges() {
        let builtInA = UUID(), builtInB = UUID(), custom = UUID()
        let changes = DietaryEditChanges(
            original: [builtInA, custom],
            selected: [builtInB],
            customIds: [custom]
        )
        #expect(changes.toAdd == [builtInB])
        #expect(changes.toRemove == [builtInA])
        #expect(changes.customToDelete == [custom])
    }
}

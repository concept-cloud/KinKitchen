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


// MARK: - Measure Keyboard

struct MeasureKeyboardTextTests {

    private func type(_ keys: [MeasureKey]) -> String {
        keys.reduce("") { MeasureKeyboardText.applying($1, to: $0) }
    }

    @Test func fractionsJoinWholeNumbers() {
        #expect(type([.digit(1), .fraction("½")]) == "1½")
        #expect(type([.fraction("¾")]) == "¾")
        let twoAndAThird: Double = 2 + 1.0 / 3
        let typed = type([.digit(2), .fraction("⅓")])
        #expect(IngredientQuantityFormatter.parse(typed) == twoAndAThird)
        #expect(IngredientQuantityFormatter.parse("1½") == 1.5)
        #expect(IngredientQuantityFormatter.parse("¾") == 0.75)
        // Older amounts typed with a slash still read.
        #expect(IngredientQuantityFormatter.parse("1 1/2") == 1.5)
    }

    @Test func nothingFollowsAFraction() {
        #expect(type([.fraction("½"), .digit(3)]) == "½")
        #expect(type([.fraction("½"), .fraction("¼")]) == "½")
        #expect(type([.fraction("½"), .decimal]) == "½")
    }

    @Test func amountsDisplayWithFractionCharacters() {
        #expect(IngredientQuantityFormatter.format(1.5) == "1½")
        #expect(IngredientQuantityFormatter.format(0.25) == "¼")
        #expect(IngredientQuantityFormatter.format(2) == "2")
        // Round trip: what the edit screen shows saves the same.
        #expect(IngredientQuantityFormatter.parse(IngredientQuantityFormatter.format(2.75)) == 2.75)
    }

    @Test func decimalsStayValid() {
        #expect(type([.decimal]) == "0.")
        #expect(type([.digit(1), .decimal, .digit(5), .decimal]) == "1.5")
        #expect(type([.digit(1), .decimal, .fraction("½")]) == "1.")
    }

    @Test func deleteRemovesAWholeFraction() {
        #expect(type([.digit(1), .fraction("½"), .delete]) == "1")
        #expect(type([.digit(1), .digit(2), .delete]) == "1")
        #expect(type([.delete]) == "")
    }

    @Test func unitsHaveSpokenNames() {
        #expect(MeasureKeyboardText.UnitGroup.volume.units.contains("Tbsp"))
        #expect(MeasureKeyboardText.UnitGroup.weight.units.contains("lb"))
        #expect(MeasureKeyboardText.UnitGroup.other.units.contains("pinch"))
        #expect(MeasureKeyboardText.group(for: "lb") == .weight)
        #expect(MeasureKeyboardText.group(for: "dash") == .other)
        #expect(MeasureKeyboardText.group(for: "") == .volume)
        // Every tab fits in three rows of four.
        #expect(MeasureKeyboardText.UnitGroup.allCases.allSatisfy { $0.units.count + ($0 == .other ? 1 : 0) <= 12 })
        #expect(MeasureKeyboardText.spokenName(for: "Tbsp") == "tablespoon")
        #expect(MeasureKeyboardText.spokenName(for: "cup") == "cup")
    }
}


// MARK: - Plural Units

struct PluralUnitTests {

    @Test func wordUnitsArePluralAboveOne() {
        #expect(IngredientQuantityFormatter.formattedMeasurement(quantity: 2, unit: "cup") == "2 cups")
        #expect(IngredientQuantityFormatter.formattedMeasurement(quantity: 1.5, unit: "cup") == "1½ cups")
        #expect(IngredientQuantityFormatter.formattedMeasurement(quantity: 3, unit: "pinch") == "3 pinches")
        #expect(IngredientQuantityFormatter.formattedMeasurement(quantity: 4, unit: "clove") == "4 cloves")
    }

    @Test func oneOrLessStaysSingular() {
        #expect(IngredientQuantityFormatter.formattedMeasurement(quantity: 1, unit: "cup") == "1 cup")
        #expect(IngredientQuantityFormatter.formattedMeasurement(quantity: 0.5, unit: "cups") == "½ cup")
        #expect(IngredientQuantityFormatter.formattedMeasurement(quantity: 1, unit: "cloves") == "1 clove")
    }

    @Test func abbreviationsAndUnknownUnitsDontChange() {
        #expect(IngredientQuantityFormatter.formattedMeasurement(quantity: 2, unit: "Tbsp") == "2 tbsp")
        #expect(IngredientQuantityFormatter.formattedMeasurement(quantity: 2, unit: "lb") == "2 lb")
        #expect(IngredientQuantityFormatter.formattedMeasurement(quantity: 2, unit: "g") == "2 g")
        #expect(IngredientQuantityFormatter.displayUnit("large", quantity: 3) == "large")
        #expect(IngredientQuantityFormatter.displayUnit("cup", quantity: nil) == "cup")
    }
}


// MARK: - Recipe List Refresh

struct RecipeListSignatureTests {

    private func recipe(
        id: UUID = UUID(),
        updatedAt: String = "2026-10-04T00:00:00Z"
    ) -> Recipe {
        Recipe(
            id: id,
            ownerId: UUID(),
            name: "Sunday Gravy",
            originalContributor: nil,
            sourceRecipeId: nil,
            originalRecipeId: nil,
            createdAt: "2026-10-04T00:00:00Z",
            updatedAt: updatedAt
        )
    }

    @Test func unchangedListMatches() {
        let soup = recipe()
        #expect(RecipeListSignature([soup]) == RecipeListSignature([soup]))
    }

    @Test func editsAddsAndRemovalsAreNoticed() {
        let id = UUID()
        let original = recipe(id: id)
        let edited = recipe(id: id, updatedAt: "2026-10-05T00:00:00Z")

        #expect(RecipeListSignature([original]) != RecipeListSignature([edited]))
        #expect(RecipeListSignature([original]) != RecipeListSignature([original, recipe()]))
        #expect(RecipeListSignature([original]) != RecipeListSignature([]))
    }
}


// MARK: - Profile Stats

struct ProfileStatsTextTests {

    @Test func ratingWording() {
        #expect(ProfileStatsText.average(4.56) == "4.6")
        #expect(ProfileStatsText.ratingCount(1) == "from 1 rating")
        #expect(ProfileStatsText.ratingCount(23) == "from 23 ratings")
    }

    @Test func starsRoundToTheNearestHalf() {
        #expect(ProfileStatsText.stars(for: 4.6) == (4, true))
        #expect(ProfileStatsText.stars(for: 4.8) == (5, false))
        #expect(ProfileStatsText.stars(for: 3.2) == (3, false))
        #expect(ProfileStatsText.stars(for: 9) == (5, false))
    }

    @Test func statsDecodeFromTheDatabaseFunction() throws {
        let json = """
        [{"recipe_count":12,"cookbook_count":3,"shared_recipe_count":5,
          "rating_average":4.25,"rating_count":8,"rating_is_public":false}]
        """
        let rows = try JSONDecoder().decode([ProfileStats].self, from: Data(json.utf8))
        #expect(rows.first?.recipeCount == 12)
        #expect(rows.first?.ratingAverage == 4.25)
        #expect(rows.first?.ratingIsPublic == false)

        let empty = """
        [{"recipe_count":0,"cookbook_count":0,"shared_recipe_count":0,
          "rating_average":null,"rating_count":0,"rating_is_public":true}]
        """
        let none = try JSONDecoder().decode([ProfileStats].self, from: Data(empty.utf8))
        #expect(none.first?.ratingAverage == nil)
    }
}


// MARK: - Notification Text

struct NotificationTextTests {

    private let calendar = Calendar(identifier: .gregorian)

    private func notification(
        _ type: KinNotificationType,
        relatedType: String?
    ) -> KinNotification {
        KinNotification(
            id: UUID(), userId: UUID(), type: type, title: "T", message: nil,
            relatedType: relatedType, relatedId: relatedType == nil ? nil : UUID(),
            isRead: false, createdAt: .now
        )
    }

    @Test func datesSayTodayAndYesterday() {
        let now = calendar.date(from: DateComponents(year: 2026, month: 10, day: 15, hour: 12))!
        let earlier = now.addingTimeInterval(-3600)
        let yesterday = now.addingTimeInterval(-86_400)
        let lastWeek = now.addingTimeInterval(-7 * 86_400)

        #expect(NotificationText.date(earlier, now: now, calendar: calendar).hasPrefix("Today at"))
        #expect(NotificationText.date(yesterday, now: now, calendar: calendar).hasPrefix("Yesterday at"))
        #expect(NotificationText.date(lastWeek, now: now, calendar: calendar).contains(" at "))
    }

    @Test func actionsMatchWhatTheNotificationPointsAt() {
        let event = notification(.invitationAccepted, relatedType: "gathering")
        let recipe = notification(.recipeShared, relatedType: "recipe")
        let plain = notification(.dishUpdated, relatedType: nil)

        #expect(NotificationText.actionTitle(for: event) == "View Event")
        #expect(NotificationText.actionTitle(for: recipe) == "View Recipe")
        #expect(NotificationText.actionTitle(for: plain) == nil)
        #expect(event.hasDetails && recipe.hasDetails && !plain.hasDetails)
        #expect(recipe.recipeId != nil && recipe.gatheringId == nil)
    }
}

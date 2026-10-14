//
//  CookbookLibraryTests.swift
//  KinKitchenTests
//
//  Created by Greg Hudler on 10/14/26.
//

import Foundation
import Testing
@testable import KinKitchen

/// C2: Cookbook experience redesign.
struct CookbookLibraryTests {

    // MARK: - C2.1 Library cards

    @Test func recipeCountReadsNaturally() {
        #expect(KinCookbookCoverCard.recipeCountText(0) == "0 Recipes")
        #expect(KinCookbookCoverCard.recipeCountText(1) == "1 Recipe")
        #expect(KinCookbookCoverCard.recipeCountText(24) == "24 Recipes")
        #expect(KinCookbookCoverCard.recipeCountText(nil) == nil)
    }

    @Test func ownedAndSharedCookbooksAreLabeledDifferently() {
        #expect(CookbookBadge.mine.title == "Private")
        #expect(CookbookBadge.shared(by: "Sam").title == "Shared by Sam")
        #expect(CookbookBadge.shared(by: nil).title == "Shared")
        #expect(CookbookBadge.mine.icon != CookbookBadge.shared(by: nil).icon)
    }

    // MARK: - C2.2 Section tabs

    @Test func slidingAlongTheRailPicksTheTabUnderYourThumb() {
        let height: CGFloat = 60
        let step = height + CookbookSectionRail.spacing

        #expect(CookbookSectionRail.index(forY: 10, tabHeight: height, count: 5) == 0)
        #expect(CookbookSectionRail.index(forY: step * 2 + 5, tabHeight: height, count: 5) == 2)
    }

    @Test func slidingPastEitherEndStaysOnTheEndTab() {
        #expect(CookbookSectionRail.index(forY: -40, tabHeight: 60, count: 5) == 0)
        #expect(CookbookSectionRail.index(forY: 5_000, tabHeight: 60, count: 5) == 4)
    }

    @Test func tabsShrinkToFitManySectionsButNotBelowTheMinimum() {
        // A few sections: full-size tabs.
        #expect(CookbookSectionRail.tabHeight(available: 600, count: 3)
                == CookbookSectionRail.maxTabHeight)

        // Many sections: smaller, but always tappable.
        let crowded = CookbookSectionRail.tabHeight(available: 600, count: 14)
        #expect(crowded < CookbookSectionRail.maxTabHeight)
        #expect(crowded >= CookbookSectionRail.minTabHeight)
        #expect(CookbookSectionRail.tabHeight(available: 600, count: 40)
                == CookbookSectionRail.minTabHeight)
    }

    @Test func commonSectionNamesGetMatchingIcons() {
        #expect(CookbookSectionRail.icon(for: "Breakfast") == "sun.horizon.fill")
        #expect(CookbookSectionRail.icon(for: "Grandma's Desserts") == "birthday.cake.fill")
        #expect(CookbookSectionRail.icon(for: "Odds & Ends") == "bookmark.fill")
    }

    // MARK: - C2.2 Organize Cookbook

    static let breakfast = UUID()
    static let dinner = UUID()
    static let pancakes = UUID(), oats = UUID(), gravy = UUID(), bread = UUID()

    /// Breakfast: pancakes, oats · Dinner: gravy · Unsorted: bread
    static var layout: CookbookLayout {
        CookbookLayout(groups: [
            .init(sectionId: breakfast, recipeIds: [pancakes, oats]),
            .init(sectionId: dinner, recipeIds: [gravy]),
            .init(sectionId: nil, recipeIds: [bread])
        ])
    }

    @Test func layoutComesFromStoredPlacementsWithUnsortedLast() {
        let cookbookId = UUID()
        let stray = UUID()
        let layout = CookbookLayout(
            sectionIds: [Self.breakfast, Self.dinner],
            relationships: [
                CookbookRecipe(cookbookId: cookbookId, recipeId: Self.oats, sectionId: Self.breakfast, sortOrder: 1),
                CookbookRecipe(cookbookId: cookbookId, recipeId: Self.pancakes, sectionId: Self.breakfast, sortOrder: 0),
                CookbookRecipe(cookbookId: cookbookId, recipeId: Self.bread, sectionId: nil, sortOrder: 0),
                // Section was deleted: counts as Unsorted.
                CookbookRecipe(cookbookId: cookbookId, recipeId: stray, sectionId: UUID(), sortOrder: 1)
            ]
        )

        #expect(layout.groups.map(\.sectionId) == [Self.breakfast, Self.dinner, nil])
        #expect(layout.groups[0].recipeIds == [Self.pancakes, Self.oats])
        #expect(layout.groups[2].recipeIds == [Self.bread, stray])
    }

    @Test func draggingARecipeUnderAnotherHeadingMovesItThere() {
        // Rows: [Breakfast, pancakes, oats, Dinner, gravy, Unsorted, bread]
        // Drag oats (row 2) to just after gravy (before Unsorted, row 5).
        let moved = Self.layout.moving(rowsAt: [2], to: 5)

        #expect(moved.groups[0].recipeIds == [Self.pancakes])
        #expect(moved.groups[1].recipeIds == [Self.gravy, Self.oats])
    }

    @Test func headingsCantBeDraggedAndNothingLandsAboveTheFirstOne() {
        #expect(Self.layout.moving(rowsAt: [3], to: 0) == Self.layout)

        let toTop = Self.layout.moving(rowsAt: [4], to: 0)
        #expect(toTop.groups[0].recipeIds == [Self.gravy, Self.pancakes, Self.oats])
    }

    @Test func batchMoveKeepsOrderAndAppendsToTheSection() {
        let moved = Self.layout.moving([Self.bread, Self.pancakes], to: Self.dinner)

        #expect(moved.groups[0].recipeIds == [Self.oats])
        #expect(moved.groups[1].recipeIds == [Self.gravy, Self.pancakes, Self.bread])
        #expect(moved.groups[2].recipeIds.isEmpty)
    }

    @Test func onlyChangedSectionsAreSaved() {
        let moved = Self.layout.moving([Self.bread], to: Self.dinner)
        let changed = moved.changedGroups(since: Self.layout).map(\.sectionId)

        #expect(Set(changed) == Set([Self.dinner, nil]))
    }

    @Test func deletingASectionSendsItsRecipesToUnsorted() {
        let removed = Self.layout.removingSection(Self.breakfast)

        #expect(removed.groups.map(\.sectionId) == [Self.dinner, nil])
        #expect(removed.groups[1].recipeIds == [Self.bread, Self.pancakes, Self.oats])
    }

    @Test func newSectionsGoBeforeUnsorted() {
        let added = UUID()
        #expect(Self.layout.addingSection(added).groups.map(\.sectionId)
                == [Self.breakfast, Self.dinner, added, nil])
    }

    // MARK: - Organize filter

    @Test func emptyFilterShowsEverything() {
        let filter = OrganizeFilter()

        #expect(!filter.isActive)
        #expect(filter.matches(category: nil, sectionId: nil, isFeatured: false))
    }

    @Test func sectionFilterCanPickUnsorted() {
        var filter = OrganizeFilter()
        filter.section = .some(nil)

        #expect(filter.matches(category: nil, sectionId: nil, isFeatured: false))
        #expect(!filter.matches(category: nil, sectionId: Self.dinner, isFeatured: false))
    }

    @Test func categoryFilterMatchesAnyChosenCategoryIgnoringCase() {
        var filter = OrganizeFilter()
        filter.toggle(.dessert)
        filter.toggle(.snack)

        #expect(filter.matches(category: "dessert", sectionId: nil, isFeatured: false))
        #expect(filter.matches(category: "Snack", sectionId: nil, isFeatured: false))
        #expect(!filter.matches(category: "Dinner", sectionId: nil, isFeatured: false))
        #expect(!filter.matches(category: nil, sectionId: nil, isFeatured: false))
        #expect(filter.categoryTitle == "2 Categories")
        #expect(filter.activeCount == 1)
    }

    @Test func filtersCombine() {
        var filter = OrganizeFilter()
        filter.section = .some(Self.dinner)
        filter.featuredOnly = true

        #expect(filter.matches(category: nil, sectionId: Self.dinner, isFeatured: true))
        #expect(!filter.matches(category: nil, sectionId: Self.dinner, isFeatured: false))
        #expect(!filter.matches(category: nil, sectionId: Self.breakfast, isFeatured: true))
        #expect(filter.activeCount == 2)
    }
}

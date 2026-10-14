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
}

//
//  CookbookLibraryTests.swift
//  KinKitchenTests
//
//  Created by Greg Hudler on 10/14/26.
//

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
}

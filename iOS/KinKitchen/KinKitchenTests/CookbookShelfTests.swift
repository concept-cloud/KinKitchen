//
//  CookbookShelfTests.swift
//  KinKitchenTests
//
//  Created by Greg Hudler on 10/15/26.
//

import Foundation
import Testing
@testable import KinKitchen

/// Regression: Cookbooks as a bookshelf.
struct CookbookShelfTests {

    @Test func twoBooksPerShelfWithNewCookbookLast() {
        let ids = [UUID(), UUID(), UUID()]
        let shelves = CookbookShelfLayout.shelves(for: ids)

        #expect(shelves.count == 2)
        #expect(shelves[0] == [.cookbook(ids[0]), .cookbook(ids[1])])
        #expect(shelves[1] == [.cookbook(ids[2]), .add])
    }

    @Test func evenCountPutsNewCookbookOnItsOwnShelf() {
        let ids = [UUID(), UUID()]
        let shelves = CookbookShelfLayout.shelves(for: ids)
        #expect(shelves.count == 2)
        #expect(shelves[1] == [.add])
    }

    @Test func noCookbooksStillShowsTheNewCookbookBook() {
        #expect(CookbookShelfLayout.shelves(for: []) == [[.add]])
    }
}

extension CookbookShelfTests {

    @Test func searchingLeavesOffTheNewCookbookBook() {
        let ids = [UUID()]
        #expect(CookbookShelfLayout.shelves(for: ids, includesAdd: false) == [[.cookbook(ids[0])]])
        #expect(CookbookShelfLayout.shelves(for: [], includesAdd: false).isEmpty)
    }
}

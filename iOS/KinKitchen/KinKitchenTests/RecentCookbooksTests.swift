//
//  RecentCookbooksTests.swift
//  KinKitchenTests
//
//  Created by Greg Hudler on 10/15/26.
//

import Foundation
import Testing
@testable import KinKitchen

/// Regression: Home's Recent Cookbooks.
struct RecentCookbooksTests {

    static func cookbook(_ name: String) throws -> Cookbook {
        let json = """
        {"id":"\(UUID())","owner_id":"\(UUID())","name":"\(name)",
         "visibility":"private","created_at":0,"updated_at":0}
        """
        return try JSONDecoder().decode(Cookbook.self, from: Data(json.utf8))
    }

    @Test func recentlyOpenedComeFirstThenOwnWithoutRepeats() throws {
        let beach = try Self.cookbook("Beach Treats")
        let holiday = try Self.cookbook("Holiday")
        let grandma = try Self.cookbook("Grandma's")

        let shown = RecentCookbooks.merge(
            recent: [holiday, grandma],
            owned: [beach, holiday]
        )
        #expect(shown.map(\.name) == ["Holiday", "Grandma's", "Beach Treats"])
    }

    @Test func noRecentsShowsOwnCookbooks() throws {
        let beach = try Self.cookbook("Beach Treats")
        #expect(RecentCookbooks.merge(recent: [], owned: [beach]).map(\.name) == ["Beach Treats"])
    }

    @Test func keepsTheRowShort() throws {
        let many = try (0..<10).map { try Self.cookbook("Book \($0)") }
        #expect(RecentCookbooks.merge(recent: many, owned: []).count == RecentCookbooks.limit)
    }
}

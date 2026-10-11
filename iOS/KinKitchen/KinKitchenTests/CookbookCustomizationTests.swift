//
//  CookbookCustomizationTests.swift
//  KinKitchenTests
//
//  Created by Greg Hudler on 10/11/26.
//

import Foundation
import Testing
@testable import KinKitchen

/// B4: cookbook sections and ordering.
struct CookbookCustomizationTests {

    // MARK: - KINKIT-173 Section Names

    @Test func sectionNameIsTrimmed() throws {
        #expect(
            try CookbookService.validatedSectionName("  Desserts  ")
                == "Desserts"
        )
    }

    @Test func blankSectionNameIsRejected() {
        #expect(throws: CookbookServiceError.self) {
            try CookbookService.validatedSectionName("   ")
        }
    }

    @Test func overlongSectionNameIsRejected() {
        let name =
            String(
                repeating: "a",
                count: CookbookSection.maxNameLength + 1
            )

        #expect(throws: CookbookServiceError.self) {
            try CookbookService.validatedSectionName(name)
        }
    }

    // MARK: - KINKIT-174 Section Assignment

    static let cookbookId = UUID()
    static let desserts = UUID()

    static func relationship(
        section: UUID?,
        order: Int
    ) -> CookbookRecipe {
        CookbookRecipe(
            cookbookId: cookbookId,
            recipeId: UUID(),
            sectionId: section,
            sortOrder: order
        )
    }

    @Test func movingToUnsortedSendsNullSection() throws {
        let data =
            try JSONEncoder().encode(
                CookbookRecipePlacement(
                    sectionId: nil,
                    sortOrder: 3
                )
            )

        let json =
            try #require(
                JSONSerialization.jsonObject(with: data)
                    as? [String: Any]
            )

        // The key must be present (as null), or the recipe would
        // stay in its old section.
        #expect(json.keys.contains("section_id"))
        #expect(json["section_id"] is NSNull)
        #expect(json["sort_order"] as? Int == 3)
    }

    @Test func movedRecipeLandsAtEndOfItsNewSection() {
        let relationships = [
            Self.relationship(section: Self.desserts, order: 0),
            Self.relationship(section: Self.desserts, order: 4),
            Self.relationship(section: nil, order: 9)
        ]

        #expect(
            CookbookService.nextSortOrder(
                in: Self.desserts,
                relationships: relationships
            ) == 5
        )
        #expect(
            CookbookService.nextSortOrder(
                in: nil,
                relationships: relationships
            ) == 10
        )
    }

    @Test func emptySectionStartsAtZero() {
        #expect(
            CookbookService.nextSortOrder(
                in: UUID(),
                relationships: []
            ) == 0
        )
    }

    @Test func maxLengthSectionNameIsAllowed() throws {
        let name =
            String(
                repeating: "a",
                count: CookbookSection.maxNameLength
            )

        #expect(
            try CookbookService.validatedSectionName(name) == name
        )
    }
}

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

    // MARK: - KINKIT-175 Recipe Reordering

    static let a = UUID()
    static let b = UUID()
    static let c = UUID()
    static let d = UUID()

    @Test func draggingDownMovesItemAfterTarget() {
        // Drag A onto the slot after C (SwiftUI destination 3).
        #expect(
            CookbookService.reordered(
                [Self.a, Self.b, Self.c, Self.d],
                moving: [0],
                to: 3
            ) == [Self.b, Self.c, Self.a, Self.d]
        )
    }

    @Test func draggingUpMovesItemBeforeTarget() {
        #expect(
            CookbookService.reordered(
                [Self.a, Self.b, Self.c, Self.d],
                moving: [3],
                to: 1
            ) == [Self.a, Self.d, Self.b, Self.c]
        )
    }

    @Test func draggingToTheEndAndStart() {
        let ids = [Self.a, Self.b, Self.c]

        #expect(
            CookbookService.reordered(ids, moving: [0], to: 3)
                == [Self.b, Self.c, Self.a]
        )
        #expect(
            CookbookService.reordered(ids, moving: [2], to: 0)
                == [Self.c, Self.a, Self.b]
        )
    }

    @Test func reorderingKeepsEveryRecipeOnce() {
        let ids = [Self.a, Self.b, Self.c, Self.d]
        let result =
            CookbookService.reordered(ids, moving: [1], to: 4)

        #expect(result.count == ids.count)
        #expect(Set(result) == Set(ids))
    }

    @Test func savedOrderWinsThenTiesStayStable() {
        let first =
            CookbookRecipe(
                cookbookId: Self.cookbookId,
                recipeId: Self.b,
                sectionId: nil,
                sortOrder: 0
            )
        let second =
            CookbookRecipe(
                cookbookId: Self.cookbookId,
                recipeId: Self.a,
                sectionId: nil,
                sortOrder: 1
            )

        #expect(CookbookRecipe.displayOrder(first, second))
        #expect(!CookbookRecipe.displayOrder(second, first))
    }

    // MARK: - KINKIT-177 Featured Recipes + Price

    static func featured(
        section: UUID?
    ) -> CookbookRecipe {
        CookbookRecipe(
            cookbookId: cookbookId,
            recipeId: UUID(),
            sectionId: section,
            sortOrder: 0,
            isFeatured: true
        )
    }

    @Test func upToThreeFeaturedPerSection() {
        let two = [
            Self.featured(section: Self.desserts),
            Self.featured(section: Self.desserts)
        ]
        let three = two + [Self.featured(section: Self.desserts)]

        #expect(CookbookRecipe.canFeature(in: Self.desserts, relationships: two))
        #expect(!CookbookRecipe.canFeature(in: Self.desserts, relationships: three))
    }

    @Test func featuredLimitIsPerSection() {
        let fullDesserts = [
            Self.featured(section: Self.desserts),
            Self.featured(section: Self.desserts),
            Self.featured(section: Self.desserts)
        ]

        // Another section and Unsorted each have their own 3.
        #expect(CookbookRecipe.canFeature(in: UUID(), relationships: fullDesserts))
        #expect(CookbookRecipe.canFeature(in: nil, relationships: fullDesserts))
    }

    @Test func missingFeaturedFlagDecodesAsNotFeatured() throws {
        let json = """
        {
          "cookbook_id": "\(Self.cookbookId.uuidString)",
          "recipe_id": "\(UUID().uuidString)",
          "section_id": null,
          "sort_order": 2
        }
        """

        let relationship =
            try JSONDecoder().decode(
                CookbookRecipe.self,
                from: Data(json.utf8)
            )

        #expect(!relationship.isFeatured)
    }

    @Test func cookbooksAreFreeByDefault() throws {
        let json = """
        {
          "id": "\(UUID().uuidString)",
          "owner_id": "\(UUID().uuidString)",
          "name": "Family Favorites",
          "visibility": "private",
          "created_at": "2026-10-11T00:00:00Z",
          "updated_at": "2026-10-11T00:00:00Z"
        }
        """

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let cookbook =
            try decoder.decode(
                Cookbook.self,
                from: Data(json.utf8)
            )

        #expect(cookbook.priceCents == 0)
        #expect(cookbook.isFree)
        #expect(cookbook.displayPrice == "Free")
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

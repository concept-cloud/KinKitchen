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

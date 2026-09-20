//
//  RecipientDietaryInformation.swift
//  KinKitchen
//
//  Created by Greg Hudler on 9/20/26.
//

import Foundation

// MARK: - Recipient Dietary Information

struct RecipientDietaryInformation: Hashable {
    let userId: UUID
    let allergens: [Allergen]
    let restrictions: [DietaryRestriction]
    let preferences: [DietaryPreference]

    var hasDietaryInformation: Bool {
        !allergens.isEmpty ||
        !restrictions.isEmpty ||
        !preferences.isEmpty
    }
}

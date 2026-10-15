//
//  CustomDietaryItem.swift
//  KinKitchen
//
//  Created by Greg Hudler on 10/14/26.
//

import Foundation

/// Something a user added to their own Dietary Profile, e.g. a
/// strawberry allergy or "no cilantro" (`custom_dietary_items`).
struct CustomDietaryItem: Codable, Identifiable, Hashable {

    enum Kind: String, Codable, CaseIterable {
        case allergen
        case restriction
        case preference
    }

    let id: UUID
    let userId: UUID
    let kind: Kind
    let name: String
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case kind
        case name
        case createdAt = "created_at"
    }

    var asAllergen: Allergen {
        Allergen(id: id, name: name, createdAt: createdAt, isCustom: true)
    }

    var asRestriction: DietaryRestriction {
        DietaryRestriction(id: id, name: name, createdAt: createdAt, isCustom: true)
    }

    var asPreference: DietaryPreference {
        DietaryPreference(id: id, name: name, createdAt: createdAt, isCustom: true)
    }
}


/// A user's custom items split by list.
struct CustomDietaryItems {

    var allergens: [Allergen] = []
    var restrictions: [DietaryRestriction] = []
    var preferences: [DietaryPreference] = []

    init() {}

    init(_ items: [CustomDietaryItem]) {
        for item in items {
            switch item.kind {
            case .allergen: allergens.append(item.asAllergen)
            case .restriction: restrictions.append(item.asRestriction)
            case .preference: preferences.append(item.asPreference)
            }
        }
    }
}


// MARK: - Name Matching

/// Matches a user's own item against ingredient names by whole word,
/// e.g. "Strawberry" catches "fresh strawberries" but "Pea" doesn't
/// catch "peanut". Like the restriction rules, a miss means
/// "not found", never "safe".
nonisolated enum CustomDietaryMatcher {

    /// "No Mushrooms" → "mushroom", "Corn-Free" → "corn".
    static func keyword(
        from name: String
    ) -> String {

        var words =
            normalize(name)
                .split(separator: " ")
                .map(String.init)

        let leading: Set<String> = ["no", "avoid", "without", "skip"]
        while let first = words.first, leading.contains(first), words.count > 1 {
            words.removeFirst()
        }

        if words.count > 1, words.last == "free" {
            words.removeLast()
        }

        var keyword = words.joined(separator: " ")

        // Singular, so plurals in recipes match ("mushrooms" → "mushroom").
        if keyword.hasSuffix("ies"), keyword.count > 4 {
            keyword = String(keyword.dropLast(3)) + "y"
        } else if keyword.hasSuffix("oes") {
            keyword = String(keyword.dropLast(2))
        } else if keyword.hasSuffix("s"), !keyword.hasSuffix("ss"), keyword.count > 3 {
            keyword = String(keyword.dropLast())
        }

        return keyword
    }

    /// Ingredient names containing the item, keeping recipe order.
    static func matchingIngredients(
        for name: String,
        in ingredientNames: [String]
    ) -> [String] {

        let keyword = keyword(from: name)

        guard !keyword.isEmpty else {
            return []
        }

        let forms = [keyword, keyword + "s", keyword + "es"]
            + (keyword.hasSuffix("y")
                ? [String(keyword.dropLast()) + "ies"]
                : [])

        var seen: Set<String> = []

        return ingredientNames.filter { ingredient in
            let padded = " \(normalize(ingredient)) "
            guard forms.contains(where: { padded.contains(" \($0) ") }) else {
                return false
            }
            return seen.insert(normalize(ingredient)).inserted
        }
    }

    static func normalize(
        _ value: String
    ) -> String {
        value
            .folding(
                options: [.diacriticInsensitive, .caseInsensitive],
                locale: Locale(identifier: "en_US_POSIX")
            )
            .lowercased()
            .map { $0.isLetter || $0.isNumber ? $0 : " " }
            .reduce(into: "") { $0.append($1) }
            .split(whereSeparator: \.isWhitespace)
            .joined(separator: " ")
    }
}

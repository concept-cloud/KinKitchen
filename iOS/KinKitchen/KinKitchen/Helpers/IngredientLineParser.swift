//
//  IngredientLineParser.swift
//  KinKitchen
//
//  Created by Greg Hudler on 10/15/26.
//

import Foundation

/// Turns pasted text into ingredient rows and steps, e.g. a recipe
/// copied from a website or a note:
/// "1 ½ cups flour" → amount "1 1/2", unit "cup", name "flour".
/// Anything it can't read stays in the name, so nothing is lost.
nonisolated enum IngredientLineParser {

    struct Ingredient: Equatable {
        var quantity: String
        var unit: String
        var name: String
    }

    /// Non-empty lines with bullets and numbering removed.
    static func lines(from text: String) -> [String] {
        text
            .components(separatedBy: .newlines)
            .map(strippingListMarker)
            .filter { !$0.isEmpty }
    }

    static func ingredients(from text: String) -> [Ingredient] {
        lines(from: text).map(ingredient(from:))
    }

    /// Steps, one per line. "Step 2:" and "2." prefixes are dropped
    /// since steps are numbered for you.
    static func steps(from text: String) -> [String] {
        lines(from: text)
    }

    static func ingredient(from line: String) -> Ingredient {

        var tokens =
            IngredientQuantityFormatter.expandingFractionGlyphs(line)
                .split(whereSeparator: \.isWhitespace)
                .map(String.init)

        // Amount: "2", "1/2", "1 1/2", "0.5".
        var quantityParts: [String] = []
        while let token = tokens.first,
              quantityParts.count < 2,
              isQuantity(token),
              quantityParts.isEmpty || token.contains("/") {
            quantityParts.append(token)
            tokens.removeFirst()
        }

        // Unit: the next word or two when it's a known unit.
        var unit = ""
        if !quantityParts.isEmpty || tokens.count > 1 {
            if tokens.count >= 2,
               let match = canonicalUnit(tokens[0] + " " + tokens[1]) {
                unit = match
                tokens.removeFirst(2)
            } else if let first = tokens.first,
                      let match = canonicalUnit(first) {
                unit = match
                tokens.removeFirst()
            }
        }

        // "2 cups of flour" → "flour".
        if !unit.isEmpty, tokens.first?.lowercased() == "of", tokens.count > 1 {
            tokens.removeFirst()
        }

        return Ingredient(
            quantity: quantityParts.joined(separator: " "),
            unit: unit,
            name: tokens.joined(separator: " ")
        )
    }


    // MARK: - Pieces

    static func strippingListMarker(_ line: String) -> String {
        var text = line.trimmingCharacters(in: .whitespaces)

        // "Step 3:" / "Step 3 -"
        if let range = text.range(
            of: #"^step\s*\d+\s*[:.)\-–]?\s*"#,
            options: [.regularExpression, .caseInsensitive]
        ) {
            text.removeSubrange(range)
        }

        // "1." / "1)" but not "1/2" or "1 cup".
        if let range = text.range(
            of: #"^\d+\s*[.)]\s+"#,
            options: .regularExpression
        ) {
            text.removeSubrange(range)
        }

        // "-", "•", "*", "▢", "☐"
        if let range = text.range(
            of: #"^[\-–•*▢☐◦·]+\s*"#,
            options: .regularExpression
        ) {
            text.removeSubrange(range)
        }

        return text.trimmingCharacters(in: .whitespaces)
    }

    static func isQuantity(_ token: String) -> Bool {
        IngredientQuantityFormatter.parse(token) != nil
    }

    /// The unit as the measuring keyboard writes it, or nil.
    static func canonicalUnit(_ token: String) -> String? {

        // Capital T is tablespoons, small t teaspoons.
        if token == "T" || token == "T." {
            return "Tbsp"
        }
        if token == "t" || token == "t." {
            return "tsp"
        }

        let word = token
            .lowercased()
            .trimmingCharacters(in: CharacterSet(charactersIn: ".,"))

        return unitNames[word]
    }

    private static let unitNames: [String: String] = {
        let groups: [String: [String]] = [
            "tsp": ["tsp", "tsps", "teaspoon", "teaspoons"],
            "Tbsp": ["tbsp", "tbsps", "tbs", "tbl", "tablespoon", "tablespoons"],
            "cup": ["cup", "cups", "c"],
            "fl oz": ["fl oz", "fl. oz", "fluid ounce", "fluid ounces"],
            "pint": ["pint", "pints", "pt"],
            "quart": ["quart", "quarts", "qt"],
            "gallon": ["gallon", "gallons", "gal"],
            "ml": ["ml", "milliliter", "milliliters", "millilitre", "millilitres"],
            "L": ["l", "liter", "liters", "litre", "litres"],
            "oz": ["oz", "ounce", "ounces"],
            "lb": ["lb", "lbs", "pound", "pounds"],
            "g": ["g", "gram", "grams"],
            "kg": ["kg", "kilogram", "kilograms"],
            "pinch": ["pinch", "pinches"],
            "dash": ["dash", "dashes"],
            "clove": ["clove", "cloves"],
            "can": ["can", "cans"],
            "slice": ["slice", "slices"],
            "piece": ["piece", "pieces"],
            "pkg": ["pkg", "pkgs", "package", "packages"],
            "stick": ["stick", "sticks"],
            "bunch": ["bunch", "bunches"],
            "sprig": ["sprig", "sprigs"]
        ]
        var names: [String: String] = [:]
        for (unit, words) in groups {
            for word in words {
                names[word] = unit
            }
        }
        return names
    }()
}

//
//  IngredientQuantityFormatter.swift
//  KinKitchen
//
//  Created by Greg Hudler on 9/7/26.
//

import Foundation

enum IngredientQuantityFormatter {

    // MARK: - Parse

    static func parse(_ value: String) -> Double? {
        let cleaned = value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "⁄", with: "/")

        guard !cleaned.isEmpty else {
            return nil
        }

        // Standard decimal / integer
        if let number = Double(cleaned) {
            return number
        }

        // Mixed number
        // Examples:
        // "1 1/2"
        // "2 3/4"
        let mixedParts = cleaned.split(separator: " ")

        if mixedParts.count == 2,
           let whole = Double(mixedParts[0]),
           let fraction = parseFraction(String(mixedParts[1])) {

            return whole + fraction
        }

        // Simple fraction
        // Examples:
        // "1/2"
        // "3/8"
        if let fraction = parseFraction(cleaned) {
            return fraction
        }

        return nil
    }

    private static func parseFraction(
        _ value: String
    ) -> Double? {

        let parts = value.split(separator: "/")

        guard
            parts.count == 2,
            let numerator = Double(parts[0]),
            let denominator = Double(parts[1]),
            denominator != 0
        else {
            return nil
        }

        return numerator / denominator
    }


    // MARK: - Format

    static func format(_ quantity: Double) -> String {
        let whole = Int(quantity)
        let fraction = quantity - Double(whole)

        let fractionText =
            nearestFractionText(
                fraction
            )

        if let fractionText {
            return whole > 0
                ? "\(whole) \(fractionText)"
                : fractionText
        }

        if quantity.rounded() == quantity {
            return "\(Int(quantity))"
        }

        return String(
            format: "%.2f",
            quantity
        )
        .replacingOccurrences(
            of: #"\.?0+$"#,
            with: "",
            options: .regularExpression
        )
    }

    private static func nearestFractionText(
        _ fraction: Double
    ) -> String? {

        let knownFractions: [
            (value: Double, text: String)
        ] = [
            (1.0 / 8.0, "1/8"),
            (1.0 / 6.0, "1/6"),
            (1.0 / 4.0, "1/4"),
            (1.0 / 3.0, "1/3"),
            (3.0 / 8.0, "3/8"),
            (1.0 / 2.0, "1/2"),
            (5.0 / 8.0, "5/8"),
            (2.0 / 3.0, "2/3"),
            (3.0 / 4.0, "3/4"),
            (5.0 / 6.0, "5/6"),
            (7.0 / 8.0, "7/8")
        ]

        let tolerance = 0.015

        return knownFractions.first {
            abs(
                fraction -
                $0.value
            ) <= tolerance
        }?.text
    }


    // MARK: - Unit Normalization

    static func normalizedUnit(
        _ unit: String
    ) -> String {

        let cleaned = unit
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )
            .lowercased()

        switch cleaned {

        case "tsp",
             "teaspoon",
             "teaspoons":
            return "tsp"

        case "tbsp",
             "tablespoon",
             "tablespoons":
            return "tbsp"

        case "cup",
             "cups":
            return "cup"

        case "fl oz",
             "fluid ounce",
             "fluid ounces":
            return "fl oz"

        case "oz",
             "ounce",
             "ounces":
            return "oz"

        case "lb",
             "lbs",
             "pound",
             "pounds":
            return "lb"

        case "ml",
             "milliliter",
             "milliliters",
             "millilitre",
             "millilitres":
            return "mL"

        case "l",
             "liter",
             "liters",
             "litre",
             "litres":
            return "L"

        case "g",
             "gram",
             "grams":
            return "g"

        case "kg",
             "kilogram",
             "kilograms":
            return "kg"

        default:
            return unit.trimmingCharacters(
                in: .whitespacesAndNewlines
            )
        }
    }


    // MARK: - Volume Conversion

    static func convertVolume(
        quantity: Double,
        fromUnit: String,
        toUnit: String
    ) -> Double? {

        guard
            let fromMilliliters =
                volumeToMilliliters(
                    quantity,
                    unit: fromUnit
                )
        else {
            return nil
        }

        return millilitersToVolume(
            fromMilliliters,
            unit: toUnit
        )
    }

    private static func volumeToMilliliters(
        _ quantity: Double,
        unit: String
    ) -> Double? {

        switch normalizedUnit(unit) {

        case "tsp":
            return quantity * 4.92892

        case "tbsp":
            return quantity * 14.7868

        case "cup":
            return quantity * 236.588

        case "fl oz":
            return quantity * 29.5735

        case "mL":
            return quantity

        case "L":
            return quantity * 1000

        default:
            return nil
        }
    }

    private static func millilitersToVolume(
        _ milliliters: Double,
        unit: String
    ) -> Double? {

        switch normalizedUnit(unit) {

        case "tsp":
            return milliliters / 4.92892

        case "tbsp":
            return milliliters / 14.7868

        case "cup":
            return milliliters / 236.588

        case "fl oz":
            return milliliters / 29.5735

        case "mL":
            return milliliters

        case "L":
            return milliliters / 1000

        default:
            return nil
        }
    }


    // MARK: - Weight Conversion

    static func convertWeight(
        quantity: Double,
        fromUnit: String,
        toUnit: String
    ) -> Double? {

        guard
            let grams =
                weightToGrams(
                    quantity,
                    unit: fromUnit
                )
        else {
            return nil
        }

        return gramsToWeight(
            grams,
            unit: toUnit
        )
    }

    private static func weightToGrams(
        _ quantity: Double,
        unit: String
    ) -> Double? {

        switch normalizedUnit(unit) {

        case "oz":
            return quantity * 28.3495

        case "lb":
            return quantity * 453.592

        case "g":
            return quantity

        case "kg":
            return quantity * 1000

        default:
            return nil
        }
    }

    private static func gramsToWeight(
        _ grams: Double,
        unit: String
    ) -> Double? {

        switch normalizedUnit(unit) {

        case "oz":
            return grams / 28.3495

        case "lb":
            return grams / 453.592

        case "g":
            return grams

        case "kg":
            return grams / 1000

        default:
            return nil
        }
    }


    // MARK: - Temperature Conversion

    static func fahrenheitToCelsius(
        _ fahrenheit: Double
    ) -> Double {

        (fahrenheit - 32) *
        5.0 / 9.0
    }

    static func celsiusToFahrenheit(
        _ celsius: Double
    ) -> Double {

        (celsius * 9.0 / 5.0) +
        32
    }


    // MARK: - Convenience Conversions

    static func teaspoonsToTablespoons(
        _ teaspoons: Double
    ) -> Double {

        teaspoons / 3
    }

    static func tablespoonsToTeaspoons(
        _ tablespoons: Double
    ) -> Double {

        tablespoons * 3
    }

    static func tablespoonsToCups(
        _ tablespoons: Double
    ) -> Double {

        tablespoons / 16
    }

    static func cupsToTablespoons(
        _ cups: Double
    ) -> Double {

        cups * 16
    }

    static func cupsToFluidOunces(
        _ cups: Double
    ) -> Double {

        cups * 8
    }

    static func fluidOuncesToCups(
        _ ounces: Double
    ) -> Double {

        ounces / 8
    }

    static func poundsToOunces(
        _ pounds: Double
    ) -> Double {

        pounds * 16
    }

    static func ouncesToPounds(
        _ ounces: Double
    ) -> Double {

        ounces / 16
    }


    // MARK: - Display

    static func formattedMeasurement(
        quantity: Double?,
        unit: String?
    ) -> String {

        let quantityText =
            quantity.map {
                format($0)
            } ?? ""

        let unitText =
            unit.map {
                normalizedUnit($0)
            } ?? ""

        let result =
            [quantityText, unitText]
                .filter {
                    !$0.isEmpty
                }
                .joined(
                    separator: " "
                )

        return result.isEmpty
            ? "—"
            : result
    }
}

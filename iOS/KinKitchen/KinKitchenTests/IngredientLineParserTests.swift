//
//  IngredientLineParserTests.swift
//  KinKitchenTests
//
//  Created by Greg Hudler on 10/15/26.
//

import Foundation
import Testing
@testable import KinKitchen

/// Regression: Add Recipe "Paste a List".
struct IngredientLineParserTests {

    typealias Ingredient = IngredientLineParser.Ingredient

    @Test func readsAmountUnitAndName() {
        #expect(IngredientLineParser.ingredient(from: "2 cups flour") == Ingredient(quantity: "2", unit: "cup", name: "flour"))
        #expect(IngredientLineParser.ingredient(from: "1 1/2 tsp baking soda") == Ingredient(quantity: "1 1/2", unit: "tsp", name: "baking soda"))
        #expect(IngredientLineParser.ingredient(from: "½ lb ground beef") == Ingredient(quantity: "1/2", unit: "lb", name: "ground beef"))
        #expect(IngredientLineParser.ingredient(from: "1½ Tablespoons olive oil") == Ingredient(quantity: "1 1/2", unit: "Tbsp", name: "olive oil"))
        #expect(IngredientLineParser.ingredient(from: "8 fl oz milk") == Ingredient(quantity: "8", unit: "fl oz", name: "milk"))
    }

    @Test func capitalTIsTablespoonAndSmallTIsTeaspoon() {
        #expect(IngredientLineParser.ingredient(from: "1 T butter").unit == "Tbsp")
        #expect(IngredientLineParser.ingredient(from: "1 t salt").unit == "tsp")
    }

    @Test func keepsWhatItCantReadInTheName() {
        #expect(IngredientLineParser.ingredient(from: "3 large eggs") == Ingredient(quantity: "3", unit: "", name: "large eggs"))
        #expect(IngredientLineParser.ingredient(from: "Salt and pepper to taste") == Ingredient(quantity: "", unit: "", name: "Salt and pepper to taste"))
        #expect(IngredientLineParser.ingredient(from: "2 cups of sugar").name == "sugar")
        #expect(IngredientLineParser.ingredient(from: "Pinch salt") == Ingredient(quantity: "", unit: "pinch", name: "salt"))
    }

    @Test func dropsBulletsNumbersAndBlankLines() {
        let text = """
        • 2 cups flour

        - 1 tsp salt
        ▢ 3 eggs
        """
        #expect(IngredientLineParser.ingredients(from: text).map(\.name) == ["flour", "salt", "eggs"])
    }

    @Test func stepsLoseTheirNumbersButKeepAmounts() {
        let text = """
        1. Preheat the oven to 350.
        Step 2: Mix 1/2 cup sugar with the butter.
        3) Bake 25 minutes.
        """
        #expect(IngredientLineParser.steps(from: text) == [
            "Preheat the oven to 350.",
            "Mix 1/2 cup sugar with the butter.",
            "Bake 25 minutes."
        ])
        // "1 cup flour" isn't a numbered list item.
        #expect(IngredientLineParser.strippingListMarker("1 cup flour") == "1 cup flour")
    }

    @Test func timesReadNaturally() {
        #expect(RecipeTimeChoices.text(15) == "15 min")
        #expect(RecipeTimeChoices.text(60) == "1 hr")
        #expect(RecipeTimeChoices.text(90) == "1 hr 30 min")
    }
}

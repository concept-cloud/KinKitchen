//
//  RecipeDiscoveryTests.swift
//  KinKitchenTests
//
//  Created by Greg Hudler on 10/4/26.
//

import Foundation
import Testing
@testable import KinKitchen

/// KINKIT-141: every discovery criterion combines into one result list.
struct RecipeDiscoveryTests {

    // MARK: - Fixtures

    static let milk = allergen("Milk")
    static let egg = allergen("Egg")
    static let peanut = allergen("Peanut")

    static let vegan = restriction("Vegan")
    static let glutenFree = restriction("Gluten-Free")

    static let chickenParm = recipe("Chicken Parm", .dinner)
    static let veggieStirFry = recipe("Veggie Stir Fry", .dinner)
    static let pancakes = recipe("Pancakes", .breakfast)
    static let fruitSalad = recipe("Fruit Salad", .breakfast)
    static let peanutNoodles = recipe("Peanut Noodles", .lunch)

    static let recipes = [
        chickenParm,
        veggieStirFry,
        pancakes,
        fruitSalad,
        peanutNoodles
    ]

    static let context = RecipeDiscoveryContext(
        restrictions: [vegan, glutenFree],
        allergens: [egg, milk, peanut],
        insights: [
            chickenParm.id: insight(
                ["chicken breast", "mozzarella", "all-purpose flour"],
                allergens: [milk: ["mozzarella"]]
            ),
            veggieStirFry.id: insight(
                ["broccoli", "soy sauce", "rice"],
                tagged: [vegan.id]
            ),
            pancakes.id: insight(
                ["milk", "egg", "all-purpose flour"],
                allergens: [milk: ["milk"], egg: ["egg"]]
            ),
            fruitSalad.id: insight(
                ["apple", "banana"],
                tagged: [vegan.id]
            ),
            peanutNoodles.id: insight(
                ["peanut butter", "rice noodles"],
                allergens: [peanut: ["peanut butter"]]
            )
        ]
    )


    func results(
        _ criteria: RecipeDiscoveryCriteria
    ) -> [String] {

        criteria
            .apply(
                to: Self.recipes,
                context: Self.context
            )
            .map(\.name)
    }

    // MARK: - Pairs

    @Test func searchAndCategory() {
        var criteria = RecipeDiscoveryCriteria()
        criteria.searchText = "p"
        criteria.categories = [.breakfast]

        #expect(results(criteria) == ["Pancakes"])
    }

    @Test func searchAndRestriction() {
        var criteria = RecipeDiscoveryCriteria()
        criteria.searchText = "salad"
        criteria.restrictionIds = [Self.vegan.id]

        #expect(results(criteria) == ["Fruit Salad"])
    }

    @Test func searchAndAllergen() {
        var criteria = RecipeDiscoveryCriteria()
        criteria.searchText = "noodles"
        criteria.allergenIds = [Self.peanut.id]

        #expect(results(criteria).isEmpty)
    }

    @Test func categoryAndRestriction() {
        var criteria = RecipeDiscoveryCriteria()
        criteria.categories = [.dinner]
        criteria.restrictionIds = [Self.vegan.id]

        #expect(results(criteria) == ["Veggie Stir Fry"])
    }

    @Test func categoryAndAllergen() {
        var criteria = RecipeDiscoveryCriteria()
        criteria.categories = [.breakfast]
        criteria.allergenIds = [Self.egg.id]

        #expect(results(criteria) == ["Fruit Salad"])
    }

    @Test func restrictionAndAllergen() {
        var criteria = RecipeDiscoveryCriteria()
        criteria.restrictionIds = [Self.glutenFree.id]
        criteria.allergenIds = [Self.peanut.id]

        // Chicken Parm and Pancakes have flour, Veggie Stir Fry has
        // soy sauce, and Peanut Noodles has peanut.
        #expect(results(criteria) == ["Fruit Salad"])
    }

    // MARK: - All Together

    @Test func allCriteriaTogether() {
        var criteria = RecipeDiscoveryCriteria()
        criteria.searchText = "fruit"
        criteria.categories = [.breakfast, .lunch]
        criteria.restrictionIds = [Self.vegan.id, Self.glutenFree.id]
        criteria.allergenIds = [Self.milk.id, Self.peanut.id]

        #expect(results(criteria) == ["Fruit Salad"])
    }

    @Test func changingOneCriterionKeepsTheOthers() {
        var criteria = RecipeDiscoveryCriteria()
        criteria.categories = [.dinner]
        criteria.allergenIds = [Self.milk.id]

        #expect(results(criteria) == ["Veggie Stir Fry"])

        criteria.categories = [.breakfast]

        #expect(criteria.allergenIds == [Self.milk.id])
        #expect(results(criteria) == ["Fruit Salad"])
    }

    @Test func removingAFilterRestoresOnlyWhatItExcluded() {
        var criteria = RecipeDiscoveryCriteria()
        criteria.categories = [.breakfast]
        criteria.allergenIds = [Self.egg.id]

        criteria.allergenIds = []

        #expect(results(criteria) == ["Pancakes", "Fruit Salad"])
    }

    @Test func originalCollectionIsNotModified() {
        var criteria = RecipeDiscoveryCriteria()
        criteria.categories = [.lunch]

        _ = results(criteria)

        #expect(Self.recipes.count == 5)
        #expect(results(RecipeDiscoveryCriteria()).count == 5)
    }

    @Test func noResultCombination() {
        var criteria = RecipeDiscoveryCriteria()
        criteria.categories = [.lunch]
        criteria.restrictionIds = [Self.vegan.id]
        criteria.allergenIds = [Self.peanut.id]

        #expect(results(criteria).isEmpty)
    }

    // MARK: - Unknown Information

    @Test func unknownInformationStaysVisible() {
        let mystery = Self.recipe("Mystery Stew", .dinner)

        var context = Self.context
        context.insights[mystery.id] = Self.insight(
            ["grandma's secret sauce"],
            unknown: ["grandma's secret sauce"]
        )

        var criteria = RecipeDiscoveryCriteria()
        criteria.allergenIds = [Self.peanut.id]
        criteria.restrictionIds = [Self.vegan.id]

        let names =
            criteria
                .apply(to: [mystery], context: context)
                .map(\.name)

        #expect(names == ["Mystery Stew"])
        #expect(
            context.allergenStatus(of: mystery, for: Self.peanut)
                == .incomplete
        )
        #expect(
            context.restrictionStatus(of: mystery, for: Self.vegan)
                == .notVerified
        )
    }
}

// MARK: - Profile Conflicts (KINKIT-142)

extension RecipeDiscoveryTests {

    func profileContext(
        allergens: Set<UUID> = [],
        restrictions: Set<UUID> = []
    ) -> RecipeDiscoveryContext {
        var context = Self.context
        context.profileAllergenIds = allergens
        context.profileRestrictionIds = restrictions
        return context
    }

    @Test func knownAllergenConflictIsWarned() {
        let context = profileContext(
            allergens: [Self.milk.id]
        )

        let conflict = context.profileConflict(of: Self.pancakes)

        #expect(conflict.hasConflict)
        #expect(conflict.allergens == [Self.milk])
    }

    @Test func restrictionConflictIsWarned() {
        let context = profileContext(
            restrictions: [Self.vegan.id]
        )

        let conflict = context.profileConflict(of: Self.chickenParm)

        #expect(conflict.restrictions == [Self.vegan])
    }

    @Test func warningStaysWithTheRightRecipe() {
        let context = profileContext(
            allergens: [Self.peanut.id]
        )

        #expect(context.profileConflict(of: Self.peanutNoodles).hasConflict)
        #expect(!context.profileConflict(of: Self.fruitSalad).hasConflict)
        #expect(!context.profileConflict(of: Self.pancakes).hasConflict)
    }

    @Test func noProfileMeansNoWarning() {
        let conflict =
            profileContext()
                .profileConflict(of: Self.pancakes)

        #expect(conflict == RecipeProfileConflict())
    }

    @Test func unknownInformationIsFlaggedNotSafe() {
        let mystery = Self.recipe("Mystery Stew", .dinner)

        var context = profileContext(
            allergens: [Self.peanut.id]
        )
        context.insights[mystery.id] = Self.insight(
            ["grandma's secret sauce"],
            unknown: ["grandma's secret sauce"]
        )

        let conflict = context.profileConflict(of: mystery)

        #expect(!conflict.hasConflict)
        #expect(conflict.isIncomplete)
    }
}

// MARK: - Clear Filters (KINKIT-143)

extension RecipeDiscoveryTests {

    @Test func clearingResetsEverythingAndRestoresResults() {
        var criteria = RecipeDiscoveryCriteria()
        criteria.searchText = "fruit"
        criteria.categories = [.breakfast]
        criteria.restrictionIds = [Self.vegan.id]
        criteria.allergenIds = [Self.peanut.id]

        #expect(criteria.isActive)
        #expect(results(criteria) == ["Fruit Salad"])

        criteria.reset()

        #expect(!criteria.isActive)
        #expect(criteria.activeFilterCount == 0)
        #expect(criteria.searchText.isEmpty)
        #expect(results(criteria).count == Self.recipes.count)
    }

    @Test func canFilterAgainAfterClearing() {
        var criteria = RecipeDiscoveryCriteria()
        criteria.categories = [.dinner]
        criteria.reset()

        criteria.categories = [.lunch]

        #expect(results(criteria) == ["Peanut Noodles"])
    }

    @Test func clearingDoesNotChangeLoadedData() {
        var criteria = RecipeDiscoveryCriteria()
        criteria.allergenIds = [Self.milk.id]
        _ = results(criteria)

        criteria.reset()

        #expect(Self.context.insights.count == Self.recipes.count)
        #expect(Self.context.profileAllergenIds.isEmpty)
    }
}

// MARK: - Fixture Builders

private extension RecipeDiscoveryTests {

    static func allergen(
        _ name: String
    ) -> Allergen {
        Allergen(
            id: UUID(),
            name: name,
            createdAt: Date()
        )
    }

    static func restriction(
        _ name: String
    ) -> DietaryRestriction {
        DietaryRestriction(
            id: UUID(),
            name: name,
            createdAt: Date()
        )
    }

    static func recipe(
        _ name: String,
        _ category: RecipeCategory
    ) -> Recipe {
        Recipe(
            id: UUID(),
            ownerId: UUID(),
            name: name,
            category: category.rawValue,
            createdAt: "2026-10-04T00:00:00Z",
            updatedAt: "2026-10-04T00:00:00Z"
        )
    }

    static func insight(
        _ ingredients: [String],
        allergens: [Allergen: [String]] = [:],
        unknown: [String] = [],
        tagged: Set<UUID> = []
    ) -> RecipeDietaryInsight {
        RecipeDietaryInsight(
            ingredientNames: ingredients,
            allergenResult:
                RecipeAllergenAssociationResult(
                    ingredientResults: [],
                    allergenAssociations:
                        allergens.map {
                            AllergenSourceAssociation(
                                allergen: $0.key,
                                ingredientNames: $0.value
                            )
                        },
                    unknownIngredients: unknown,
                    knownIngredientsWithoutMappedAllergens: []
                ),
            taggedRestrictionIds: tagged
        )
    }
}

//
//  DietaryRestrictionRules.swift
//  KinKitchen
//
//  Created by Greg Hudler on 10/4/26.
//

import Foundation

// MARK: - Dietary Restriction Rules

/// Detects ingredients that conflict with a dietary restriction.
///
/// Rules only ever find conflicts. An ingredient that isn't caught
/// is unverified, never confirmed compatible.
enum DietaryRestrictionRules {

    /// Ingredient names in a recipe that conflict with the restriction.
    /// Returns an empty array when no conflict is known, including for
    /// restrictions without a rule.
    static func conflictingIngredients(
        for restriction: DietaryRestriction,
        ingredientNames: [String],
        allergenAssociations: [AllergenSourceAssociation]
    ) -> [String] {

        guard
            let rule =
                rule(
                    for: restriction
                )
        else {
            return []
        }

        var conflicts: [String] = []

        // Allergen matches from the existing allergen evaluation.
        for association in allergenAssociations
        where rule.allergenNames.contains(
            association.allergen.name.lowercased()
        ) {
            conflicts += association.ingredientNames
        }

        // Keyword matches on ingredient names.
        conflicts += ingredientNames.filter {
            matches(
                $0,
                keywords: rule.keywords
            )
        }

        if rule.checksMeatWithDairy {
            conflicts += meatWithDairyConflicts(
                ingredientNames: ingredientNames,
                allergenAssociations: allergenAssociations
            )
        }

        return unique(conflicts)
    }
}

// MARK: - Rule

private extension DietaryRestrictionRules {

    struct Rule {

        /// Lowercased allergen names, matching `allergens.name`.
        let allergenNames: Set<String>

        let keywords: [String]

        var checksMeatWithDairy = false
    }


    /// Rules keyed by the normalized `dietary_restrictions.name`.
    static func rule(
        for restriction: DietaryRestriction
    ) -> Rule? {

        switch IngredientAllergenService
            .normalizeIngredientName(
                restriction.name
            ) {

        case "gluten free":
            return Rule(
                allergenNames: ["wheat"],
                keywords: Keywords.gluten
            )

        case "vegetarian":
            return Rule(
                allergenNames: ["fish", "shellfish"],
                keywords: Keywords.meat + Keywords.seafood
            )

        case "vegan":
            return Rule(
                allergenNames: ["fish", "shellfish", "milk", "egg"],
                keywords:
                    Keywords.meat
                    + Keywords.seafood
                    + Keywords.dairy
                    + Keywords.egg
                    + Keywords.otherAnimal
            )

        case "halal":
            return Rule(
                allergenNames: [],
                keywords: Keywords.pork + Keywords.alcohol
            )

        case "kosher":
            return Rule(
                allergenNames: ["shellfish"],
                keywords: Keywords.pork + Keywords.shellfish,
                checksMeatWithDairy: true
            )

        default:
            return nil
        }
    }
}

// MARK: - Keywords

private extension DietaryRestrictionRules {

    enum Keywords {

        static let pork = [
            "pork", "bacon", "ham", "prosciutto", "pancetta",
            "lard", "chorizo", "pepperoni", "salami", "gelatin"
        ]

        static let meat = pork + [
            "beef", "steak", "veal", "sausage", "hot dog",
            "chicken", "turkey", "duck", "goose", "lamb",
            "mutton", "venison", "bison", "goat", "meatball",
            "ground meat"
        ]

        static let shellfish = [
            "shrimp", "prawn", "crab", "lobster", "clam",
            "oyster", "scallop", "mussel", "squid", "octopus"
        ]

        static let seafood = shellfish + [
            "fish", "salmon", "tuna", "cod", "tilapia",
            "halibut", "trout", "anchovy", "anchovies",
            "sardine", "fish sauce"
        ]

        static let dairy = [
            "milk", "butter", "cheese", "cream", "yogurt",
            "yoghurt", "ghee", "whey", "buttermilk", "parmesan",
            "mozzarella", "cheddar", "ricotta", "feta",
            "sour cream", "half and half", "custard"
        ]

        static let egg = [
            "egg", "mayonnaise", "mayo", "meringue"
        ]

        static let otherAnimal = [
            "honey"
        ]

        static let alcohol = [
            "wine", "beer", "rum", "vodka", "whiskey", "whisky",
            "bourbon", "brandy", "sake", "mirin", "liqueur",
            "tequila", "gin", "sherry", "alcohol"
        ]

        static let gluten = [
            "wheat", "barley", "rye", "spelt", "semolina", "farro",
            "bulgur", "couscous", "seitan", "malt", "all purpose flour",
            "bread flour", "cake flour", "bread", "breadcrumb",
            "panko", "spaghetti", "macaroni", "lasagna", "soy sauce",
            "beer"
        ]

        /// Ingredients described as free of animal products, gluten,
        /// etc. are skipped by keyword matching.
        static let skipMarkers = [
            "vegan", "dairy free", "plant based", "gluten free",
            "meatless", "imitation", "egg free"
        ]

        /// Plant-based phrases removed before matching so they don't
        /// trip a keyword (e.g. "coconut milk" isn't dairy).
        static let plantPhrases = [
            "peanut butter", "almond butter", "cashew butter",
            "sunflower butter", "apple butter", "cocoa butter",
            "coconut milk", "almond milk", "oat milk", "soy milk",
            "rice milk", "cashew milk", "coconut cream",
            "cream of tartar", "wine vinegar"
        ]
    }
}

// MARK: - Matching

private extension DietaryRestrictionRules {

    static func matches(
        _ ingredientName: String,
        keywords: [String]
    ) -> Bool {

        var name =
            IngredientAllergenService
                .normalizeIngredientName(
                    ingredientName
                )

        if Keywords.skipMarkers.contains(where: {
            name.contains($0)
        }) {
            return false
        }

        for phrase in Keywords.plantPhrases {
            name = name.replacingOccurrences(
                of: phrase,
                with: " "
            )
        }

        // Pad so keywords only match whole words
        // ("ham" shouldn't match "graham").
        let padded = " \(name) "

        return keywords.contains {
            padded.contains(" \($0) ")
                || padded.contains(" \($0)s ")
                || padded.contains(" \($0)es ")
        }
    }


    /// Kosher: meat and dairy in the same recipe.
    static func meatWithDairyConflicts(
        ingredientNames: [String],
        allergenAssociations: [AllergenSourceAssociation]
    ) -> [String] {

        let meatIngredients =
            ingredientNames.filter {
                matches(
                    $0,
                    keywords: Keywords.meat
                )
            }

        let dairyIngredients =
            ingredientNames.filter {
                matches(
                    $0,
                    keywords: Keywords.dairy
                )
            }
            + allergenAssociations
                .filter {
                    $0.allergen.name.lowercased() == "milk"
                }
                .flatMap(\.ingredientNames)

        guard
            !meatIngredients.isEmpty,
            !dairyIngredients.isEmpty
        else {
            return []
        }

        return meatIngredients + dairyIngredients
    }


    static func unique(
        _ values: [String]
    ) -> [String] {

        var seen: Set<String> = []

        return values.filter {
            seen.insert(
                IngredientAllergenService
                    .normalizeIngredientName($0)
            )
            .inserted
        }
    }
}

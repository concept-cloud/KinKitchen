//
//  IngredientAllergenService.swift
//  KinKitchen
//
//  Created by Greg Hudler on 9/9/26.
//

import Foundation
import Supabase


// MARK: - Ingredient Allergen Service

enum IngredientAllergenService {

    // MARK: - Catalog Version

    static func fetchCurrentCatalogVersion()
        async throws -> Int {

        let records:
            [AllergenCatalogMetadata] =
            try await SupabaseManager.client
                .from(
                    "allergen_catalog_metadata"
                )
                .select(
                    """
                    current_version
                    """
                )
                .eq(
                    "id",
                    value: 1
                )
                .limit(1)
                .execute()
                .value

        return records.first?.currentVersion ?? 1
    }


    // MARK: - Refresh Recipe If Needed

    static func refreshRecipeClassificationsIfNeeded(
        ingredients: [RecipeIngredient]
    ) async throws {

        guard !ingredients.isEmpty else {
            return
        }

        let currentVersion =
            try await fetchCurrentCatalogVersion()

        for ingredient in ingredients {

            guard
                ingredient
                    .allergenClassificationVersion
                    < currentVersion
            else {
                continue
            }

            _ = try await classifyAndStore(
                ingredientId:
                    ingredient.id,
                name:
                    ingredient.name,
                offProductId:
                    ingredient.offProductId,
                catalogVersion:
                    currentVersion
            )
        }
    }


    // MARK: - Evaluate One Ingredient

    static func evaluateIngredient(
        name: String,
        offProductId: String? = nil
    ) async throws
        -> IngredientAllergenAssociation {

        let normalizedName =
            normalizeIngredientName(
                name
            )

        guard !normalizedName.isEmpty else {

            return IngredientAllergenAssociation(
                ingredientName: name,
                canonicalIngredientName: nil,
                allergens: [],
                state: .unknown,
                source: nil
            )
        }


        // MARK: Catalog

        if let catalogIngredient =
            try await findCatalogIngredient(
                normalizedName:
                    normalizedName
            ) {

            return try await buildSystemAssociation(
                originalName: name,
                catalogIngredient:
                    catalogIngredient
            )
        }


        // MARK: Alias

        if let catalogIngredient =
            try await findIngredientByAlias(
                normalizedAlias:
                    normalizedName
            ) {

            return try await buildSystemAssociation(
                originalName: name,
                catalogIngredient:
                    catalogIngredient
            )
        }


        // MARK: Open Food Facts

        if let offProductId =
            cleanedOptionalString(
                offProductId
            ) {

            do {

                let offResult =
                    try await OpenFoodFactsService
                        .lookupBarcode(
                            offProductId
                        )

                return try await
                    buildOpenFoodFactsAssociation(
                        originalName: name,
                        result: offResult
                    )

            } catch {

                // Open Food Facts is supplemental.
                // Failure must not break recipe use.

                return IngredientAllergenAssociation(
                    ingredientName: name,
                    canonicalIngredientName: nil,
                    allergens: [],
                    state: .unknown,
                    source: nil
                )
            }
        }


        // MARK: Unknown

        return IngredientAllergenAssociation(
            ingredientName: name,
            canonicalIngredientName: nil,
            allergens: [],
            state: .unknown,
            source: nil
        )
    }


    // MARK: - Evaluate Whole Recipe

    static func evaluateRecipe(
        ingredients: [IngredientAllergenInput]
    ) async throws
        -> RecipeAllergenAssociationResult {

        var results:
            [IngredientAllergenAssociation] = []

        for ingredient in ingredients {

            let result =
                try await evaluateIngredient(
                    name: ingredient.name,
                    offProductId:
                        ingredient.offProductId
                )

            results.append(
                result
            )
        }

        return aggregateRecipeResults(
            results
        )
    }


    // MARK: - Classify and Store One Ingredient

    static func classifyAndStore(
        ingredientId: UUID,
        name: String,
        offProductId: String? = nil
    ) async throws
        -> IngredientAllergenAssociation {

        let currentVersion =
            try await fetchCurrentCatalogVersion()

        return try await classifyAndStore(
            ingredientId:
                ingredientId,
            name:
                name,
            offProductId:
                offProductId,
            catalogVersion:
                currentVersion
        )
    }


    // MARK: - Internal Classify and Store

    private static func classifyAndStore(
        ingredientId: UUID,
        name: String,
        offProductId: String?,
        catalogVersion: Int
    ) async throws
        -> IngredientAllergenAssociation {

        let result =
            try await evaluateIngredient(
                name: name,
                offProductId:
                    offProductId
            )

        // Remove only automatic associations.
        //
        // Never delete source=user rows.

        try await deleteAutomaticAssociations(
            ingredientId:
                ingredientId
        )

        if let source = result.source {

            for allergen in result.allergens {

                let insert =
                    IngredientAllergenInsert(
                        ingredientId:
                            ingredientId,
                        allergenId:
                            allergen.id,
                        source:
                            source.rawValue
                    )

                try await SupabaseManager.client
                    .from(
                        "ingredient_allergens"
                    )
                    .upsert(
                        insert,
                        onConflict:
                            "ingredient_id,allergen_id"
                    )
                    .execute()
            }
        }

        // Classification completed successfully,
        // even when the result is unknown or contains
        // no mapped allergens.

        try await updateClassificationVersion(
            ingredientId:
                ingredientId,
            version:
                catalogVersion
        )

        return result
    }


    // MARK: - Classify and Store Ingredient List

    static func classifyAndStore(
        ingredients: [IngredientAllergenInput]
    ) async throws
        -> RecipeAllergenAssociationResult {

        guard !ingredients.isEmpty else {

            return RecipeAllergenAssociationResult(
                ingredientResults: [],
                allergenAssociations: [],
                unknownIngredients: [],
                knownIngredientsWithoutMappedAllergens: []
            )
        }

        let currentVersion =
            try await fetchCurrentCatalogVersion()

        var results:
            [IngredientAllergenAssociation] = []

        for ingredient in ingredients {

            guard let ingredientId =
                ingredient.id else {

                let result =
                    try await evaluateIngredient(
                        name:
                            ingredient.name,
                        offProductId:
                            ingredient.offProductId
                    )

                results.append(
                    result
                )

                continue
            }

            let result =
                try await classifyAndStore(
                    ingredientId:
                        ingredientId,
                    name:
                        ingredient.name,
                    offProductId:
                        ingredient.offProductId,
                    catalogVersion:
                        currentVersion
                )

            results.append(
                result
            )
        }

        return aggregateRecipeResults(
            results
        )
    }


    // MARK: - Catalog Lookup

    private static func findCatalogIngredient(
        normalizedName: String
    ) async throws
        -> IngredientCatalogRecord? {

        let records:
            [IngredientCatalogRecord] =
            try await SupabaseManager.client
                .from(
                    "ingredient_catalog"
                )
                .select(
                    """
                    id,
                    name,
                    normalized_name
                    """
                )
                .eq(
                    "normalized_name",
                    value:
                        normalizedName
                )
                .limit(1)
                .execute()
                .value

        return records.first
    }


    // MARK: - Alias Lookup

    private static func findIngredientByAlias(
        normalizedAlias: String
    ) async throws
        -> IngredientCatalogRecord? {

        let aliases:
            [IngredientAliasLookup] =
            try await SupabaseManager.client
                .from(
                    "ingredient_aliases"
                )
                .select(
                    """
                    ingredient_id
                    """
                )
                .eq(
                    "normalized_alias",
                    value:
                        normalizedAlias
                )
                .limit(1)
                .execute()
                .value

        guard let alias =
            aliases.first else {

            return nil
        }

        let ingredients:
            [IngredientCatalogRecord] =
            try await SupabaseManager.client
                .from(
                    "ingredient_catalog"
                )
                .select(
                    """
                    id,
                    name,
                    normalized_name
                    """
                )
                .eq(
                    "id",
                    value:
                        alias.ingredientId
                )
                .limit(1)
                .execute()
                .value

        return ingredients.first
    }


    // MARK: - Build System Association

    private static func buildSystemAssociation(
        originalName: String,
        catalogIngredient:
            IngredientCatalogRecord
    ) async throws
        -> IngredientAllergenAssociation {

        let mappings:
            [IngredientCatalogAllergenLookup] =
            try await SupabaseManager.client
                .from(
                    "ingredient_catalog_allergens"
                )
                .select(
                    """
                    allergen_id
                    """
                )
                .eq(
                    "ingredient_id",
                    value:
                        catalogIngredient.id
                )
                .execute()
                .value


        // The ingredient is known, but we do not
        // currently associate it with one of the
        // supported allergens.

        guard !mappings.isEmpty else {

            return IngredientAllergenAssociation(
                ingredientName:
                    originalName,
                canonicalIngredientName:
                    catalogIngredient.name,
                allergens: [],
                state:
                    .knownNoMappedAllergens,
                source:
                    .system
            )
        }


        let allergenIds =
            Set(
                mappings.map(
                    \.allergenId
                )
            )

        let availableAllergens =
            try await DietaryService
                .fetchAllergens()

        let matchedAllergens =
            availableAllergens
                .filter {
                    allergenIds.contains(
                        $0.id
                    )
                }
                .sorted {
                    $0.name
                        .localizedCaseInsensitiveCompare(
                            $1.name
                        )
                        == .orderedAscending
                }


        guard !matchedAllergens.isEmpty else {

            return IngredientAllergenAssociation(
                ingredientName:
                    originalName,
                canonicalIngredientName:
                    catalogIngredient.name,
                allergens: [],
                state:
                    .unknown,
                source: nil
            )
        }


        return IngredientAllergenAssociation(
            ingredientName:
                originalName,
            canonicalIngredientName:
                catalogIngredient.name,
            allergens:
                matchedAllergens,
            state:
                .knownWithAllergens,
            source:
                .system
        )
    }


    // MARK: - Build Open Food Facts Association

    private static func buildOpenFoodFactsAssociation(
        originalName: String,
        result: OpenFoodFactsResult
    ) async throws
        -> IngredientAllergenAssociation {

        let availableAllergens =
            try await DietaryService
                .fetchAllergens()

        let normalizedOFFAllergens =
            Set(
                (
                    result.allergens +
                    result.traces
                )
                .compactMap {
                    canonicalAllergenName(
                        fromExternalName:
                            $0
                    )
                }
            )

        let matchedAllergens =
            availableAllergens
                .filter { allergen in

                    normalizedOFFAllergens
                        .contains(
                            allergen.name
                        )
                }
                .sorted {
                    $0.name
                        .localizedCaseInsensitiveCompare(
                            $1.name
                        )
                        == .orderedAscending
                }


        if !matchedAllergens.isEmpty {

            return IngredientAllergenAssociation(
                ingredientName:
                    originalName,
                canonicalIngredientName:
                    result.productName,
                allergens:
                    matchedAllergens,
                state:
                    .knownWithAllergens,
                source:
                    .openFoodFacts
            )
        }


        // Missing OFF allergen data must never
        // automatically mean "safe".

        switch result.dataState {

        case .available,
             .incomplete:

            return IngredientAllergenAssociation(
                ingredientName:
                    originalName,
                canonicalIngredientName:
                    result.productName,
                allergens: [],
                state:
                    .unknown,
                source:
                    .openFoodFacts
            )

        case .unknown:

            return IngredientAllergenAssociation(
                ingredientName:
                    originalName,
                canonicalIngredientName:
                    result.productName,
                allergens: [],
                state:
                    .unknown,
                source: nil
            )
        }
    }


    // MARK: - Delete Automatic Associations

    private static func deleteAutomaticAssociations(
        ingredientId: UUID
    ) async throws {

        try await SupabaseManager.client
            .from(
                "ingredient_allergens"
            )
            .delete()
            .eq(
                "ingredient_id",
                value:
                    ingredientId
            )
            .in(
                "source",
                values: [
                    IngredientAllergenSource
                        .system
                        .rawValue,

                    IngredientAllergenSource
                        .openFoodFacts
                        .rawValue
                ]
            )
            .execute()
    }


    // MARK: - Update Classification Version

    private static func updateClassificationVersion(
        ingredientId: UUID,
        version: Int
    ) async throws {

        let payload =
            IngredientClassificationVersionUpdate(
                allergenClassificationVersion:
                    version
            )

        try await SupabaseManager.client
            .from(
                "recipe_ingredients"
            )
            .update(
                payload
            )
            .eq(
                "id",
                value:
                    ingredientId
            )
            .execute()
    }


    // MARK: - Aggregate Recipe Results

    private static func aggregateRecipeResults(
        _ results:
            [IngredientAllergenAssociation]
    ) -> RecipeAllergenAssociationResult {

        var allergensById:
            [UUID: Allergen] = [:]

        var allergenSources:
            [UUID: [String]] = [:]

        var unknownIngredients:
            [String] = []

        var knownWithoutMappings:
            [String] = []


        for result in results {

            switch result.state {

            case .knownWithAllergens:

                for allergen in
                    result.allergens {

                    allergensById[
                        allergen.id
                    ] = allergen

                    allergenSources[
                        allergen.id,
                        default: []
                    ]
                    .append(
                        result.ingredientName
                    )
                }


            case .knownNoMappedAllergens:

                knownWithoutMappings.append(
                    result.ingredientName
                )


            case .unknown:

                unknownIngredients.append(
                    result.ingredientName
                )
            }
        }


        let associations =
            allergensById.values
                .sorted {
                    $0.name
                        .localizedCaseInsensitiveCompare(
                            $1.name
                        )
                        == .orderedAscending
                }
                .map { allergen in

                    AllergenSourceAssociation(
                        allergen:
                            allergen,
                        ingredientNames:
                            uniqueStrings(
                                allergenSources[
                                    allergen.id
                                ] ?? []
                            )
                    )
                }


        return RecipeAllergenAssociationResult(
            ingredientResults:
                results,
            allergenAssociations:
                associations,
            unknownIngredients:
                uniqueStrings(
                    unknownIngredients
                ),
            knownIngredientsWithoutMappedAllergens:
                uniqueStrings(
                    knownWithoutMappings
                )
        )
    }


    // MARK: - External Allergen Normalization

    private static func canonicalAllergenName(
        fromExternalName value: String
    ) -> String? {

        let normalized =
            normalizeIngredientName(
                value
            )

        switch normalized {

        case "milk",
             "dairy",
             "lait":

            return "Milk"


        case "egg",
             "eggs",
             "oeuf",
             "oeufs":

            return "Egg"


        case "peanut",
             "peanuts",
             "groundnut",
             "groundnuts",
             "arachide",
             "arachides":

            return "Peanut"


        case "soy",
             "soya",
             "soybean",
             "soybeans",
             "soja":

            return "Soy"


        case "sesame",
             "sesame seeds":

            return "Sesame"


        case "fish":

            return "Fish"


        case "shellfish",
             "crustaceans",
             "crustacean":

            return "Shellfish"


        case "tree nut",
             "tree nuts",
             "nut",
             "nuts",
             "almond",
             "almonds",
             "hazelnut",
             "hazelnuts",
             "walnut",
             "walnuts",
             "cashew",
             "cashews",
             "pecan",
             "pecans",
             "pistachio",
             "pistachios",
             "macadamia",
             "brazil nut",
             "brazil nuts",
             "fruits a coque":

            return "Tree Nut"


        case "wheat",
             "ble":

            return "Wheat"


        default:

            // Gluten is deliberately not converted
            // directly into Wheat.

            return nil
        }
    }


    // MARK: - Normalization

    static func normalizeIngredientName(
        _ value: String
    ) -> String {

        value
            .folding(
                options: [
                    .diacriticInsensitive,
                    .caseInsensitive
                ],
                locale:
                    Locale(
                        identifier:
                            "en_US_POSIX"
                    )
            )
            .lowercased()
            .replacingOccurrences(
                of: "-",
                with: " "
            )
            .trimmingCharacters(
                in:
                    .whitespacesAndNewlines
            )
            .split(
                whereSeparator: {
                    $0.isWhitespace
                }
            )
            .joined(
                separator: " "
            )
    }


    // MARK: - Optional String

    private static func cleanedOptionalString(
        _ value: String?
    ) -> String? {

        guard let value else {
            return nil
        }

        let cleaned =
            value.trimmingCharacters(
                in:
                    .whitespacesAndNewlines
            )

        return cleaned.isEmpty
            ? nil
            : cleaned
    }


    // MARK: - Unique Strings

    private static func uniqueStrings(
        _ values: [String]
    ) -> [String] {

        var seen:
            Set<String> = []

        return values.filter { value in

            let key =
                normalizeIngredientName(
                    value
                )

            guard !key.isEmpty else {
                return false
            }

            return seen
                .insert(
                    key
                )
                .inserted
        }
    }
}


// MARK: - Input

struct IngredientAllergenInput:
    Hashable {

    let id: UUID?

    let name: String

    let offProductId: String?


    init(
        id: UUID? = nil,
        name: String,
        offProductId: String? = nil
    ) {

        self.id = id

        self.name = name

        self.offProductId =
            offProductId
    }
}


// MARK: - Ingredient Association

struct IngredientAllergenAssociation:
    Identifiable,
    Hashable {

    let id = UUID()

    let ingredientName:
        String

    let canonicalIngredientName:
        String?

    let allergens:
        [Allergen]

    let state:
        IngredientAllergenState

    let source:
        IngredientAllergenSource?


    var isKnown: Bool {

        switch state {

        case .knownWithAllergens,
             .knownNoMappedAllergens:

            return true

        case .unknown:

            return false
        }
    }


    var hasMappedAllergens: Bool {

        state ==
            .knownWithAllergens
    }
}


// MARK: - Allergen Source Association

struct AllergenSourceAssociation:
    Identifiable,
    Hashable {

    var id: UUID {
        allergen.id
    }

    let allergen:
        Allergen

    let ingredientNames:
        [String]
}


// MARK: - Recipe Result

struct RecipeAllergenAssociationResult:
    Hashable {

    let ingredientResults:
        [IngredientAllergenAssociation]

    let allergenAssociations:
        [AllergenSourceAssociation]

    let unknownIngredients:
        [String]

    let knownIngredientsWithoutMappedAllergens:
        [String]


    var allergens:
        [Allergen] {

        allergenAssociations.map(
            \.allergen
        )
    }


    var hasKnownAllergens: Bool {

        !allergenAssociations.isEmpty
    }


    var hasUnknownIngredients: Bool {

        !unknownIngredients.isEmpty
    }
}


// MARK: - State

enum IngredientAllergenState:
    String,
    Codable,
    Hashable {

    case knownWithAllergens

    case knownNoMappedAllergens

    case unknown
}


// MARK: - Source

enum IngredientAllergenSource:
    String,
    Codable,
    Hashable {

    case user

    case openFoodFacts =
        "open_food_facts"

    case system
}


// MARK: - Supabase Records

private struct IngredientCatalogRecord:
    Decodable {

    let id: UUID

    let name: String

    let normalizedName: String


    enum CodingKeys:
        String,
        CodingKey {

        case id

        case name

        case normalizedName =
            "normalized_name"
    }
}


private struct IngredientAliasLookup:
    Decodable {

    let ingredientId: UUID


    enum CodingKeys:
        String,
        CodingKey {

        case ingredientId =
            "ingredient_id"
    }
}


private struct IngredientCatalogAllergenLookup:
    Decodable {

    let allergenId: UUID


    enum CodingKeys:
        String,
        CodingKey {

        case allergenId =
            "allergen_id"
    }
}


private struct IngredientAllergenInsert:
    Encodable {

    let ingredientId: UUID

    let allergenId: UUID

    let source: String


    enum CodingKeys:
        String,
        CodingKey {

        case ingredientId =
            "ingredient_id"

        case allergenId =
            "allergen_id"

        case source
    }
}


private struct AllergenCatalogMetadata:
    Decodable {

    let currentVersion:
        Int


    enum CodingKeys:
        String,
        CodingKey {

        case currentVersion =
            "current_version"
    }
}


private struct IngredientClassificationVersionUpdate:
    Encodable {

    let allergenClassificationVersion:
        Int


    enum CodingKeys:
        String,
        CodingKey {

        case allergenClassificationVersion =
            "allergen_classification_version"
    }
}

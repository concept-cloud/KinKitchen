//
//  CookbookService.swift
//  KinKitchen
//
//  Created by Greg Hudler on 9/23/26.
//

import Foundation
import Supabase

enum CookbookService {

    // MARK: - Create Cookbook

    static func createCookbook(
        name: String,
        description: String? = nil,
        coverPath: String? = nil
    ) async throws -> Cookbook {

        let user =
            try await SupabaseManager.client
                .auth
                .session
                .user

        let cleanName =
            name.trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        guard !cleanName.isEmpty else {
            throw CookbookServiceError.invalidName
        }

        let payload =
            CookbookCreate(
                ownerId: user.id,
                name: cleanName,
                description:
                    cleanedOptionalString(
                        description
                    ),
                coverPath:
                    cleanedOptionalString(
                        coverPath
                    ),
                visibility: .private
            )

        let cookbook: Cookbook =
            try await SupabaseManager.client
                .from("cookbooks")
                .insert(payload)
                .select()
                .single()
                .execute()
                .value

        return cookbook
    }

    // MARK: - Fetch Current User Cookbooks

    static func fetchCurrentUserCookbooks()
        async throws -> [Cookbook] {

        let user =
            try await SupabaseManager.client
                .auth
                .session
                .user

        let cookbooks: [Cookbook] =
            try await SupabaseManager.client
                .from("cookbooks")
                .select()
                .eq(
                    "owner_id",
                    value: user.id
                )
                .eq(
                    "visibility",
                    value: CookbookVisibility.private.rawValue
                )
                .order(
                    "updated_at",
                    ascending: false
                )
                .execute()
                .value

        return cookbooks
    }

    // MARK: - Fetch Cookbook

    static func fetchCookbook(
        id cookbookId: UUID
    ) async throws -> Cookbook {

        let user =
            try await SupabaseManager.client
                .auth
                .session
                .user

        let cookbooks: [Cookbook] =
            try await SupabaseManager.client
                .from("cookbooks")
                .select()
                .eq(
                    "id",
                    value: cookbookId
                )
                .eq(
                    "owner_id",
                    value: user.id
                )
                .eq(
                    "visibility",
                    value: CookbookVisibility.private.rawValue
                )
                .limit(1)
                .execute()
                .value

        guard let cookbook = cookbooks.first else {
            throw CookbookServiceError.cookbookNotFound
        }

        return cookbook
    }

    // MARK: - Update Cookbook

    static func updateCookbook(
        id cookbookId: UUID,
        name: String,
        description: String?,
        coverPath: String?
    ) async throws -> Cookbook {

        let user =
            try await SupabaseManager.client
                .auth
                .session
                .user

        let cleanName =
            name.trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        guard !cleanName.isEmpty else {
            throw CookbookServiceError.invalidName
        }

        let payload =
            CookbookUpdate(
                name: cleanName,
                description:
                    cleanedOptionalString(
                        description
                    ),
                coverPath:
                    cleanedOptionalString(
                        coverPath
                    )
            )

        let cookbook: Cookbook =
            try await SupabaseManager.client
                .from("cookbooks")
                .update(payload)
                .eq(
                    "id",
                    value: cookbookId
                )
                .eq(
                    "owner_id",
                    value: user.id
                )
                .select()
                .single()
                .execute()
                .value

        return cookbook
    }

    // MARK: - Delete Cookbook

    /// Deletes a cookbook the user owns along with its sections and
    /// recipe links, in one database transaction (see
    /// supabase/KINKIT-182). Recipes are never deleted.
    static func deleteCookbook(
        id cookbookId: UUID
    ) async throws {

        let result: CookbookDeletionResult =
            try await SupabaseManager.client
                .rpc(
                    "delete_cookbook",
                    params: ["p_cookbook_id": cookbookId]
                )
                .execute()
                .value

        // The cookbook is already gone; a leftover cover file
        // shouldn't turn a successful delete into an error.
        if let coverPath = result.coverPath,
           !coverPath.isEmpty {
            _ = try? await SupabaseManager.client.storage
                .from("cookbook-covers")
                .remove(paths: [coverPath])
        }
    }

    // MARK: - Add Recipe

    static func addRecipe(
        recipeId: UUID,
        to cookbookId: UUID
    ) async throws -> CookbookRecipe {

        // New recipes go to the end of Unsorted.
        let existing =
            try await fetchRecipeRelationships(
                cookbookId: cookbookId
            )

        let payload =
            CookbookRecipeCreate(
                cookbookId: cookbookId,
                recipeId: recipeId,
                sortOrder:
                    nextSortOrder(
                        in: nil,
                        relationships: existing
                    )
            )

        let relationship: CookbookRecipe =
            try await SupabaseManager.client
                .from("cookbook_recipes")
                .insert(payload)
                .select()
                .single()
                .execute()
                .value

        return relationship
    }

    // MARK: - Remove Recipe

    static func removeRecipe(
        recipeId: UUID,
        from cookbookId: UUID
    ) async throws {

        _ =
            try await fetchCookbook(
                id: cookbookId
            )

        try await SupabaseManager.client
            .from("cookbook_recipes")
            .delete()
            .eq(
                "cookbook_id",
                value: cookbookId
            )
            .eq(
                "recipe_id",
                value: recipeId
            )
            .execute()
    }

    // MARK: - Fetch Recipe Relationships

    static func fetchRecipeRelationships(
        cookbookId: UUID
    ) async throws -> [CookbookRecipe] {

        _ =
            try await fetchCookbook(
                id: cookbookId
            )

        let relationships: [CookbookRecipe] =
            try await SupabaseManager.client
                .from("cookbook_recipes")
                .select()
                .eq(
                    "cookbook_id",
                    value: cookbookId
                )
                .order(
                    "sort_order",
                    ascending: true
                )
                .execute()
                .value

        return relationships
    }

    // MARK: - Fetch Cookbook Recipes

    static func fetchRecipes(
        cookbookId: UUID
    ) async throws -> [Recipe] {

        let relationships =
            try await fetchRecipeRelationships(
                cookbookId: cookbookId
            )

        var recipes: [Recipe] = []

        for relationship in relationships {
            let recipe =
                try await RecipeService.fetchRecipe(
                    id: relationship.recipeId
                )

            recipes.append(recipe)
        }

        return recipes
    }

    // MARK: - Fetch Cookbook Contents

    /// Recipe relationships in saved order plus the recipes they point
    /// at, loaded in one request. Recipes that no longer exist are
    /// simply missing from `recipesById`.
    static func fetchContents(
        cookbookId: UUID
    ) async throws -> (
        relationships: [CookbookRecipe],
        recipesById: [UUID: Recipe]
    ) {

        let relationships =
            try await fetchRecipeRelationships(
                cookbookId: cookbookId
            )

        let recipes =
            try await RecipeService.fetchRecipes(
                ids: relationships.map(\.recipeId)
            )

        return (
            relationships,
            Dictionary(
                uniqueKeysWithValues:
                    recipes.map { ($0.id, $0) }
            )
        )
    }

    // MARK: - Sections

    static func fetchSections(
        cookbookId: UUID
    ) async throws -> [CookbookSection] {

        _ =
            try await fetchCookbook(
                id: cookbookId
            )

        let sections: [CookbookSection] =
            try await SupabaseManager.client
                .from("cookbook_sections")
                .select()
                .eq(
                    "cookbook_id",
                    value: cookbookId
                )
                .order(
                    "sort_order",
                    ascending: true
                )
                .execute()
                .value

        return sections
    }

    /// Adds a section at the end of the cookbook's sections.
    static func createSection(
        name: String,
        in cookbookId: UUID,
        after existingSections: [CookbookSection]
    ) async throws -> CookbookSection {

        let cleanName =
            try validatedSectionName(name)

        _ =
            try await fetchCookbook(
                id: cookbookId
            )

        let section: CookbookSection =
            try await SupabaseManager.client
                .from("cookbook_sections")
                .insert(
                    CookbookSectionCreate(
                        cookbookId: cookbookId,
                        name: cleanName,
                        sortOrder:
                            (existingSections
                                .map(\.sortOrder)
                                .max() ?? -1) + 1
                    )
                )
                .select()
                .single()
                .execute()
                .value

        return section
    }

    static func renameSection(
        _ section: CookbookSection,
        to name: String
    ) async throws -> CookbookSection {

        let cleanName =
            try validatedSectionName(name)

        let updated: CookbookSection =
            try await SupabaseManager.client
                .from("cookbook_sections")
                .update(
                    ["name": cleanName]
                )
                .eq(
                    "id",
                    value: section.id
                )
                .select()
                .single()
                .execute()
                .value

        return updated
    }

    /// Saves section order as explicit positions 0, 1, 2… Recipes keep
    /// their section; only the section's `sort_order` changes.
    static func reorderSections(
        _ orderedSectionIds: [UUID],
        cookbookId: UUID
    ) async throws {

        _ =
            try await fetchCookbook(
                id: cookbookId
            )

        for (position, sectionId) in
            orderedSectionIds.enumerated() {

            try await SupabaseManager.client
                .from("cookbook_sections")
                .update(
                    ["sort_order": position]
                )
                .eq(
                    "id",
                    value: sectionId
                )
                .eq(
                    "cookbook_id",
                    value: cookbookId
                )
                .execute()
        }
    }

    /// Deletes the section only. Its recipes stay in the cookbook as
    /// Unsorted (the database clears their section_id).
    static func deleteSection(
        _ section: CookbookSection
    ) async throws {

        try await SupabaseManager.client
            .from("cookbook_sections")
            .delete()
            .eq(
                "id",
                value: section.id
            )
            .execute()
    }

    // MARK: - Move Recipe To Section

    /// Moves a cookbook recipe into a section (nil = Unsorted),
    /// placing it at the end of that section. Only the cookbook
    /// relationship changes, never the recipe.
    static func moveRecipe(
        recipeId: UUID,
        in cookbookId: UUID,
        to sectionId: UUID?,
        relationships: [CookbookRecipe]
    ) async throws {

        _ =
            try await fetchCookbook(
                id: cookbookId
            )

        let sortOrder =
            nextSortOrder(
                in: sectionId,
                relationships:
                    relationships.filter {
                        $0.recipeId != recipeId
                    }
            )

        try await SupabaseManager.client
            .from("cookbook_recipes")
            .update(
                CookbookRecipePlacement(
                    sectionId: sectionId,
                    sortOrder: sortOrder
                )
            )
            .eq(
                "cookbook_id",
                value: cookbookId
            )
            .eq(
                "recipe_id",
                value: recipeId
            )
            .execute()
    }

    // MARK: - Featured Recipes

    /// Features or un-features a recipe for the cookbook preview.
    /// Up to 3 per section; the database enforces the same limit.
    static func setFeatured(
        _ isFeatured: Bool,
        recipeId: UUID,
        in cookbookId: UUID,
        relationships: [CookbookRecipe]
    ) async throws {

        if isFeatured {
            let sectionId =
                relationships
                    .first { $0.recipeId == recipeId }?
                    .sectionId

            guard
                CookbookRecipe.canFeature(
                    in: sectionId,
                    relationships:
                        relationships.filter {
                            $0.recipeId != recipeId
                        }
                )
            else {
                throw CookbookServiceError.featuredLimitReached
            }
        }

        _ =
            try await fetchCookbook(
                id: cookbookId
            )

        do {
            try await SupabaseManager.client
                .from("cookbook_recipes")
                .update(
                    ["is_featured": isFeatured]
                )
                .eq(
                    "cookbook_id",
                    value: cookbookId
                )
                .eq(
                    "recipe_id",
                    value: recipeId
                )
                .execute()
        } catch {
            if String(describing: error)
                .contains("FEATURED_LIMIT") {
                throw CookbookServiceError.featuredLimitReached
            }
            throw error
        }
    }

    // MARK: - Reorder Recipes

    /// Saves the order of recipes within one section (nil = Unsorted)
    /// as explicit positions 0, 1, 2… Only `sort_order` on the
    /// cookbook relationship changes.
    static func reorderRecipes(
        _ orderedRecipeIds: [UUID],
        in sectionId: UUID?,
        cookbookId: UUID
    ) async throws {

        _ =
            try await fetchCookbook(
                id: cookbookId
            )

        for (position, recipeId) in
            orderedRecipeIds.enumerated() {

            try await SupabaseManager.client
                .from("cookbook_recipes")
                .update(
                    CookbookRecipePlacement(
                        sectionId: sectionId,
                        sortOrder: position
                    )
                )
                .eq(
                    "cookbook_id",
                    value: cookbookId
                )
                .eq(
                    "recipe_id",
                    value: recipeId
                )
                .execute()
        }
    }

    /// The new order after a drag, using the same rules as SwiftUI's
    /// list move.
    static func reordered(
        _ ids: [UUID],
        moving offsets: IndexSet,
        to destination: Int
    ) -> [UUID] {

        // Pull out the moved items, then insert them where the drop
        // lands once the items above it are accounted for.
        let moved =
            offsets.map { ids[$0] }

        var remaining =
            ids.enumerated()
                .filter { !offsets.contains($0.offset) }
                .map(\.element)

        let insertAt =
            destination
                - offsets.filter { $0 < destination }.count

        remaining.insert(
            contentsOf: moved,
            at: min(max(insertAt, 0), remaining.count)
        )

        return remaining
    }

    /// One past the highest position in a section, so a moved
    /// recipe lands at the end.
    static func nextSortOrder(
        in sectionId: UUID?,
        relationships: [CookbookRecipe]
    ) -> Int {

        (relationships
            .filter { $0.sectionId == sectionId }
            .map(\.sortOrder)
            .max() ?? -1) + 1
    }

    /// Trimmed name, or throws if it's empty or too long.
    static func validatedSectionName(
        _ name: String
    ) throws -> String {

        let cleanName =
            name.trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        guard !cleanName.isEmpty else {
            throw CookbookServiceError.invalidSectionName
        }

        guard
            cleanName.count <= CookbookSection.maxNameLength
        else {
            throw CookbookServiceError.sectionNameTooLong
        }

        return cleanName
    }

    // MARK: - Cookbook Cover

    static func uploadCookbookCover(
        cookbookId: UUID,
        imageData: Data
    ) async throws -> String {

        _ =
            try await fetchCookbook(
                id: cookbookId
            )

        let user =
            try await SupabaseManager.client
                .auth
                .session
                .user

        let path =
            "\(user.id.uuidString.lowercased())/\(cookbookId.uuidString.lowercased())/cover.jpg"

        try await SupabaseManager.client.storage
            .from("cookbook-covers")
            .upload(
                path,
                data: imageData,
                options: FileOptions(
                    contentType: "image/jpeg",
                    upsert: true
                )
            )

        return path
    }

    static func fetchCookbookCover(
        path: String
    ) async throws -> Data {

        try await SupabaseManager.client.storage
            .from("cookbook-covers")
            .download(
                path: path
            )
    }

    static func replaceCookbookCover(
        cookbook: Cookbook,
        imageData: Data
    ) async throws -> Cookbook {

        let path =
            try await uploadCookbookCover(
                cookbookId: cookbook.id,
                imageData: imageData
            )

        return try await updateCookbook(
            id: cookbook.id,
            name: cookbook.name,
            description: cookbook.description,
            coverPath: path
        )
    }
    
    // MARK: - Optional String Cleanup

    private static func cleanedOptionalString(
        _ value: String?
    ) -> String? {

        guard let value else {
            return nil
        }

        let cleaned =
            value.trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        return cleaned.isEmpty
            ? nil
            : cleaned
    }
}

// MARK: - Cookbook Deletion Result

/// What `delete_cookbook` returns.
private struct CookbookDeletionResult: Decodable {

    let coverPath: String?

    enum CodingKeys: String, CodingKey {
        case coverPath = "cover_path"
    }
}

// MARK: - Cookbook Service Error

enum CookbookServiceError: LocalizedError {
    case invalidName
    case cookbookNotFound
    case invalidSectionName
    case sectionNameTooLong
    case featuredLimitReached

    var errorDescription: String? {
        switch self {
        case .invalidName:
            return "Cookbook name cannot be empty."

        case .cookbookNotFound:
            return "Cookbook could not be found."

        case .invalidSectionName:
            return "Please enter a section name."

        case .sectionNameTooLong:
            return "Section names can be up to \(CookbookSection.maxNameLength) characters."

        case .featuredLimitReached:
            return "Each section can feature up to \(CookbookRecipe.maxFeaturedPerSection) recipes. Remove one from the preview first."
        }
    }
}

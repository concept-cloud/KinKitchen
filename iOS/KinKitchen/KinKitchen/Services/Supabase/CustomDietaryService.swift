//
//  CustomDietaryService.swift
//  KinKitchen
//
//  Created by Greg Hudler on 10/14/26.
//

import Foundation
import Supabase

/// Allergens, restrictions and preferences users add themselves
/// (`custom_dietary_items`). Having one means it's on; removing it
/// deletes it.
enum CustomDietaryService {

    private struct NewItem: Encodable {
        let kind: CustomDietaryItem.Kind
        let name: String
    }

    /// Defaults to the signed-in user.
    static func fetchItems(
        for userId: UUID? = nil
    ) async throws -> CustomDietaryItems {

        let ownerId: UUID
        if let userId {
            ownerId = userId
        } else {
            ownerId = try await SupabaseManager.client.auth.session.user.id
        }

        let items: [CustomDietaryItem] =
            try await SupabaseManager.client
                .from("custom_dietary_items")
                .select()
                .eq("user_id", value: ownerId)
                .order("name")
                .execute()
                .value

        return CustomDietaryItems(items)
    }

    static func add(
        _ kind: CustomDietaryItem.Kind,
        name: String
    ) async throws {

        try await SupabaseManager.client
            .from("custom_dietary_items")
            .insert(
                NewItem(
                    kind: kind,
                    name: CustomDietaryText.cleaned(name)
                )
            )
            .execute()
    }

    static func remove(
        _ id: UUID
    ) async throws {

        try await SupabaseManager.client
            .from("custom_dietary_items")
            .delete()
            .eq("id", value: id)
            .execute()
    }
}


/// Tidying what the user typed.
nonisolated enum CustomDietaryText {

    static let maxLength = 40

    /// Trimmed, single-spaced, first letter capitalized, at most
    /// 40 characters: "  tree   nuts " → "Tree nuts".
    static func cleaned(
        _ value: String
    ) -> String {
        let words =
            value
                .split(whereSeparator: \.isWhitespace)
                .joined(separator: " ")
        let trimmed = String(words.prefix(maxLength))
        return trimmed.prefix(1).uppercased() + trimmed.dropFirst()
    }

    /// True when `name` is already in the list (ignoring case and
    /// spacing), so it can be selected instead of added twice.
    static func existingMatch(
        for name: String,
        in names: [String]
    ) -> String? {
        let key = CustomDietaryMatcher.normalize(name)
        return names.first { CustomDietaryMatcher.normalize($0) == key }
    }
}

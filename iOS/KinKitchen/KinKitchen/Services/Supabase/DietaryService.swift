//
//  DietaryService.swift
//  KinKitchen
//
//  Created by Greg Hudler on 8/28/26.
//

import Foundation
import Supabase

enum DietaryService {

    static func fetchAllergens() async throws -> [Allergen] {
        try await SupabaseManager.client
            .from("allergens")
            .select()
            .order("name")
            .execute()
            .value
    }

    static func fetchSelectedAllergens() async throws -> [UUID] {
        let user = try await SupabaseManager.client.auth.session.user

        let selections: [UserAllergenSelection] = try await SupabaseManager.client
            .from("user_allergens")
            .select()
            .eq("user_id", value: user.id)
            .execute()
            .value

        return selections.map(\.allergenId)
    }

    static func addAllergen(_ allergenId: UUID) async throws {
        let user = try await SupabaseManager.client.auth.session.user

        let selection = UserAllergenSelection(
            userId: user.id,
            allergenId: allergenId
        )

        try await SupabaseManager.client
            .from("user_allergens")
            .insert(selection)
            .execute()
    }

    static func removeAllergen(_ allergenId: UUID) async throws {
        let user = try await SupabaseManager.client.auth.session.user

        try await SupabaseManager.client
            .from("user_allergens")
            .delete()
            .eq("user_id", value: user.id)
            .eq("allergen_id", value: allergenId)
            .execute()
    }
}

private struct UserAllergenSelection: Codable {
    let userId: UUID
    let allergenId: UUID

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case allergenId = "allergen_id"
    }
}

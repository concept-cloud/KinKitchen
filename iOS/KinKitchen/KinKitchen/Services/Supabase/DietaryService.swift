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
    
    static func fetchDietaryRestrictions() async throws -> [DietaryRestriction] {
        try await SupabaseManager.client
            .from("dietary_restrictions")
            .select()
            .order("name")
            .execute()
            .value
    }

    static func fetchSelectedDietaryRestrictions() async throws -> [UUID] {
        let user = try await SupabaseManager.client.auth.session.user

        let selections: [UserDietaryRestrictionSelection] = try await SupabaseManager.client
            .from("user_dietary_restrictions")
            .select()
            .eq("user_id", value: user.id)
            .execute()
            .value

        return selections.map(\.restrictionId)
    }

    static func addDietaryRestriction(_ restrictionId: UUID) async throws {
        let user = try await SupabaseManager.client.auth.session.user

        let selection = UserDietaryRestrictionSelection(
            userId: user.id,
            restrictionId: restrictionId
        )

        try await SupabaseManager.client
            .from("user_dietary_restrictions")
            .insert(selection)
            .execute()
    }

    static func removeDietaryRestriction(_ restrictionId: UUID) async throws {
        let user = try await SupabaseManager.client.auth.session.user

        try await SupabaseManager.client
            .from("user_dietary_restrictions")
            .delete()
            .eq("user_id", value: user.id)
            .eq("restriction_id", value: restrictionId)
            .execute()
    }
    
    static func fetchDietaryPreferences() async throws -> [DietaryPreference] {
        try await SupabaseManager.client
            .from("dietary_preferences")
            .select()
            .order("name")
            .execute()
            .value
    }

    static func fetchSelectedDietaryPreferences() async throws -> [UUID] {
        let user = try await SupabaseManager.client.auth.session.user

        let selections: [UserDietaryPreferenceSelection] = try await SupabaseManager.client
            .from("user_dietary_preferences")
            .select()
            .eq("user_id", value: user.id)
            .execute()
            .value

        return selections.map(\.preferenceId)
    }

    static func addDietaryPreference(_ preferenceId: UUID) async throws {
        let user = try await SupabaseManager.client.auth.session.user

        let selection = UserDietaryPreferenceSelection(
            userId: user.id,
            preferenceId: preferenceId
        )

        try await SupabaseManager.client
            .from("user_dietary_preferences")
            .insert(selection)
            .execute()
    }

    static func removeDietaryPreference(_ preferenceId: UUID) async throws {
        let user = try await SupabaseManager.client.auth.session.user

        try await SupabaseManager.client
            .from("user_dietary_preferences")
            .delete()
            .eq("user_id", value: user.id)
            .eq("preference_id", value: preferenceId)
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

private struct UserDietaryRestrictionSelection: Codable {
    let userId: UUID
    let restrictionId: UUID

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case restrictionId = "restriction_id"
    }
}

private struct UserDietaryPreferenceSelection: Codable {
    let userId: UUID
    let preferenceId: UUID

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case preferenceId = "preference_id"
    }
}

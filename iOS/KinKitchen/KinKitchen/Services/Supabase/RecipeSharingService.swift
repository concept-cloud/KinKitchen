//
//  RecipeSharingService.swift
//  KinKitchen
//
//  Created by Greg Hudler on 9/20/26.
//

import Foundation
import Supabase

enum RecipeSharingService {
    static func createShare(
        recipeId: UUID,
        recipientId: UUID
    ) async throws -> RecipeShare {
        let user =
            try await SupabaseManager.client
                .auth
                .session
                .user

        let payload =
            RecipeShareCreate(
                recipeId: recipeId,
                senderId: user.id,
                recipientId: recipientId
            )

        let share: RecipeShare =
            try await SupabaseManager.client
                .from("recipe_shares")
                .insert(payload)
                .select()
                .single()
                .execute()
                .value

        return share
    }

    static func fetchReceivedShares() async throws -> [RecipeShare] {
        let user =
            try await SupabaseManager.client
                .auth
                .session
                .user

        let shares: [RecipeShare] =
            try await SupabaseManager.client
                .from("recipe_shares")
                .select()
                .eq(
                    "recipient_id",
                    value: user.id
                )
                .order(
                    "created_at",
                    ascending: false
                )
                .execute()
                .value

        return shares
    }

    static func fetchSentShares() async throws -> [RecipeShare] {
        let user =
            try await SupabaseManager.client
                .auth
                .session
                .user

        let shares: [RecipeShare] =
            try await SupabaseManager.client
                .from("recipe_shares")
                .select()
                .eq(
                    "sender_id",
                    value: user.id
                )
                .order(
                    "created_at",
                    ascending: false
                )
                .execute()
                .value

        return shares
    }
}

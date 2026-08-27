//
//  AuthService.swift
//  KinKitchen
//
//  Created by Greg Hudler on 8/26/26.
//

import Foundation
import Supabase
import Combine

@MainActor
final class AuthService: ObservableObject {

    static let shared = AuthService()

    @Published private(set) var isAuthenticated = false
    @Published private(set) var currentUser: User?

    private var authTask: Task<Void, Never>?

    private init() {
        currentUser = SupabaseManager.client.auth.currentUser
        isAuthenticated = currentUser != nil

        observeAuthChanges()
    }

    func refreshAuthState() {
        currentUser = SupabaseManager.client.auth.currentUser
        isAuthenticated = currentUser != nil
    }

    private func observeAuthChanges() {
        authTask = Task {
            for await (_, session) in await SupabaseManager.client.auth.authStateChanges {
                self.currentUser = session?.user
                self.isAuthenticated = session != nil && session?.isExpired == false
            }
        }
    }

    deinit {
        authTask?.cancel()
    }
}

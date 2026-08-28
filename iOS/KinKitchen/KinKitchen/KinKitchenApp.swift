//
//  KinKitchenApp.swift
//  KinKitchen
//
//  Created by Greg Hudler on 8/26/26.
//

import SwiftUI

@main
struct KinKitchenApp: App {
    @StateObject private var authService = AuthService.shared

    var body: some Scene {
        WindowGroup {
            Group {
                if authService.isAuthenticated {
                    ContentView()
                } else {
                    SignInView()
                }
            }
            .preferredColorScheme(.light)
        }
    }
}

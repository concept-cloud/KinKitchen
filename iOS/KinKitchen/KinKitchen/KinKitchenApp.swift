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

    @State private var isProfileComplete: Bool?
    @State private var isCheckingProfile = false

    var body: some Scene {
        WindowGroup {
            Group {
                if authService.isLoadingSession {
                    ProgressView()

                } else if !authService.isAuthenticated {
                    SignInView()

                } else if isCheckingProfile {
                    ProgressView()

                } else if let isProfileComplete {
                    if isProfileComplete {
                        ContentView()
                    } else {
                        profileSetupRequiredView
                    }

                } else {
                    ProgressView()
                }
            }
            .preferredColorScheme(.light)
            .task(id: authService.isAuthenticated) {
                guard authService.isAuthenticated else {
                    isProfileComplete = nil
                    return
                }

                await checkProfileCompletion()
            }
        }
    }

    private var profileSetupRequiredView: some View {
        VStack(spacing: KinSpacing.large) {
            Text("Complete Your Profile")
                .font(KinTypography.largeTitle)
                .foregroundStyle(KinColors.primaryText)

            Text(
                "Your profile must be completed before continuing to Kin Kitchen."
            )
            .font(KinTypography.body)
            .foregroundStyle(KinColors.secondaryText)
            .multilineTextAlignment(.center)
        }
        .padding(KinSpacing.xLarge)
        .frame(
            maxWidth: .infinity,
            maxHeight: .infinity
        )
        .background(KinColors.background)
    }

    @MainActor
    private func checkProfileCompletion() async {
        isCheckingProfile = true

        defer {
            isCheckingProfile = false
        }

        do {
            isProfileComplete =
                try await ProfileService.isCurrentProfileComplete()

            print(
                "PROFILE CHECK:",
                isProfileComplete == true ? "COMPLETE" : "INCOMPLETE"
            )

        } catch {
            isProfileComplete = false

            print(
                "PROFILE CHECK ERROR:",
                error.localizedDescription
            )
        }
    }
}

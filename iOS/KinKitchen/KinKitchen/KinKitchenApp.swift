//
//  KinKitchenApp.swift
//  KinKitchen
//
//  Created by Greg Hudler on 8/26/26.
//

import SwiftUI

@main
struct KinKitchenApp: App {

    enum OnboardingStep {
        case checking
        case profile
        case dietaryRestrictions
        case dietaryPreferences
        case complete
    }

    @StateObject private var authService =
        AuthService.shared

    @State private var onboardingStep:
        OnboardingStep = .checking

    var body: some Scene {

        WindowGroup {

            Group {

                if authService.isLoadingSession {

                    ProgressView()

                } else if !authService.isAuthenticated {

                    SignInView()

                } else {

                    authenticatedContent
                }
            }
            .preferredColorScheme(.light)
            .task(id: authService.isAuthenticated) {

                guard authService.isAuthenticated else {

                    onboardingStep = .checking
                    return
                }

                await checkOnboardingStatus()
            }
        }
    }

    // MARK: - Authenticated Routing

    @ViewBuilder
    private var authenticatedContent: some View {

        switch onboardingStep {

        case .checking:

            ProgressView()

        case .profile:

            ProfileSetupView {

                Task {
                    await profileSetupCompleted()
                }
            }

        case .dietaryRestrictions:

            DietaryRestrictionsSetupView {

                onboardingStep =
                    .dietaryPreferences
            }

        case .dietaryPreferences:

            DietaryPreferencesSetupView {

                Task {
                    await dietarySetupCompleted()
                }
            }

        case .complete:

            ContentView()
        }
    }

    // MARK: - Check Onboarding Status

    @MainActor
    private func checkOnboardingStatus() async {

        onboardingStep = .checking

        do {

            let isProfileComplete =
                try await ProfileService
                    .isCurrentProfileComplete()

            print(
                "PROFILE CHECK:",
                isProfileComplete
                    ? "COMPLETE"
                    : "INCOMPLETE"
            )

            guard isProfileComplete else {

                onboardingStep = .profile
                return
            }

            let isDietarySetupComplete =
                try await ProfileService
                    .isDietarySetupComplete()

            print(
                "DIETARY SETUP CHECK:",
                isDietarySetupComplete
                    ? "COMPLETE"
                    : "INCOMPLETE"
            )

            guard isDietarySetupComplete else {

                onboardingStep =
                    .dietaryRestrictions

                return
            }

            let isDietaryReviewDue =
                try await ProfileService
                    .isDietaryReviewDue()

            print(
                "DIETARY REVIEW:",
                isDietaryReviewDue
                    ? "DUE"
                    : "CURRENT"
            )

            if isDietaryReviewDue {

                onboardingStep =
                    .dietaryRestrictions

            } else {

                onboardingStep =
                    .complete
            }

        } catch {

            onboardingStep = .profile

            print(
                "ONBOARDING CHECK ERROR:",
                error.localizedDescription
            )
        }
    }

    // MARK: - Profile Setup Completed

    @MainActor
    private func profileSetupCompleted() async {

        do {

            let isProfileComplete =
                try await ProfileService
                    .isCurrentProfileComplete()

            guard isProfileComplete else {

                onboardingStep = .profile

                print(
                    "PROFILE CHECK: INCOMPLETE"
                )

                return
            }

            print(
                "PROFILE CHECK: COMPLETE"
            )

            onboardingStep =
                .dietaryRestrictions

        } catch {

            onboardingStep = .profile

            print(
                "PROFILE COMPLETION ERROR:",
                error.localizedDescription
            )
        }
    }

    // MARK: - Dietary Setup Completed

    @MainActor
    private func dietarySetupCompleted() async {

        do {

            try await ProfileService
                .markDietarySetupReviewed()

            print(
                "DIETARY SETUP: COMPLETE"
            )

            onboardingStep = .complete

        } catch {

            print(
                "DIETARY SETUP COMPLETION ERROR:",
                error.localizedDescription
            )
        }
    }
}

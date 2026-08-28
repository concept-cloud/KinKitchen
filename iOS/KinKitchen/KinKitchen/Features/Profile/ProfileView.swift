//
//  ProfileView.swift
//  KinKitchen
//
//  Created by Greg Hudler on 8/26/26.
//

import SwiftUI



struct ProfileView: View {
    
    @State private var profile: Profile?
    @State private var errorMessage: String?
    @State private var isLoading = true
    
    
    var body: some View {
        ScrollView {
            VStack(spacing: KinSpacing.xLarge) {

                // Profile Photo
                ZStack {
                    Circle()
                        .fill(KinColors.surface)
                        .frame(width: 120, height: 120)

                    Image(systemName: KinIcons.profile)
                        .font(.system(size: 48))
                        .foregroundStyle(KinColors.secondaryText)
                }

                // Identity
                VStack(spacing: KinSpacing.small) {
                    Text(profile?.displayName ?? "Display Name")
                        .font(KinTypography.largeTitle)
                        .foregroundStyle(KinColors.primaryText)

                    if let username = profile?.username {
                        Text("@\(username)")
                            .font(KinTypography.body)
                            .foregroundStyle(KinColors.secondaryText)
                    }
                }

                // Bio
                VStack(alignment: .leading, spacing: KinSpacing.small) {
                    Text("About")
                        .font(KinTypography.title)
                        .foregroundStyle(KinColors.primaryText)

                    Text(profile?.bio ?? "Your bio will appear here.")
                        .font(KinTypography.body)
                        .foregroundStyle(KinColors.secondaryText)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // Edit Profile
                KinSecondaryButton(
                    title: "Edit Profile",
                    color: KinColors.success
                ) {
                    print("Navigate to Edit Profile")
                }

                // Sign Out
                Button {
                    Task {
                        do {
                            try await AuthService.shared.signOut()
                        } catch {
                            print("Sign out failed: \(error.localizedDescription)")
                        }
                    }
                } label: {
                    Text("Sign Out")
                        .font(KinTypography.body)
                        .foregroundStyle(KinColors.error)
                }
            }
            .padding(KinSpacing.xLarge)
        }
        .background(KinColors.background)
        .task {
            await loadProfile()
        }
    }
    
    @MainActor
    private func loadProfile() async {
        isLoading = true
        errorMessage = nil

        do {
            profile = try await ProfileService.fetchCurrentProfile()
        } catch {
            errorMessage = "Unable to load your profile."
        }

        isLoading = false
    }
}

#Preview {
    ProfileView()
}

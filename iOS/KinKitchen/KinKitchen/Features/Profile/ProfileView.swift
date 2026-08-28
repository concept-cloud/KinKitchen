//
//  ProfileView.swift
//  KinKitchen
//
//  Created by Greg Hudler on 8/26/26.
//

import SwiftUI

struct ProfileView: View {
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
                    Text("Display Name")
                        .font(KinTypography.largeTitle)
                        .foregroundStyle(KinColors.primaryText)

                    Text("@username")
                        .font(KinTypography.body)
                        .foregroundStyle(KinColors.secondaryText)
                }

                // Bio
                VStack(alignment: .leading, spacing: KinSpacing.small) {
                    Text("About")
                        .font(KinTypography.title)
                        .foregroundStyle(KinColors.primaryText)

                    Text("Your bio will appear here.")
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
    }
}

#Preview {
    ProfileView()
}

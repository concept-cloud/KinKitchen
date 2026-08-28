//
//  ProfileView.swift
//  KinKitchen
//
//  Created by Greg Hudler on 8/26/26.
//

import SwiftUI
import Supabase

struct ProfileView: View {
    var body: some View {
        VStack(spacing: KinSpacing.large) {
            Image(systemName: KinIcons.profile)
                .font(.system(size: 48))
                .foregroundStyle(KinColors.primary)

            Text("Profile")
                .font(KinTypography.largeTitle)
                .foregroundStyle(KinColors.primaryText)

            Text("Your profile and account settings will appear here.")
                .font(KinTypography.body)
                .foregroundStyle(KinColors.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, KinSpacing.large)

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
        .task {
            do {
                let profiles: [Profile] = try await SupabaseManager.client
                    .from("profiles")
                    .select()
                    .limit(1)
                    .execute()
                    .value

                print("Profile model decode successful:", profiles)
            } catch {
                print("Profile model decode failed:", error)
            }
        }
    }
}

#Preview {
    ProfileView()
}

//
//  ProfileView.swift
//  KinKitchen
//
//  Created by Greg Hudler on 8/26/26.
//

import SwiftUI
import PhotosUI
import UIKit

struct ProfileView: View {

    @State private var profile: Profile?
    @State private var errorMessage: String?
    @State private var isLoading = true
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var profilePhotoData: Data?
    @State private var isEditingProfile = false
    @State private var isEditingDietaryProfile = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: KinSpacing.xLarge) {

                    // Profile Photo
                    ZStack {
                        Circle()
                            .fill(KinColors.surface)
                            .frame(width: 120, height: 120)

                        if
                            let profilePhotoData,
                            let uiImage = UIImage(data: profilePhotoData)
                        {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 120, height: 120)
                                .clipShape(Circle())
                        } else {
                            Image(systemName: KinIcons.profile)
                                .font(.system(size: 48))
                                .foregroundStyle(KinColors.secondaryText)
                        }
                    }

                    KinPhotoPicker(
                        selectedItem: $selectedPhotoItem
                    )

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
                    VStack(
                        alignment: .leading,
                        spacing: KinSpacing.small
                    ) {
                        Text("About")
                            .font(KinTypography.title)
                            .foregroundStyle(KinColors.primaryText)

                        Text(
                            profile?.bio ?? "Your bio will appear here."
                        )
                        .font(KinTypography.body)
                        .foregroundStyle(KinColors.secondaryText)
                    }
                    .frame(
                        maxWidth: .infinity,
                        alignment: .leading
                    )

                    // Edit Profile
                    KinSecondaryButton(
                        title: "Edit Profile",
                        color: KinColors.success
                    ) {
                        isEditingProfile = true
                    }

                    // Edit Dietary Information
                    KinSecondaryButton(
                        title: "Edit Dietary Information",
                        color: KinColors.success
                    ) {
                        isEditingDietaryProfile = true
                    }

                    // Sign Out
                    Button {
                        Task {
                            do {
                                try await AuthService.shared.signOut()
                            } catch {
                                print(
                                    "Sign out failed: \(error.localizedDescription)"
                                )
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
            .onChange(of: selectedPhotoItem) { _, newItem in
                guard let newItem else {
                    return
                }

                Task {
                    await uploadSelectedPhoto(newItem)
                }
            }
            .sheet(isPresented: $isEditingProfile) {
                EditProfileView(
                    displayName: profile?.displayName ?? "",
                    username: profile?.username ?? "",
                    bio: profile?.bio ?? ""
                )
            }
            .onChange(of: isEditingProfile) { _, isEditing in
                if !isEditing {
                    Task {
                        await loadProfile()
                    }
                }
            }
            .navigationDestination(
                isPresented: $isEditingDietaryProfile
            ) {
                EditDietaryProfileView()
            }
        }
    }

    @MainActor
    private func loadProfile() async {
        isLoading = true
        errorMessage = nil

        do {
            profile = try await ProfileService.fetchCurrentProfile()

            if let path = profile?.profilePhotoPath {
                do {
                    profilePhotoData =
                        try await ProfileService.fetchProfilePhoto(
                            path: path
                        )
                } catch {
                    profilePhotoData = nil
                }
            }

        } catch {
            errorMessage = "Unable to load your profile."
        }

        isLoading = false
    }

    @MainActor
    private func uploadSelectedPhoto(
        _ item: PhotosPickerItem
    ) async {

        defer {
            selectedPhotoItem = nil
        }

        do {
            guard
                let imageData =
                    try await item.loadTransferable(
                        type: Data.self
                    )
            else {
                errorMessage =
                    "Unable to load the selected photo."
                return
            }

            _ = try await ProfileService.uploadProfilePhoto(
                imageData
            )

            await loadProfile()

        } catch {
            errorMessage =
                "Unable to upload profile photo."

            print(
                "Profile photo upload failed:",
                error.localizedDescription
            )
        }
    }
}

#Preview {
    ProfileView()
}

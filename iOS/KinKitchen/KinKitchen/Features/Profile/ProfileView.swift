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
    
    
    var body: some View {
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
                    isEditingProfile = true
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
        .task {
            do {
                let allergens = try await DietaryService.fetchAllergens()

                print("Available allergens:", allergens.map(\.name))

                guard allergens.count >= 2 else {
                    print("Not enough allergens for test")
                    return
                }

                let first = allergens[0]
                let second = allergens[1]

                // Start from a clean test state
                try? await DietaryService.removeAllergen(first.id)
                try? await DietaryService.removeAllergen(second.id)

                // Add first allergen
                try await DietaryService.addAllergen(first.id)

                // Verify duplicate prevention
                do {
                    try await DietaryService.addAllergen(first.id)
                    print("Duplicate allergen test failed: duplicate was allowed")
                } catch {
                    print("Duplicate allergen prevented successfully")
                }

                // Add second allergen
                try await DietaryService.addAllergen(second.id)

                // Verify multiple selections are stored
                let selected = try await DietaryService.fetchSelectedAllergens()

                print("Selected allergen IDs:", selected)
                print(
                    "Multiple allergen test:",
                    selected.contains(first.id) && selected.contains(second.id)
                )

                // Remove first allergen
                try await DietaryService.removeAllergen(first.id)

                // Verify removal and remaining selection
                let afterRemoval = try await DietaryService.fetchSelectedAllergens()

                print("Removal test:", !afterRemoval.contains(first.id))
                print("Remaining allergen test:", afterRemoval.contains(second.id))

            } catch {
                print(
                    "KINKIT-34 allergen test failed:",
                    error.localizedDescription
                )
            }
        }
        .task {
            do {
                let restrictions = try await DietaryService.fetchDietaryRestrictions()

                print("Available restrictions:", restrictions.map(\.name))

                guard restrictions.count >= 2 else {
                    print("Not enough dietary restrictions for test")
                    return
                }

                let first = restrictions[0]
                let second = restrictions[1]

                try? await DietaryService.removeDietaryRestriction(first.id)
                try? await DietaryService.removeDietaryRestriction(second.id)

                try await DietaryService.addDietaryRestriction(first.id)

                do {
                    try await DietaryService.addDietaryRestriction(first.id)
                    print("Duplicate restriction test failed: duplicate was allowed")
                } catch {
                    print("Duplicate restriction prevented successfully")
                }

                try await DietaryService.addDietaryRestriction(second.id)

                let selected = try await DietaryService.fetchSelectedDietaryRestrictions()

                print("Selected restriction IDs:", selected)
                print(
                    "Multiple restriction test:",
                    selected.contains(first.id) && selected.contains(second.id)
                )

                try await DietaryService.removeDietaryRestriction(first.id)

                let afterRemoval = try await DietaryService.fetchSelectedDietaryRestrictions()

                print("Restriction removal test:", !afterRemoval.contains(first.id))
                print("Remaining restriction test:", afterRemoval.contains(second.id))

            } catch {
                print(
                    "KINKIT-35 restriction test failed:",
                    error.localizedDescription
                )
            }
        }
        .onChange(of: selectedPhotoItem) { _, newItem in
            guard let newItem else { return }

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
    }
    
    @MainActor
    private func loadProfile() async {
        isLoading = true
        errorMessage = nil

        do {
            profile = try await ProfileService.fetchCurrentProfile()

            if let path = profile?.profilePhotoPath {
                do {
                    profilePhotoData = try await ProfileService.fetchProfilePhoto(path: path)
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
    private func uploadSelectedPhoto(_ item: PhotosPickerItem) async {
        do {
            guard let imageData = try await item.loadTransferable(type: Data.self) else {
                errorMessage = "Unable to load the selected photo."
                return
            }
            

            
            let path = try await ProfileService.uploadProfilePhoto(imageData)


            await loadProfile()
        } catch {
            errorMessage = "Unable to upload profile photo."
            print("Profile photo upload failed:", error.localizedDescription)
        }
    }
}

#Preview {
    ProfileView()
}

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

    // MARK: - Profile

    @State private var profile: Profile?
    @State private var errorMessage: String?
    @State private var isLoading = true
    @State private var hasLoadedProfile = false

    // MARK: - Profile Photo

    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var profilePhotoData: Data?

    // MARK: - Navigation

    @State private var isEditingProfile = false
    @State private var isEditingDietaryProfile = false
    @State private var isShowingSettings = false

    var body: some View {

        NavigationStack {

            ZStack{
                KinColors.background
                    .ignoresSafeArea()
                
                GeometryReader { geometry in
                    
                    ScrollView {
                        
                        VStack(
                            alignment: .leading,
                            spacing: KinSpacing.xLarge
                        ) {
                            
                            if isLoading {
                                
                                loadingSection
                                
                            } else {
                                
                                // MARK: - Identity
                                
                                profileHeader
                                
                                // MARK: - About
                                
                                profileDetails
                                
                                // MARK: - Error
                                
                                if let errorMessage {
                                    
                                    Text(errorMessage)
                                        .font(KinTypography.caption)
                                        .foregroundStyle(KinColors.error)
                                        .frame(
                                            maxWidth: .infinity,
                                            alignment: .leading
                                        )
                                }
                                
                                // MARK: - Profile Sections
                                
                                profileNavigation
                                
                                Spacer(
                                    minLength: KinSpacing.small
                                )
                                
                                // MARK: - Sign Out
                                
                                signOutButton
                            }
                        }
                        .padding(KinSpacing.xLarge)
                        .frame(
                            maxWidth: .infinity,
                            minHeight: geometry.size.height,
                            alignment: .top
                        )
                    }
                    .background(KinColors.background)
                }
            }
            // MARK: - Load Profile

            .task {

                guard !hasLoadedProfile else {
                    return
                }

                await loadProfile()

                hasLoadedProfile = true
            }

            // MARK: - Photo Selection

            .onChange(
                of: selectedPhotoItem
            ) { _, newItem in

                guard let newItem else {
                    return
                }

                Task {

                    await uploadSelectedPhoto(
                        newItem
                    )
                }
            }

            // MARK: - Edit Profile

            .sheet(
                isPresented: $isEditingProfile
            ) {

                EditProfileView()
            }

            .onChange(
                of: isEditingProfile
            ) { _, isEditing in

                if !isEditing {

                    Task {

                        await loadProfile()
                    }
                }
            }

            // MARK: - Dietary Profile

            .navigationDestination(
                isPresented:
                    $isEditingDietaryProfile
            ) {

                DietaryProfileView()
            }
            .navigationDestination(
                isPresented: $isShowingSettings
            ) {
                SettingsView()
            }
        }
        .toolbarBackground(
            KinColors.background,
            for: .navigationBar
        )
        .toolbarBackground(
            .visible,
            for: .navigationBar
        )
        .background(
            KinColors.background
                .ignoresSafeArea()
        )
    }
   

    // MARK: - Profile Header

    private var profileHeader: some View {

        HStack(
            alignment: .top,
            spacing: KinSpacing.large
        ) {

            // MARK: Photo

            PhotosPicker(
                selection: $selectedPhotoItem,
                matching: .images
            ) {

                ZStack(
                    alignment: .bottomTrailing
                ) {

                    ZStack {

                        Circle()
                            .fill(KinColors.surface)
                            .frame(
                                width: 120,
                                height: 120
                            )

                        if
                            let profilePhotoData,
                            let uiImage = UIImage(
                                data: profilePhotoData
                            )
                        {

                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .frame(
                                    width: 120,
                                    height: 120
                                )
                                .clipShape(Circle())

                        } else {

                            Image(
                                systemName:
                                    KinIcons.profile
                            )
                            .font(
                                .system(size: 48)
                            )
                            .foregroundStyle(
                                KinColors.secondaryText
                            )
                        }
                    }

                    Image(
                        systemName: "camera.fill"
                    )
                    .font(
                        .system(size: 12)
                    )
                    .foregroundStyle(
                        KinColors.background
                    )
                    .frame(
                        width: 30,
                        height: 30
                    )
                    .background(
                        KinColors.primary
                    )
                    .clipShape(Circle())
                }
            }
            .buttonStyle(.plain)

            // MARK: Identity

            VStack(
                alignment: .leading,
                spacing: KinSpacing.medium
            ) {

                // Display Name

                Text(displayName)
                    .font(
                        KinTypography.largeTitle
                    )
                    .foregroundStyle(
                        KinColors.primaryText
                    )
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .frame(
                        maxWidth: .infinity,
                        alignment: .leading
                    )

                // Username + Edit

                HStack(
                    alignment: .center,
                    spacing: KinSpacing.medium
                ) {

                    if let username =
                        profile?.username?
                            .trimmingCharacters(
                                in:
                                    .whitespacesAndNewlines
                            ),
                       !username.isEmpty
                    {

                        Text("@\(username)")
                            .font(
                                KinTypography.body
                            )
                            .foregroundStyle(
                                KinColors.secondaryText
                            )
                            .lineLimit(1)
                    }

                    Spacer(
                        minLength: KinSpacing.small
                    )

                    Button {

                        isEditingProfile = true

                    } label: {

                        HStack(
                            spacing: KinSpacing.small
                        ) {

                            Image(
                                systemName: "pencil"
                            )

                            Text("Edit")
                        }
                        .font(
                            KinTypography.caption
                        )
                        .foregroundStyle(
                            KinColors.primary
                        )
                    }
                    .buttonStyle(.plain)
                }

                // Location

                if let location =
                    profile?.location?
                        .trimmingCharacters(
                            in:
                                .whitespacesAndNewlines
                        ),
                   !location.isEmpty
                {

                    HStack(
                        spacing: KinSpacing.small
                    ) {

                        Image(
                            systemName:
                                "mappin.and.ellipse"
                        )

                        Text(location)
                            .lineLimit(1)
                    }
                    .font(
                        KinTypography.caption
                    )
                    .foregroundStyle(
                        KinColors.secondaryText
                    )
                }
            }
            .frame(
                maxWidth: .infinity,
                minHeight: 120,
                alignment: .topLeading
            )
        }
        .frame(
            maxWidth: .infinity,
            alignment: .leading
        )
    }

    // MARK: - Profile Details

    @ViewBuilder
    private var profileDetails: some View {

        if let bio =
            profile?.bio?
                .trimmingCharacters(
                    in: .whitespacesAndNewlines
                ),
           !bio.isEmpty
        {

            VStack(
                alignment: .leading,
                spacing: KinSpacing.small
            ) {

                Text("About")
                    .font(
                        KinTypography.title
                    )
                    .foregroundStyle(
                        KinColors.primaryText
                    )

                Text(bio)
                    .font(
                        KinTypography.body
                    )
                    .foregroundStyle(
                        KinColors.secondaryText
                    )
                    .frame(
                        maxWidth: .infinity,
                        alignment: .leading
                    )
            }
            .frame(
                maxWidth: .infinity,
                alignment: .leading
            )
        }
    }


    // MARK: - Profile Navigation

    private var profileNavigation: some View {

        VStack(
            spacing: KinSpacing.small
        ) {

            // Dietary Profile

            profileNavigationRow(
                title: "Dietary Profile",
                systemImage: "fork.knife"
            ) {

                isEditingDietaryProfile = true
            }

            // Future Profile Destinations

            placeholderNavigationRow(
                title: "My Recipes",
                systemImage: "book.closed"
            )

            placeholderNavigationRow(
                title: "My Cookbooks",
                systemImage: "books.vertical"
            )

            placeholderNavigationRow(
                title: "Saved Recipes",
                systemImage: "bookmark"
            )

            // Settings

            profileNavigationRow(
                title: "Settings",
                systemImage: "gearshape"
            ) {
                isShowingSettings = true
            }

            placeholderNavigationRow(
                title: "App Info",
                systemImage: "info.circle"
            )
        }
    }

    // MARK: - Navigation Row

    private func profileNavigationRow(
        title: String,
        systemImage: String,
        action: @escaping () -> Void
    ) -> some View {

        Button(
            action: action
        ) {

            HStack(
                spacing: KinSpacing.medium
            ) {

                Image(
                    systemName: systemImage
                )
                .font(.body)
                .foregroundStyle(
                    KinColors.primary
                )
                .frame(width: 24)

                Text(title)
                    .font(
                        KinTypography.body
                    )
                    .foregroundStyle(
                        KinColors.primaryText
                    )

                Spacer()

                Image(
                    systemName:
                        "chevron.right"
                )
                .font(.caption)
                .foregroundStyle(
                    KinColors.secondaryText
                )
            }
            .padding(
                KinSpacing.medium
            )
            .frame(
                maxWidth: .infinity
            )
            .background(
                KinColors.surface
            )
            .clipShape(
                RoundedRectangle(
                    cornerRadius:
                        KinRadius.medium
                )
            )
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Placeholder Navigation Row

    private func placeholderNavigationRow(
        title: String,
        systemImage: String
    ) -> some View {

        HStack(
            spacing: KinSpacing.medium
        ) {

            Image(systemName: systemImage)
                .font(.body)
                .foregroundStyle(KinColors.primary)
                .frame(width: 24)

            Text(title)
                .font(KinTypography.body)
                .foregroundStyle(KinColors.primaryText)

            Spacer()

            Text("Coming Soon")
                .font(KinTypography.caption)
                .foregroundStyle(KinColors.secondaryText)
        }
        .padding(KinSpacing.medium)
        .frame(maxWidth: .infinity)
        .background(KinColors.surface)
        .clipShape(
            RoundedRectangle(
                cornerRadius: KinRadius.medium
            )
        )
    }

    // MARK: - Sign Out

    private var signOutButton: some View {

        Button {

            Task {

                do {

                    try await
                        AuthService.shared
                            .signOut()

                } catch {

                    errorMessage =
                        "Unable to sign out. Please try again."

                    print(
                        "SIGN OUT ERROR:",
                        error.localizedDescription
                    )
                }
            }

        } label: {

            HStack {

                Image(
                    systemName:
                        "rectangle.portrait.and.arrow.right"
                )

                Text("Sign Out")

                Spacer()
            }
            .font(
                KinTypography.body
            )
            .foregroundStyle(
                KinColors.error
            )
            .padding(
                KinSpacing.medium
            )
            .frame(
                maxWidth: .infinity
            )
            .background(
                KinColors.surface
            )
            .clipShape(
                RoundedRectangle(
                    cornerRadius:
                        KinRadius.medium
                )
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Loading

    private var loadingSection: some View {

        VStack {

            Spacer()

            ProgressView()

            Spacer()
        }
        .frame(
            maxWidth: .infinity
        )
    }

    // MARK: - Display Name

    private var displayName: String {

        let storedDisplayName =
            profile?.displayName?
                .trimmingCharacters(
                    in: .whitespacesAndNewlines
                ) ?? ""

        if !storedDisplayName.isEmpty {

            return storedDisplayName
        }

        let firstName =
            profile?.firstName?
                .trimmingCharacters(
                    in: .whitespacesAndNewlines
                ) ?? ""

        let lastName =
            profile?.lastName?
                .trimmingCharacters(
                    in: .whitespacesAndNewlines
                ) ?? ""

        let fullName =
            "\(firstName) \(lastName)"
                .trimmingCharacters(
                    in: .whitespacesAndNewlines
                )

        if !fullName.isEmpty {

            return fullName
        }

        return "Your Profile"
    }

    // MARK: - Load Profile

    @MainActor
    private func loadProfile() async {

        isLoading = true
        errorMessage = nil

        defer {

            isLoading = false
        }

        do {

            profile =
                try await ProfileService
                    .fetchCurrentProfile()

            if let path =
                profile?
                    .profilePhotoPath
            {

                do {

                    profilePhotoData =
                        try await ProfileService
                            .fetchProfilePhoto(
                                path: path
                            )

                } catch {

                    profilePhotoData = nil

                    print(
                        "PROFILE PHOTO LOAD ERROR:",
                        error.localizedDescription
                    )
                }

            } else {

                profilePhotoData = nil
            }

        } catch {

            errorMessage =
                "Unable to load your profile."

            print(
                "PROFILE LOAD ERROR:",
                error.localizedDescription
            )
        }
    }

    // MARK: - Upload Profile Photo

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
                    try await item
                        .loadTransferable(
                            type: Data.self
                        )
            else {

                errorMessage =
                    "Unable to load the selected photo."

                return
            }

            _ =
                try await ProfileService
                    .uploadProfilePhoto(
                        imageData
                    )

            await loadProfile()

        } catch {

            errorMessage =
                "Unable to upload profile photo."

            print(
                "PROFILE PHOTO UPLOAD ERROR:",
                error.localizedDescription
            )
        }
    }
}

#Preview {

    ProfileView()
}

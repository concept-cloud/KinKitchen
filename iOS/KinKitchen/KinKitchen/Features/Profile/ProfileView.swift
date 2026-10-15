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
    @State private var isShowingNotifications = false
    @State private var isShowingAppInfo = false

    var body: some View {

        NavigationStack {

            GeometryReader { geometry in

                ScrollView {

                    if isLoading {

                        loadingSection
                            .frame(minHeight: geometry.size.height)

                    } else {

                        VStack(spacing: 0) {

                            // MARK: - Identity

                            profileHero(
                                topInset: geometry.safeAreaInsets.top
                            )

                            // MARK: - Sections

                            VStack(
                                spacing: KinSpacing.medium
                            ) {

                                if let errorMessage {

                                    Text(errorMessage)
                                        .font(KinTypography.caption)
                                        .foregroundStyle(KinColors.error)
                                        .frame(
                                            maxWidth: .infinity,
                                            alignment: .leading
                                        )
                                }

                                profileNavigation

                                signOutButton
                                    .padding(.top, KinSpacing.small)
                            }
                            .padding(KinSpacing.large)
                            .padding(.top, KinSpacing.small)
                            .padding(.bottom, KinSpacing.xxLarge)
                            .frame(
                                maxWidth: .infinity,
                                minHeight: geometry.size.height * 0.55,
                                alignment: .top
                            )
                            .background(
                                UnevenRoundedRectangle(
                                    topLeadingRadius: KinRadius.xLarge,
                                    topTrailingRadius: KinRadius.xLarge
                                )
                                .fill(KinColors.paper)
                                .shadow(color: .black.opacity(0.12), radius: 10, y: -2)
                            )
                            // Tucks up over the bottom of the photo.
                            .padding(.top, -KinSpacing.xLarge)
                        }
                    }
                }
                .scrollEdgeEffectHidden(true, for: .top)
                .ignoresSafeArea(edges: .top)
                .background(KinColors.paper.ignoresSafeArea())
            }
            .navigationBarHidden(true)
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
            
            // MARK: - Notifications

            .navigationDestination(
                isPresented:
                    $isShowingNotifications
            ) {
                NotificationsView()
            }
            .navigationDestination(
                isPresented: $isShowingSettings
            ) {
                SettingsView()
            }
            .navigationDestination(
                isPresented: $isShowingAppInfo
            ) {
                AppInfoView()
            }
        }
    }
   

    // MARK: - Profile Hero

    /// Deep navy the photo fades into; the same in light and dark mode
    /// so the white text always reads.
    private static let heroNavy =
        Color(red: 0.07, green: 0.10, blue: 0.17)

    @AppStorage(KinDietaryBackground.storageKey)
    private var backgroundChoice = KinDietaryBackground.default.rawValue

    /// The user's kitchen photo on the left fading into navy, with who
    /// they are on the right: photo, name, @username, location, bio.
    private func profileHero(
        topInset: CGFloat
    ) -> some View {

        HStack(spacing: 0) {

            Spacer(minLength: 0)

            VStack(
                alignment: .leading,
                spacing: KinSpacing.small
            ) {

                HStack {
                    Spacer()
                    editButton
                }

                avatar
                    .padding(.top, KinSpacing.xSmall)

                Text(displayName)
                    .font(KinTypography.title)
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isHeader)

                if let username = cleaned(profile?.username) {
                    Text("@\(username)")
                        .font(KinTypography.body)
                        .foregroundStyle(.white.opacity(0.7))
                        .lineLimit(1)
                }

                if let location = cleaned(profile?.location) {
                    Label(location, systemImage: "mappin.and.ellipse")
                        .font(KinTypography.footnote)
                        .foregroundStyle(.white.opacity(0.8))
                        .lineLimit(1)
                }

                if let bio = cleaned(profile?.bio) {

                    Rectangle()
                        .fill(.white.opacity(0.2))
                        .frame(height: 1)
                        .padding(.vertical, KinSpacing.xSmall)

                    Label {
                        Text("Bio")
                            .font(KinTypography.headline)
                            .foregroundStyle(.white)
                    } icon: {
                        Image(systemName: "leaf.fill")
                            .foregroundStyle(KinColors.success)
                    }

                    Text(bio)
                        .font(KinTypography.callout)
                        .foregroundStyle(.white.opacity(0.85))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .containerRelativeFrame(.horizontal) { width, _ in
                width * 0.58
            }
            .padding(.trailing, KinSpacing.large)
        }
        .padding(.top, topInset + KinSpacing.small)
        // Room for the sheet to tuck under.
        .padding(.bottom, KinSpacing.xLarge + KinSpacing.large)
        .frame(maxWidth: .infinity, minHeight: 380, alignment: .top)
        .background {
            Color.clear
                .overlay(alignment: .leading) {
                    Image(KinDietaryBackground.saved(backgroundChoice).imageName)
                        .resizable()
                        .scaledToFill()
                }
                .clipped()
                .overlay {
                    // Photo on the left, navy behind the text.
                    LinearGradient(
                        stops: [
                            .init(color: Self.heroNavy.opacity(0), location: 0.2),
                            .init(color: Self.heroNavy.opacity(0.75), location: 0.45),
                            .init(color: Self.heroNavy.opacity(0.97), location: 0.62),
                            .init(color: Self.heroNavy, location: 1)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                }
                .overlay(alignment: .top) {
                    // Keeps the clock readable over a bright photo.
                    LinearGradient(
                        colors: [
                            KinColors.background.opacity(0.55),
                            KinColors.background.opacity(0)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: topInset + 30)
                }
                .accessibilityHidden(true)
        }
    }

    private var editButton: some View {

        Button {
            isEditingProfile = true
        } label: {
            HStack(spacing: KinSpacing.xSmall) {
                Image(systemName: KinIcons.edit)
                    .foregroundStyle(KinColors.primary)
                Text("Edit")
                    .foregroundStyle(Color(red: 0.12, green: 0.14, blue: 0.2))
            }
            .font(KinTypography.subheadline)
            .padding(.horizontal, KinSpacing.medium)
            .padding(.vertical, KinSpacing.small)
            .background(.white, in: Capsule())
            .kinFloatingShadow()
        }
        .buttonStyle(.kinPressable)
        .accessibilityLabel("Edit profile")
    }

    /// Tap to change the profile photo.
    private var avatar: some View {

        PhotosPicker(
            selection: $selectedPhotoItem,
            matching: .images
        ) {
            ZStack(alignment: .bottomTrailing) {

                Group {
                    if let profilePhotoData,
                       let uiImage = UIImage(data: profilePhotoData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                    } else {
                        Image(systemName: KinIcons.profile)
                            .resizable()
                            .scaledToFit()
                            .foregroundStyle(.white.opacity(0.6))
                            .padding(KinSpacing.small)
                    }
                }
                .frame(width: 72, height: 72)
                .background(.white.opacity(0.12))
                .clipShape(Circle())
                .overlay {
                    Circle().strokeBorder(.white.opacity(0.85), lineWidth: 2)
                }

                Image(systemName: KinIcons.camera)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 26, height: 26)
                    .background(KinColors.primary, in: Circle())
                    .overlay {
                        Circle().strokeBorder(Self.heroNavy, lineWidth: 2)
                    }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Change profile photo")
    }

    private func cleaned(
        _ value: String?
    ) -> String? {
        guard let value = value?.trimmingCharacters(in: .whitespacesAndNewlines),
              !value.isEmpty else {
            return nil
        }
        return value
    }


    // MARK: - Profile Navigation

    private var profileNavigation: some View {

        VStack(
            spacing: KinSpacing.medium
        ) {

            profileNavigationRow(
                title: "Dietary Profile",
                subtitle: "Manage your allergens, restrictions, and preferences.",
                systemImage: KinIcons.recipes,
                tint: KinColors.primary
            ) {
                isEditingDietaryProfile = true
            }

            profileNavigationRow(
                title: "Notifications",
                subtitle: "Invites, event updates, and reminders.",
                systemImage: "bell",
                tint: KinColors.warning
            ) {
                isShowingNotifications = true
            }

            profileNavigationRow(
                title: "Settings",
                subtitle: "Appearance, themes, and cooking options.",
                systemImage: "gearshape",
                tint: KinColors.success
            ) {
                isShowingSettings = true
            }

            profileNavigationRow(
                title: "App Info",
                subtitle: "Version and build details.",
                systemImage: "info.circle",
                tint: KinColors.secondaryText
            ) {
                isShowingAppInfo = true
            }
        }
    }

    // MARK: - Navigation Row

    /// Tinted icon tile, title, a line about what's inside, chevron.
    private func profileNavigationRow(
        title: String,
        subtitle: String,
        systemImage: String,
        tint: Color,
        action: @escaping () -> Void
    ) -> some View {

        Button(action: action) {

            HStack(spacing: KinSpacing.medium) {

                Image(systemName: systemImage)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(tint)
                    .frame(width: 56, height: 56)
                    .background(
                        tint.opacity(0.14),
                        in: RoundedRectangle(cornerRadius: KinRadius.large)
                    )
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: KinSpacing.xxSmall) {
                    Text(title)
                        .font(KinTypography.headline)
                        .foregroundStyle(KinColors.primaryText)

                    Text(subtitle)
                        .font(KinTypography.footnote)
                        .foregroundStyle(KinColors.secondaryText)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: KinSpacing.small)

                Image(systemName: KinIcons.forward)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(KinColors.secondaryText)
            }
            .padding(KinSpacing.medium)
            .frame(maxWidth: .infinity)
            .background(
                KinColors.surface,
                in: RoundedRectangle(cornerRadius: KinRadius.large)
            )
            .kinCardShadow()
            .contentShape(RoundedRectangle(cornerRadius: KinRadius.large))
        }
        .buttonStyle(.kinPressable)
        .accessibilityElement(children: .combine)
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

            Label(
                "Sign Out",
                systemImage: "rectangle.portrait.and.arrow.right"
            )
            .font(KinTypography.headline)
            .foregroundStyle(KinColors.error)
            .frame(maxWidth: .infinity)
            .padding(.vertical, KinSpacing.medium)
            .background(
                KinColors.error.opacity(0.08),
                in: RoundedRectangle(cornerRadius: KinRadius.large)
            )
            .overlay {
                RoundedRectangle(cornerRadius: KinRadius.large)
                    .strokeBorder(KinColors.error.opacity(0.6), lineWidth: 1.5)
            }
        }
        .buttonStyle(.kinPressable)
    }

    // MARK: - Loading

    private var loadingSection: some View {
        KinLoadingView(message: "Loading profile...")
            .frame(minHeight: 320)
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

//
//  ProfileView.swift
//  KinKitchen
//
//  Created by Greg Hudler on 8/26/26.
//

import SwiftUI
import UIKit

struct ProfileView: View {

    // MARK: - Profile

    @State private var profile: Profile?
    @State private var errorMessage: String?
    @State private var isLoading = true
    @State private var hasLoadedProfile = false

    // MARK: - Profile Photo

    /// Changed from Edit Profile.
    @State private var profilePhotoData: Data?

    // MARK: - Full Profile

    /// Collapsed shows who you are and every option; pulling down
    /// opens the full profile (bio, numbers, family rating).
    @State private var isExpanded = false
    @State private var stats: ProfileStats?
    @State private var isUpdatingRatingVisibility = false

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

                                sheetHandle

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
                            .padding(.top, -KinSpacing.small)
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
                // Pulling down past the top opens the full profile.
                .onScrollGeometryChange(
                    for: Bool.self
                ) { geometry in
                    geometry.contentOffset.y + geometry.contentInsets.top < -70
                } action: { _, isPulled in
                    if isPulled, !isExpanded, !isLoading {
                        setExpanded(true)
                    }
                }
                .sensoryFeedback(.impact(weight: .light), trigger: isExpanded)
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

            // MARK: - Edit Profile

            .sheet(
                isPresented: $isEditingProfile
            ) {

                EditProfileView(
                    currentPhotoData: profilePhotoData
                )
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

    /// Who you are: the photo fading into navy with your name,
    /// @username and location. Pulled open, the full profile follows
    /// on the navy: bio, your numbers and your family rating.
    private func profileHero(
        topInset: CGFloat
    ) -> some View {

        VStack(spacing: 0) {

            identityHeader(topInset: topInset)

            if isExpanded {
                fullProfile
                    .transition(
                        .move(edge: .top)
                            .combined(with: .opacity)
                    )
            }
        }
        // Room for the sheet to tuck under.
        .padding(.bottom, KinSpacing.xLarge + KinSpacing.medium)
        .frame(maxWidth: .infinity)
        .background(Self.heroNavy)
        .clipped()
    }

    private func identityHeader(
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
            }
            .containerRelativeFrame(.horizontal) { width, _ in
                width * 0.58
            }
            .padding(.trailing, KinSpacing.large)
        }
        .padding(.top, topInset + KinSpacing.small)
        .padding(.bottom, KinSpacing.large)
        .frame(maxWidth: .infinity, minHeight: topInset + 200, alignment: .top)
        .background {
            // Navy underneath, so the photo fades into it with no edge.
            Self.heroNavy
                .overlay(alignment: .leading) {
                    heroPhoto
                }
                .clipped()
                .overlay {
                    // Photo on the left, navy behind the text.
                    LinearGradient(
                        stops: [
                            .init(color: Self.heroNavy.opacity(0), location: 0.18),
                            .init(color: Self.heroNavy.opacity(0.75), location: 0.42),
                            // Solid before the photo's edge (62%), so
                            // the edge never shows.
                            .init(color: Self.heroNavy, location: 0.58),
                            .init(color: Self.heroNavy, location: 1)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                }
                .overlay(alignment: .bottom) {
                    // Blends into the full profile below when open.
                    LinearGradient(
                        colors: [Self.heroNavy.opacity(0), Self.heroNavy],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 40)
                    .opacity(isExpanded ? 1 : 0)
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


    // MARK: - Full Profile

    private var fullProfile: some View {

        VStack(
            alignment: .leading,
            spacing: KinSpacing.large
        ) {

            if let bio = cleaned(profile?.bio) {

                VStack(alignment: .leading, spacing: KinSpacing.small) {
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

            if let stats {

                HStack(spacing: KinSpacing.small) {
                    statTile(stats.recipeCount, label: "Recipes", systemImage: KinIcons.recipes)
                    statTile(stats.cookbookCount, label: "Cookbooks", systemImage: KinIcons.cookbooks)
                    statTile(stats.sharedRecipeCount, label: "Shared", systemImage: KinIcons.share)
                }

                ratingCard(stats)

            } else {

                Text("Your numbers couldn't be loaded right now.")
                    .font(KinTypography.footnote)
                    .foregroundStyle(.white.opacity(0.6))
            }
        }
        .padding(.horizontal, KinSpacing.large)
        .padding(.top, KinSpacing.xSmall)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func statTile(
        _ value: Int,
        label: String,
        systemImage: String
    ) -> some View {

        VStack(spacing: KinSpacing.xxSmall) {
            Image(systemName: systemImage)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(KinColors.accent)

            Text("\(value)")
                .font(KinTypography.title2)
                .foregroundStyle(.white)
                .contentTransition(.numericText())

            Text(label)
                .font(KinTypography.caption)
                .foregroundStyle(.white.opacity(0.7))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, KinSpacing.medium)
        .background(
            .white.opacity(0.08),
            in: RoundedRectangle(cornerRadius: KinRadius.large)
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(value) \(label)")
    }

    /// Average of the ratings other people gave your recipes, and
    /// whether others may see it.
    private func ratingCard(
        _ stats: ProfileStats
    ) -> some View {

        VStack(alignment: .leading, spacing: KinSpacing.medium) {

            HStack(alignment: .center, spacing: KinSpacing.medium) {

                VStack(alignment: .leading, spacing: KinSpacing.xxSmall) {
                    Text("Family Rating")
                        .font(KinTypography.headline)
                        .foregroundStyle(.white)

                    if let average = stats.ratingAverage,
                       let count = stats.ratingCount,
                       count > 0 {

                        HStack(spacing: KinSpacing.small) {
                            stars(average)
                            Text(ProfileStatsText.ratingCount(count))
                                .font(KinTypography.caption)
                                .foregroundStyle(.white.opacity(0.7))
                        }
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel(
                            "\(ProfileStatsText.average(average)) out of 5, \(ProfileStatsText.ratingCount(count))"
                        )

                    } else {

                        Text("When family rates your recipes, it shows here.")
                            .font(KinTypography.caption)
                            .foregroundStyle(.white.opacity(0.7))
                    }
                }

                Spacer(minLength: 0)

                if let average = stats.ratingAverage,
                   (stats.ratingCount ?? 0) > 0 {
                    Text(ProfileStatsText.average(average))
                        .font(KinTypography.largeTitle)
                        .foregroundStyle(.white)
                        .accessibilityHidden(true)
                }
            }

            Rectangle()
                .fill(.white.opacity(0.12))
                .frame(height: 1)

            Toggle(
                isOn: Binding(
                    get: { stats.ratingIsPublic },
                    set: { newValue in
                        Task {
                            await setRatingPublic(newValue)
                        }
                    }
                )
            ) {
                VStack(alignment: .leading, spacing: KinSpacing.xxSmall) {
                    Text("Show on my profile")
                        .font(KinTypography.subheadline)
                        .foregroundStyle(.white)
                    Text(
                        stats.ratingIsPublic
                            ? "Others can see your family rating."
                            : "Only you can see your family rating."
                    )
                    .font(KinTypography.caption)
                    .foregroundStyle(.white.opacity(0.65))
                }
            }
            .tint(KinColors.success)
            .disabled(isUpdatingRatingVisibility)
        }
        .padding(KinSpacing.medium)
        .background(
            .white.opacity(0.08),
            in: RoundedRectangle(cornerRadius: KinRadius.large)
        )
    }

    private func stars(
        _ average: Double
    ) -> some View {

        let stars = ProfileStatsText.stars(for: average)

        return HStack(spacing: 2) {
            ForEach(0..<5, id: \.self) { index in
                Image(
                    systemName:
                        index < stars.full
                            ? "star.fill"
                            : (index == stars.full && stars.half
                                ? "star.leadinghalf.filled"
                                : "star")
                )
            }
        }
        .font(.system(size: 14))
        .foregroundStyle(KinColors.accent)
    }


    // MARK: - Sheet Handle

    /// Pull down (or tap) to open the full profile; swipe up (or tap)
    /// to close it.
    private var sheetHandle: some View {

        VStack(spacing: KinSpacing.xSmall) {
            Capsule()
                .fill(KinColors.secondaryText.opacity(0.4))
                .frame(width: 40, height: 5)

            Label(
                isExpanded ? "Swipe up to close" : "Pull down for your full profile",
                systemImage: isExpanded ? "chevron.up" : "chevron.down"
            )
            .font(KinTypography.caption)
            .foregroundStyle(KinColors.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, KinSpacing.small)
        .padding(.bottom, KinSpacing.xSmall)
        .contentShape(Rectangle())
        .onTapGesture {
            setExpanded(!isExpanded)
        }
        .gesture(
            DragGesture(minimumDistance: 12)
                .onEnded { value in
                    if value.translation.height > 30 {
                        setExpanded(true)
                    } else if value.translation.height < -30 {
                        setExpanded(false)
                    }
                }
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(isExpanded ? "Hide full profile" : "Show full profile")
        .accessibilityAddTraits(.isButton)
    }

    private func setExpanded(
        _ expanded: Bool
    ) {
        guard expanded != isExpanded else {
            return
        }
        withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
            isExpanded = expanded
        }
    }

    @MainActor
    private func setRatingPublic(
        _ isPublic: Bool
    ) async {

        guard var updated = stats else {
            return
        }

        let previous = updated.ratingIsPublic
        updated.ratingIsPublic = isPublic
        stats = updated
        isUpdatingRatingVisibility = true

        defer {
            isUpdatingRatingVisibility = false
        }

        do {
            try await ProfileStatsService.setRatingPublic(isPublic)
        } catch {
            // Put the switch back; nothing changed on the account.
            updated.ratingIsPublic = previous
            stats = updated
            errorMessage = "Couldn't change who sees your rating. Please try again."
            print("RATING VISIBILITY ERROR:", error.localizedDescription)
        }
    }


    /// The profile photo, filling the left of the header and showing
    /// the person's face (top of the photo) rather than the middle.
    /// A warm placeholder until one is chosen.
    @ViewBuilder
    private var heroPhoto: some View {

        if let profilePhotoData,
           let uiImage = UIImage(data: profilePhotoData) {

            GeometryReader { proxy in
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    // Photo sits in the left ~60%, where it shows.
                    .frame(
                        width: proxy.size.width * 0.62,
                        height: proxy.size.height,
                        alignment: .top
                    )
                    .clipped()
            }

        } else {

            GeometryReader { proxy in
                // Warm fill where a photo would be, with the icon kept
                // on the photo side, clear of the name.
                LinearGradient(
                    colors: [
                        KinColors.accent.opacity(0.35),
                        KinColors.primary.opacity(0.25)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .background(KinColors.paper)
                .frame(
                    width: proxy.size.width * 0.62,
                    height: proxy.size.height
                )
                .overlay(alignment: .leading) {
                    Image(systemName: KinIcons.profile)
                        .font(.system(size: 52, weight: .semibold))
                        .foregroundStyle(KinColors.primary.opacity(0.6))
                        .frame(width: proxy.size.width * 0.36)
                }
            }
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

        // Loader only the first time; after editing, refresh quietly.
        isLoading = profile == nil
        errorMessage = nil

        // Numbers are extra; the page works without them.
        async let statsRequest =
            try? ProfileStatsService.fetchStats()

        defer {

            isLoading = false
        }

        stats = await statsRequest

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
}

#Preview {

    ProfileView()
}

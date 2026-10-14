//
//  HomeView.swift
//  KinKitchen
//
//  Created by Greg Hudler on 8/26/26.
//

import SwiftUI
import Supabase


struct HomeView: View {
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    /// Switches the app's main tab (ContentView owns the tab bar).
    var selectTab: (KinTab) -> Void = { _ in }

    @State private var showingAddRecipe = false
    @State private var showingAddGathering = false
    @State private var showingSearch = false
    @State private var comingSoon: ComingSoonFeature?
    @State private var bellRings = 0
    @State private var recentRecipes: [Recipe] = []
    @State private var cookbooks: [Cookbook] = []
    @State private var hasLoadedDiscovery = false
    @State private var selectedRecipeId: UUID?
    @State private var selectedCookbookId: UUID?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    @State private var upcomingGatherings:
    [GatheringListItem] = []
    
    @State private var isLoadingGatherings = true
    
    @State private var notifications:
    [KinNotification] = []
    @State private var selectedGatheringId: UUID?
    @State private var selectedNotification: KinNotification?
    @State private var showingAllNotifications = false

    
    var body: some View {
        
        NavigationStack {
            
            ScrollView {

                VStack(
                    spacing: 0
                ) {

                // MARK: - Hero & Welcome

                homeHero

                VStack(
                    alignment: .leading,
                    spacing: KinSpacing.xLarge
                ) {

                    // MARK: - Quick Actions

                    quickActionsSection

                    // MARK: - Upcoming Gatherings

                    VStack(
                        alignment: .leading,
                        spacing: KinSpacing.medium
                    ) {

                        KinSectionHeader(
                            title: "Upcoming Gatherings",
                            actionTitle: "View All"
                        ) {
                            selectTab(.gatherings)
                        }

                        upcomingGatheringsSection
                    }

                    // MARK: - Recent Recipes

                    VStack(
                        alignment: .leading,
                        spacing: KinSpacing.medium
                    ) {

                        KinSectionHeader(
                            title: "Recent Recipes",
                            actionTitle: "View All"
                        ) {
                            selectTab(.recipes)
                        }

                        recentRecipesSection
                    }

                    // MARK: - Your Cookbooks

                    VStack(
                        alignment: .leading,
                        spacing: KinSpacing.medium
                    ) {

                        KinSectionHeader(
                            title: "Your Cookbooks",
                            actionTitle: "View All"
                        ) {
                            selectTab(.cookbooks)
                        }

                        cookbooksSection
                    }

                    // MARK: - Alerts

                    VStack(
                        alignment: .leading,
                        spacing: KinSpacing.medium
                    ) {

                        KinSectionHeader(
                            title: "Alerts",
                            actionTitle: "View All"
                        ) {
                            showingAllNotifications = true
                        }

                        alertsSection
                    }
                }
                .padding(
                    .horizontal,
                    KinSpacing.large
                )
                .padding(
                    .bottom,
                    KinSpacing.xLarge
                )
                }
            }
            .background(
                homeBackground
            )
            // Photo runs up under the status bar. A clear bar with a
            // dark scheme keeps the status bar light over it, and holds
            // the bell.
            .ignoresSafeArea(
                edges: .top
            )
            // No bar background or scroll-edge haze over the photo,
            // so its top (light or dark) shows through untinted.
            .toolbarBackgroundVisibility(
                .hidden,
                for: .navigationBar
            )
            .scrollEdgeEffectHidden(
                true,
                for: .top
            )
            .toolbar {

                ToolbarItem(
                    placement: .topBarTrailing
                ) {
                    notificationsBell
                }
                .sharedBackgroundVisibility(.hidden)
            }
            .task {
                await loadHome()
            }

            .refreshable {

                do {
                    notifications =
                    try await NotificationService
                        .fetchNotifications()
                } catch {
                    print(
                        "HOME NOTIFICATION REFRESH ERROR:",
                        error.localizedDescription
                    )
                }

                await loadHome()
            }

            .onChange(of: scenePhase) {
                if scenePhase == .active {
                    Task {
                        await loadHome()
                    }
                }
            }

            // MARK: - Gathering Destination

            .navigationDestination(
                item: $selectedGatheringId
            ) { gatheringId in

                GatheringDetailView(
                    gatheringId: gatheringId
                )
            }

            .navigationDestination(
                item: $selectedNotification
            ) { notification in

                if let gatheringId =
                    notification.gatheringId {

                    GatheringDetailView(
                        gatheringId: gatheringId,
                        openedNotification: notification
                    )
                }
            }
            // MARK: - Notifications Destination

            .navigationDestination(
                isPresented: $showingAllNotifications
            ) {

                NotificationsView()
            }
            // MARK: - Recipe & Cookbook Destinations

            .navigationDestination(
                item: $selectedRecipeId
            ) { recipeId in

                RecipeDetailView(
                    recipeId: recipeId
                )
            }
            .navigationDestination(
                item: $selectedCookbookId
            ) { cookbookId in

                CookbookDetailView(
                    cookbookId: cookbookId
                )
            }
            // Recents and cookbooks may have changed while away.
            .onChange(of: selectedRecipeId) {
                if selectedRecipeId == nil {
                    Task {
                        await loadDiscovery()
                    }
                }
            }
            .onChange(of: selectedCookbookId) {
                if selectedCookbookId == nil {
                    Task {
                        await loadDiscovery()
                    }
                }
            }
            .onChange(of: showingAddRecipe) {
                if !showingAddRecipe {
                    Task {
                        await loadDiscovery()
                    }
                }
            }
            // MARK: - Search Destination

            .navigationDestination(
                isPresented: $showingSearch
            ) {

                HomeSearchView()
            }
            // MARK: - Add Gathering Destination

            .navigationDestination(
                isPresented: $showingAddGathering
            ) {

                AddGatheringView()
            }
            // Show a just-created gathering when coming back.
            .onChange(of: showingAddGathering) {
                if !showingAddGathering {
                    Task {
                        await loadHome()
                    }
                }
            }
            // MARK: - Add Recipe Destination

            .navigationDestination(
                isPresented: $showingAddRecipe
            ) {

                AddRecipeView()
            }
        }
    }
    // MARK: - Unread Notifications

    private var unreadNotifications:
    [KinNotification] {

        notifications.filter {
            !$0.isRead
        }
    }
}


// MARK: - Coming Soon

/// Quick actions whose features aren't built yet.
private enum ComingSoonFeature {

    case tableTalk
    case scanRecipe

    var title: String {

        switch self {

        case .tableTalk:
            return "Table Talk Is Coming Soon"

        case .scanRecipe:
            return "Scan Recipe Is Coming Soon"
        }
    }

    var message: String {

        switch self {

        case .tableTalk:
            return "A place to share what you're cooking and see what your family and friends are making."

        case .scanRecipe:
            return "Snap a photo of a recipe card or cookbook page to add it to your recipes."
        }
    }
}


// MARK: - Layout

private extension HomeView {

    /// Warm wash behind the top of Home, fading into the app background.
    var homeBackground: some View {

        LinearGradient(
            colors: [
                KinColors.accent.opacity(0.22),
                KinColors.background
            ],
            startPoint: .top,
            endPoint: .center
        )
        .background(
            KinColors.background
        )
        .ignoresSafeArea()
    }


    /// Where the table begins in the hero photos: the fade into the
    /// page starts here and the search bar sits on it.
    private static let heroFadeStart: CGFloat = 0.74

    /// The Kin Kitchen hero photo (light and dark versions in the
    /// HomeHero asset), full width from the top of the screen with
    /// nothing cropped, fading into the page at the bottom.
    var homeHero: some View {

        Image("HomeHero")
            .resizable()
            .scaledToFit()
            .frame(
                maxWidth: .infinity
            )
            .overlay {

                LinearGradient(
                    stops: [
                        .init(
                            color: KinColors.background.opacity(0),
                            location: Self.heroFadeStart
                        ),
                        .init(
                            color: KinColors.background.opacity(0.75),
                            location: 0.87
                        ),
                        .init(
                            color: KinColors.background,
                            location: 1
                        )
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
            .accessibilityElement()
            .accessibilityLabel("Kin Kitchen")
            .accessibilityAddTraits(.isHeader)
            // Search sits at the top of the fade, where the table
            // begins, and the fade runs on below it into the page.
            .overlay {

                GeometryReader { proxy in

                    searchEntry
                        .padding(
                            .horizontal,
                            KinSpacing.large
                        )
                        .padding(
                            .top,
                            proxy.size.height * Self.heroFadeStart
                        )
                }
            }
    }


    /// Looks like a search field; opens the full search screen.
    var searchEntry: some View {

        Button {

            showingSearch = true

        } label: {

            HStack(
                spacing: KinSpacing.small
            ) {

                Image(systemName: KinIcons.search)
                    .foregroundStyle(KinColors.secondaryText)

                Text(HomeSearch.placeholder)
                    .font(KinTypography.callout)
                    .foregroundStyle(KinColors.secondaryText)
                    .lineLimit(1)

                Spacer(minLength: 0)
            }
            .padding(KinSpacing.medium)
            .background(KinColors.surface)
            .clipShape(Capsule())
            .shadow(
                color: .black.opacity(0.06),
                radius: 6,
                y: 2
            )
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Search")
        .accessibilityHint("Searches your recipes, cookbooks, and gatherings")
    }




    var notificationsBell: some View {

        let count =
            unreadNotifications.count

        return Button {

            showingAllNotifications = true

        } label: {

            Image(
                systemName: "bell.fill"
            )
            .font(
                .system(
                    size: 20,
                    weight: .semibold
                )
            )
            .foregroundStyle(
                KinColors.primary
            )
            // Rings when Home loads with unread notifications.
            .symbolEffect(
                .wiggle.byLayer,
                options: .repeat(2),
                value: bellRings
            )
            .frame(
                width: 44,
                height: 44
            )
            .background(
                .white.opacity(0.92)
            )
            .clipShape(
                Circle()
            )
            .overlay(
                alignment: .topTrailing
            ) {

                if count > 0 {

                    Text(
                        count > 99
                            ? "99+"
                            : "\(count)"
                    )
                    .font(
                        .system(
                            size: 11,
                            weight: .bold
                        )
                    )
                    .foregroundStyle(.white)
                    .padding(
                        .horizontal,
                        5
                    )
                    .frame(
                        minWidth: 18,
                        minHeight: 18
                    )
                    .background(
                        KinColors.primary
                    )
                    .clipShape(
                        Capsule()
                    )
                    .offset(
                        x: 4,
                        y: -4
                    )
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(
            "Notifications"
        )
        .accessibilityValue(
            count == 0
                ? "No unread"
                : "\(count) unread"
        )
    }




    /// Four shortcuts; wraps to two rows at accessibility text sizes.
    var quickActionsSection: some View {

        let columns =
            Array(
                repeating:
                    GridItem(
                        .flexible(),
                        spacing: KinSpacing.medium,
                        alignment: .top
                    ),
                count:
                    dynamicTypeSize.isAccessibilitySize
                        ? 2
                        : 4
            )

        return LazyVGrid(
            columns: columns,
            spacing: KinSpacing.medium
        ) {

            KinQuickActionTile(
                title: "New Recipe",
                icon: "frying.pan.fill",
                tint: KinColors.primary,
                hint: "Opens a new recipe"
            ) {

                showingAddRecipe = true
            }

            KinQuickActionTile(
                title: "New Event",
                icon: KinIcons.gatherings,
                tint: KinColors.success,
                hint: "Plans a new event"
            ) {

                showingAddGathering = true
            }

            KinQuickActionTile(
                title: "Table Talk",
                icon: "cup.and.saucer.fill",
                tint: .orange,
                hint: "See what family and friends are cooking",
                badge: "Soon"
            ) {

                comingSoon = .tableTalk
            }

            KinQuickActionTile(
                title: "Scan Recipe",
                icon: KinIcons.camera,
                tint: .blue,
                hint: "Add a recipe from a photo",
                badge: "Soon"
            ) {

                comingSoon = .scanRecipe
            }
        }
        .alert(
            comingSoon?.title ?? "",
            isPresented: Binding(
                get: { comingSoon != nil },
                set: { if !$0 { comingSoon = nil } }
            ),
            presenting: comingSoon
        ) { _ in

            Button("OK", role: .cancel) {}

        } message: { feature in

            Text(feature.message)
        }
    }


    @ViewBuilder
    var alertsSection: some View {

        if unreadNotifications.isEmpty {

            KinCard {

                Label {

                    Text(
                        "You're all caught up."
                    )

                } icon: {

                    Image(
                        systemName: "checkmark.circle"
                    )
                }
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

        } else {

            // Newest unread first, in one grouped card.
            VStack(
                spacing: 0
            ) {

                let shown =
                    Array(
                        unreadNotifications.prefix(3)
                    )

                ForEach(
                    shown
                ) { notification in

                    homeNotificationRow(
                        notification
                    )

                    if notification.id != shown.last?.id {

                        Divider()
                            .padding(
                                .leading,
                                60
                            )
                    }
                }
            }
            .background(
                KinColors.surface
            )
            .clipShape(
                RoundedRectangle(
                    cornerRadius: KinRadius.large
                )
            )
        }
    }


    // MARK: - Notification Row

    private func homeNotificationRow(
        _ notification: KinNotification
    ) -> some View {

        let color =
            notification.type.color

        return Button {

            Task {
                await markAsRead(
                    notification
                )
            }

            guard
                notification.gatheringId != nil
            else {
                return
            }

            selectedNotification =
                notification

        } label: {

            HStack(
                alignment: .top,
                spacing: KinSpacing.medium
            ) {

                Image(
                    systemName:
                        notification.type.iconName
                )
                .font(
                    .system(
                        size: 15,
                        weight: .semibold
                    )
                )
                .foregroundStyle(
                    color
                )
                .frame(
                    width: 36,
                    height: 36
                )
                .background(
                    color.opacity(0.14)
                )
                .clipShape(
                    Circle()
                )

                VStack(
                    alignment: .leading,
                    spacing: KinSpacing.xxSmall
                ) {

                    Text(
                        notification.title
                    )
                    .font(
                        KinTypography.headline
                    )
                    .foregroundStyle(
                        KinColors.primaryText
                    )
                    .lineLimit(2)

                    if let message =
                        notification.displayMessage {

                        Text(message)
                            .font(
                                KinTypography.footnote
                            )
                            .foregroundStyle(
                                KinColors.secondaryText
                            )
                            .lineLimit(3)
                    }

                    Text(
                        notification.createdAt,
                        format:
                            .relative(
                                presentation:
                                    .named
                            )
                    )
                    .font(
                        KinTypography.caption2
                    )
                    .foregroundStyle(
                        KinColors.secondaryText
                    )
                }
                .frame(
                    maxWidth: .infinity,
                    alignment: .leading
                )

                // Unread dot
                Circle()
                    .fill(
                        KinColors.primary
                    )
                    .frame(
                        width: 9,
                        height: 9
                    )
                    .padding(
                        .top,
                        6
                    )
                    .accessibilityHidden(true)
            }
            .padding(
                KinSpacing.medium
            )
            .contentShape(
                Rectangle()
            )
        }
        .buttonStyle(.plain)
        .accessibilityElement(
            children: .combine
        )
        .accessibilityLabel(
            "Unread. \(notification.title)"
        )
        .accessibilityHint(
            notification.gatheringId == nil
                ? "Marks as read"
                : "Opens the gathering"
        )
    }
}


// MARK: - Upcoming Gatherings

private extension HomeView {

    @ViewBuilder
    var upcomingGatheringsSection:
        some View {

        if isLoadingGatherings
            && upcomingGatherings.isEmpty {

            KinCard {

                HStack(
                    spacing: KinSpacing.medium
                ) {

                    ProgressView()

                    Text(
                        "Loading gatherings..."
                    )
                    .font(
                        KinTypography.body
                    )
                    .foregroundStyle(
                        KinColors.secondaryText
                    )
                }
                .frame(
                    maxWidth: .infinity,
                    alignment: .leading
                )
            }

        } else if upcomingGatherings.isEmpty {

            KinCard {

                HStack(
                    spacing: KinSpacing.medium
                ) {

                    Image(
                        systemName: "calendar.badge.plus"
                    )
                    .font(
                        .system(
                            size: 26,
                            weight: .semibold
                        )
                    )
                    .foregroundStyle(
                        KinColors.success
                    )

                    VStack(
                        alignment: .leading,
                        spacing: KinSpacing.xSmall
                    ) {

                        Text(
                            "Nothing planned yet"
                        )
                        .font(
                            KinTypography.headline
                        )
                        .foregroundStyle(
                            KinColors.primaryText
                        )

                        Text(
                            "Tap New Event to bring everyone to the table."
                        )
                        .font(
                            KinTypography.footnote
                        )
                        .foregroundStyle(
                            KinColors.secondaryText
                        )
                    }
                }
                .frame(
                    maxWidth: .infinity,
                    alignment: .leading
                )
            }

        } else {

            VStack(
                spacing: KinSpacing.medium
            ) {

                ForEach(
                    upcomingGatherings
                ) { item in

                    homeGatheringCard(
                        item
                    )
                }
            }
        }
    }


    func homeGatheringCard(
        _ item: GatheringListItem
    ) -> some View {

        let gathering =
            item.gathering

        let unread =
            notifications.unread(
                forGathering: gathering.id
            )

        let location =
            cleaned(
                gathering.location
            )

        let dateText =
            HomeView.eventDateText(
                gathering.startsAt
            )

        return Button {

            selectedGatheringId =
                gathering.id

        } label: {

            HStack(
                spacing: 0
            ) {

                VStack(
                    alignment: .leading,
                    spacing: KinSpacing.xSmall
                ) {

                    HStack(
                        alignment: .top,
                        spacing: KinSpacing.small
                    ) {

                        Text(
                            gathering.name
                        )
                        .font(
                            KinTypography.headline
                        )
                        .foregroundStyle(
                            KinColors.primaryText
                        )
                        .lineLimit(2)
                        .frame(
                            maxWidth: .infinity,
                            alignment: .leading
                        )

                        relationshipPill(
                            for: item
                        )
                    }

                    Label(
                        dateText,
                        systemImage: KinIcons.calendar
                    )
                    .font(
                        KinTypography.footnote
                    )
                    .foregroundStyle(
                        KinColors.secondaryText
                    )

                    if let location {

                        Label(
                            location,
                            systemImage: "mappin"
                        )
                        .font(
                            KinTypography.footnote
                        )
                        .foregroundStyle(
                            KinColors.secondaryText
                        )
                        .lineLimit(1)
                    }

                    if let latest =
                        unread.first {

                        HStack(
                            alignment: .top,
                            spacing: KinSpacing.small
                        ) {

                            KinCardNotificationLine(
                                notification: latest
                            )
                            .frame(
                                maxWidth: .infinity,
                                alignment: .leading
                            )

                            if unread.count > 1 {

                                KinUnreadIndicator(
                                    count: unread.count
                                )
                            }
                        }
                        .padding(
                            .top,
                            KinSpacing.xxSmall
                        )
                    }
                }
                .padding(
                    KinSpacing.medium
                )
                // A soft halo in the card color keeps text crisp
                // where it runs over the photo.
                .shadow(
                    color: KinColors.surface,
                    radius: 3
                )
            }
            .frame(
                minHeight: 132
            )
            .background {

                // Photo fills the card. The card color (light or dark)
                // sits behind the text on the left and fades out to
                // the right so the photo shows through.
                ZStack {

                    GatheringCardImage(
                        path: gathering.coverImagePath,
                        size: nil
                    )

                    LinearGradient(
                        stops: [
                            .init(
                                color: KinColors.surface.opacity(0.92),
                                location: 0
                            ),
                            .init(
                                color: KinColors.surface.opacity(0.82),
                                location: 0.45
                            ),
                            .init(
                                color: KinColors.surface.opacity(0.35),
                                location: 0.75
                            ),
                            .init(
                                color: KinColors.surface.opacity(0.1),
                                location: 1
                            )
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                }
            }
            .clipShape(
                RoundedRectangle(
                    cornerRadius: KinRadius.large
                )
            )
            .shadow(
                color: .black.opacity(0.05),
                radius: 6,
                y: 2
            )
            .contentShape(
                RoundedRectangle(
                    cornerRadius: KinRadius.large
                )
            )
        }
        .buttonStyle(.plain)
        .accessibilityElement(
            children: .ignore
        )
        .accessibilityLabel(
            [
                gathering.name,
                item.relationship.displayName,
                dateText,
                location,
                unread.isEmpty
                    ? nil
                    : "\(unread.count) new update\(unread.count == 1 ? "" : "s")"
            ]
            .compactMap { $0 }
            .joined(separator: ", ")
        )
        .accessibilityHint(
            "Opens the gathering"
        )
        .accessibilityAddTraits(
            .isButton
        )
    }


    func relationshipPill(
        for item: GatheringListItem
    ) -> some View {

        let color =
            relationshipColor(
                for: item
            )

        return Text(
            item.relationship
                .displayName
        )
        .font(
            .system(
                size: 12,
                weight: .bold
            )
        )
        .foregroundStyle(.white)
        .padding(
            .horizontal,
            KinSpacing.small
        )
        .padding(
            .vertical,
            KinSpacing.xSmall
        )
        .background(
            color
        )
        .clipShape(
            Capsule()
        )
        .fixedSize()
    }
}


// MARK: - Recent Recipes & Cookbooks

private extension HomeView {

    @ViewBuilder
    var recentRecipesSection: some View {

        if !hasLoadedDiscovery {

            ProgressView()
                .frame(
                    maxWidth: .infinity,
                    minHeight: 120
                )

        } else if recentRecipes.isEmpty {

            homeEmptyPrompt(
                icon: KinIcons.recipes,
                title: "Your recipes will show up here",
                message: "Add a family favorite to get started.",
                buttonTitle: "Add a Recipe"
            ) {
                showingAddRecipe = true
            }

        } else {

            ScrollView(
                .horizontal,
                showsIndicators: false
            ) {

                LazyHStack(
                    alignment: .top,
                    spacing: KinSpacing.medium
                ) {

                    ForEach(recentRecipes) { recipe in

                        recipeTile(recipe)
                    }
                }
                .padding(
                    .vertical,
                    KinSpacing.xSmall
                )
            }
            .scrollClipDisabled()
        }
    }


    func recipeTile(
        _ recipe: Recipe
    ) -> some View {

        let details =
            HomeView.recipeDetails(
                minutes: recipe.totalTimeMinutes,
                formattedTime: recipe.formattedTotalTime,
                category: recipe.category
            )

        return Button {

            selectedRecipeId = recipe.id

        } label: {

            VStack(
                alignment: .leading,
                spacing: KinSpacing.xSmall
            ) {

                KinStorageImage(
                    bucket: "recipe-photos",
                    path: recipe.photoPath
                )
                .frame(
                    width: 124,
                    height: 124
                )
                .clipShape(
                    RoundedRectangle(
                        cornerRadius: KinRadius.medium
                    )
                )

                Text(recipe.name)
                    .font(KinTypography.footnote)
                    .fontWeight(.semibold)
                    .foregroundStyle(KinColors.primaryText)
                    .lineLimit(
                        2,
                        reservesSpace: true
                    )

                if let details {

                    Text(details)
                        .font(KinTypography.caption2)
                        .foregroundStyle(KinColors.secondaryText)
                        .lineLimit(1)
                }
            }
            .frame(
                width: 124,
                alignment: .leading
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            [recipe.name, details]
                .compactMap { $0 }
                .joined(separator: ", ")
        )
        .accessibilityHint("Opens the recipe")
        .accessibilityAddTraits(.isButton)
    }


    @ViewBuilder
    var cookbooksSection: some View {

        if !hasLoadedDiscovery {

            EmptyView()

        } else if cookbooks.isEmpty {

            homeEmptyPrompt(
                icon: KinIcons.cookbooks,
                title: "Gather your favorites",
                message: "Make a cookbook for the recipes your family loves most.",
                buttonTitle: "Go to Cookbooks"
            ) {
                selectTab(.cookbooks)
            }

        } else {

            ScrollView(
                .horizontal,
                showsIndicators: false
            ) {

                LazyHStack(
                    spacing: KinSpacing.medium
                ) {

                    ForEach(cookbooks) { cookbook in

                        cookbookCard(cookbook)
                    }
                }
                .padding(
                    .vertical,
                    KinSpacing.xSmall
                )
            }
            .scrollClipDisabled()
        }
    }


    /// Cover photo with the title written over it, like a book cover.
    func cookbookCard(
        _ cookbook: Cookbook
    ) -> some View {

        Button {

            selectedCookbookId = cookbook.id

        } label: {

            KinStorageImage(
                bucket: "cookbook-covers",
                path: cookbook.coverPath,
                placeholderIcon: KinIcons.cookbooks
            )
            .overlay(
                alignment: .bottomLeading
            ) {

                ZStack(
                    alignment: .bottomLeading
                ) {

                    LinearGradient(
                        colors: [
                            .black.opacity(0),
                            .black.opacity(0.7)
                        ],
                        startPoint: .center,
                        endPoint: .bottom
                    )

                    Text(cookbook.name)
                        .font(KinTypography.title3)
                        .foregroundStyle(.white)
                        .lineLimit(2)
                        .shadow(
                            color: .black.opacity(0.4),
                            radius: 3,
                            y: 1
                        )
                        .padding(KinSpacing.medium)
                }
            }
            .frame(
                width: 220,
                height: 140
            )
            .clipShape(
                RoundedRectangle(
                    cornerRadius: KinRadius.large
                )
            )
            .shadow(
                color: .black.opacity(0.08),
                radius: 6,
                y: 2
            )
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(cookbook.name), cookbook")
        .accessibilityHint("Opens the cookbook")
        .accessibilityAddTraits(.isButton)
    }


    func homeEmptyPrompt(
        icon: String,
        title: String,
        message: String,
        buttonTitle: String,
        action: @escaping () -> Void
    ) -> some View {

        KinCard {

            HStack(
                alignment: .top,
                spacing: KinSpacing.medium
            ) {

                Image(systemName: icon)
                    .font(
                        .system(
                            size: 24,
                            weight: .semibold
                        )
                    )
                    .foregroundStyle(KinColors.primary)
                    .accessibilityHidden(true)

                VStack(
                    alignment: .leading,
                    spacing: KinSpacing.xSmall
                ) {

                    Text(title)
                        .font(KinTypography.headline)
                        .foregroundStyle(KinColors.primaryText)

                    Text(message)
                        .font(KinTypography.footnote)
                        .foregroundStyle(KinColors.secondaryText)

                    Button(
                        buttonTitle,
                        action: action
                    )
                    .font(KinTypography.subheadline)
                    .foregroundStyle(KinColors.primary)
                    .padding(.top, KinSpacing.xSmall)
                }
            }
            .frame(
                maxWidth: .infinity,
                alignment: .leading
            )
        }
    }
}


// MARK: - Home Data

private extension HomeView {
    
    // MARK: - Load Home

    @MainActor
    func loadHome() async {

        isLoadingGatherings = true

        do {
            notifications =
                try await NotificationService
                    .fetchNotifications()
        } catch {
            if !(error is CancellationError) {
                print(
                    "HOME NOTIFICATION LOAD ERROR:",
                    error.localizedDescription
                )
            }
        }

        do {
            let gatherings =
                try await GatheringService
                    .fetchUpcomingGatheringItems()

            upcomingGatherings =
                Array(
                    gatherings.prefix(3)
                )

        } catch {
            if !(error is CancellationError) {
                print(
                    "HOME GATHERINGS LOAD ERROR:",
                    error.localizedDescription
                )
            }
        }

        isLoadingGatherings = false

        ringBellIfUnread()

        await loadDiscovery()
    }

    // MARK: - Load Recipes & Cookbooks

    /// Recently opened recipes (then the user's newest) and their
    /// cookbooks. Everything loads through Supabase, so RLS decides
    /// what's visible: nothing unauthorized can appear.
    @MainActor
    func loadDiscovery() async {

        defer {
            hasLoadedDiscovery = true
        }

        do {

            let own =
                try await RecipeService
                    .fetchCurrentUserRecipes()

            var viewedIds: [UUID] = []

            if let userId =
                SupabaseManager.client.auth.currentUser?.id {

                viewedIds =
                    RecentRecipesStore()
                        .recipeIds(for: userId)
            }

            let viewed =
                try await RecipeService
                    .fetchRecipes(ids: viewedIds)

            recentRecipes =
                RecentRecipesStore.merged(
                    viewedIds: viewedIds,
                    viewed: viewed,
                    own: own,
                    limit: 10
                )

        } catch {
            if !(error is CancellationError) {
                print(
                    "HOME RECIPES LOAD ERROR:",
                    error.localizedDescription
                )
            }
        }

        do {

            cookbooks =
                Array(
                    try await CookbookService
                        .fetchCurrentUserCookbooks()
                        .prefix(6)
                )

        } catch {
            if !(error is CancellationError) {
                print(
                    "HOME COOKBOOKS LOAD ERROR:",
                    error.localizedDescription
                )
            }
        }
    }

    // MARK: - Bell

    /// Rings the bell a few seconds after Home loads, once the screen
    /// has settled, if anything is still unread.
    func ringBellIfUnread() {

        guard
            !unreadNotifications.isEmpty,
            !reduceMotion
        else {
            return
        }

        Task {

            try? await Task.sleep(
                for: .seconds(3)
            )

            guard !unreadNotifications.isEmpty else {
                return
            }

            bellRings += 1
        }
    }

    // MARK: - Mark Read

    @MainActor
    func markAsRead(
        _ notification: KinNotification
    ) async {

        do {
            try await NotificationService
                .markAsRead(
                    notificationId:
                        notification.id
                )

            notifications =
                try await NotificationService
                    .fetchNotifications()

        } catch {
            if !(error is CancellationError) {
                print(
                    "HOME NOTIFICATION MARK READ ERROR:",
                    error.localizedDescription
                )
            }
        }
    }

}

// MARK: - Gathering Helpers

private extension HomeView {

    func relationshipColor(
        for item: GatheringListItem
    ) -> Color {

        switch item.relationship {

        case .hosting:
            return KinColors.primary

        case .going:
            return KinColors.success

        case .invited:
            return KinColors.warning
        }
    }


    func cleaned(
        _ value: String?
    ) -> String? {

        guard let value else {

            return nil
        }

        let cleanedValue =
            value.trimmingCharacters(
                in:
                    .whitespacesAndNewlines
            )

        return cleanedValue.isEmpty
            ? nil
            : cleanedValue
    }
}


// MARK: - Event Dates

extension HomeView {


    /// "30 min · Dinner", just one of them, or nil when neither is set.
    nonisolated static func recipeDetails(
        minutes: Int,
        formattedTime: String,
        category: String?
    ) -> String? {

        let category =
            category?.trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        let parts =
            [
                minutes > 0 ? formattedTime : nil,
                (category?.isEmpty ?? true) ? nil : category
            ]
            .compactMap { $0 }

        return parts.isEmpty
            ? nil
            : parts.joined(separator: " · ")
    }


    /// "Today · 6:00 PM", "Tomorrow · …", "Sunday · …" within the
    /// week, otherwise "Sun, Oct 26 · 6:00 PM", so far-off events are
    /// never mistaken for this week's.
    nonisolated static func eventDateText(
        _ date: Date,
        now: Date = .now,
        calendar: Calendar = .current
    ) -> String {

        let time =
            date.formatted(
                date: .omitted,
                time: .shortened
            )

        let startOfToday =
            calendar.startOfDay(
                for: now
            )

        let days =
            calendar.dateComponents(
                [.day],
                from: startOfToday,
                to: calendar.startOfDay(
                    for: date
                )
            )
            .day ?? 0

        let day: String

        switch days {

        case 0:
            day = "Today"

        case 1:
            day = "Tomorrow"

        case 2...6:
            day =
                date.formatted(
                    .dateTime
                        .weekday(.wide)
                )

        default:
            day =
                date.formatted(
                    .dateTime
                        .weekday(.abbreviated)
                        .month(.abbreviated)
                        .day()
                )
        }

        return "\(day) · \(time)"
    }
}


#Preview {

    HomeView()
}

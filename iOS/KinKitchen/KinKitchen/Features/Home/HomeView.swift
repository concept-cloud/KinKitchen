//
//  HomeView.swift
//  KinKitchen
//
//  Created by Greg Hudler on 8/26/26.
//

import SwiftUI


struct HomeView: View {
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    /// Switches the app's main tab (ContentView owns the tab bar).
    var selectTab: (KinTab) -> Void = { _ in }

    @State private var showingAddRecipe = false
    @State private var showingAddGathering = false
    @State private var comingSoon: ComingSoonFeature?
    
    @State private var upcomingGatherings:
    [GatheringListItem] = []
    
    @State private var isLoadingGatherings = true
    
    @State private var firstName = ""
    @State private var notifications:
    [KinNotification] = []
    @State private var selectedGatheringId: UUID?
    @State private var selectedNotification: KinNotification?
    @State private var showingAllNotifications = false

    
    var body: some View {
        
        NavigationStack {
            
            ScrollView {
                
                VStack(
                    alignment: .leading,
                    spacing: KinSpacing.xLarge
                ) {

                    // MARK: - Header

                    homeHeader

                    // MARK: - Welcome

                    greeting

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
            .background(
                homeBackground
            )
            .toolbar(
                .hidden,
                for: .navigationBar
            )
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


    /// Logo at the center, notifications bell on the trailing edge.
    var homeHeader: some View {

        ZStack(
            alignment: .top
        ) {

            KinLogo()
                .frame(
                    maxWidth: .infinity
                )

            HStack {

                Spacer()

                notificationsBell
            }
        }
        .padding(
            .top,
            KinSpacing.small
        )
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
            .frame(
                width: 44,
                height: 44
            )
            .background(
                KinColors.surface
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


    var greeting: some View {

        VStack(
            spacing: KinSpacing.xSmall
        ) {

            Text("Welcome back,")
                .font(
                    KinTypography.body
                )
                .foregroundStyle(
                    KinColors.secondaryText
                )

            Text(
                firstName.isEmpty
                ? "Chef"
                : firstName
            )
            .font(
                KinTypography.largeTitle
            )
            .foregroundStyle(
                KinColors.primaryText
            )
            .lineLimit(1)
            .minimumScaleFactor(0.6)

            Text("What's cookin' today?")
                .font(
                    KinTypography.body
                )
                .foregroundStyle(
                    KinColors.secondaryText
                )
        }
        .multilineTextAlignment(.center)
        .frame(
            maxWidth: .infinity
        )
        .accessibilityElement(
            children: .combine
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

                HStack(
                    spacing: KinSpacing.medium
                ) {

                    Image(
                        systemName: "bell"
                    )
                    .font(
                        .system(size: 20)
                    )
                    .foregroundStyle(
                        KinColors.secondaryText
                    )

                    Text(
                        "You're all caught up."
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

        } else {

            VStack(
                spacing: KinSpacing.medium
            ) {
                ForEach(
                    unreadNotifications.prefix(3)
                ) { notification in
                    homeNotificationCard(
                        notification
                    )
                }
            }
        }
    }


    // MARK: - Notification Card

    private func homeNotificationCard(
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

            KinCard {

                HStack(
                    alignment: .top,
                    spacing: KinSpacing.medium
                ) {

                    ZStack {

                        Circle()
                            .fill(
                                color.opacity(0.15)
                            )
                            .frame(
                                width: 44,
                                height: 44
                            )

                        Image(
                            systemName:
                                notification.type.iconName
                        )
                        .foregroundStyle(
                            color
                        )
                    }

                    VStack(
                        alignment: .leading,
                        spacing: KinSpacing.xSmall
                    ) {

                        HStack {

                            Text(
                                notification.title
                            )
                            .font(
                                KinTypography.headline
                            )
                            .foregroundStyle(
                                KinColors.primaryText
                            )

                            Spacer()

                            Image(systemName: "bell.fill")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundStyle(
                                    KinColors.primary
                                )
                        }

                        if let message =
                            notification.displayMessage {

                            Text(message)
                                .font(
                                    KinTypography.body
                                )
                                .foregroundStyle(
                                    KinColors.secondaryText
                                )
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
                            KinTypography.caption
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
        }
        .buttonStyle(.plain)
    }
}


// MARK: - Upcoming Gatherings

private extension HomeView {

    @ViewBuilder
    var upcomingGatheringsSection:
        some View {

        if isLoadingGatherings {

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
            }

        } else if upcomingGatherings.isEmpty {

            KinCard {

                VStack(
                    alignment: .leading,
                    spacing: KinSpacing.small
                ) {

                    Text(
                        "No upcoming gatherings"
                    )
                    .font(
                        KinTypography.title3
                    )
                    .foregroundStyle(
                        KinColors.primaryText
                    )

                    Text(
                        "Your upcoming community meals will appear here."
                    )
                    .font(
                        KinTypography.body
                    )
                    .foregroundStyle(
                        KinColors.secondaryText
                    )
                }
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

        let unreadCount =
            unread.count

        return Button {

            selectedGatheringId =
                gathering.id

        } label: {

            KinCard {

                HStack(
                    spacing: KinSpacing.medium
                ) {

                    Image(
                        systemName:
                            gatheringIcon(
                                for: item
                            )
                    )
                    .font(
                        .system(
                            size: 22,
                            weight: .semibold
                        )
                    )
                    .foregroundStyle(
                        relationshipColor(
                            for: item
                        )
                    )
                    .frame(
                        width: 44,
                        height: 44
                    )
                    .background(
                        relationshipColor(
                            for: item
                        )
                        .opacity(0.10)
                    )
                    .clipShape(
                        Circle()
                    )

                    VStack(
                        alignment: .leading,
                        spacing: KinSpacing.xSmall
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

                        Text(
                            formattedGatheringDate(
                                gathering.startsAt
                            )
                        )
                        .font(
                            KinTypography.caption
                        )
                        .foregroundStyle(
                            KinColors.secondaryText
                        )

                        if
                            let location =
                                cleaned(
                                    gathering.location
                                )
                        {

                            Text(
                                location
                            )
                            .font(
                                KinTypography.caption
                            )
                            .foregroundStyle(
                                KinColors.secondaryText
                            )
                            .lineLimit(1)
                        }

                        if let latest =
                            unread.first {

                            KinCardNotificationLine(
                                notification: latest
                            )
                        }
                    }
                    .frame(
                        maxWidth: .infinity,
                        alignment: .leading
                    )

                    VStack(
                        alignment: .trailing,
                        spacing: KinSpacing.small
                    ) {

                        if unreadCount > 0 {

                            KinUnreadIndicator(
                                count: unreadCount
                            )
                        }

                        Text(
                            item.relationship
                                .displayName
                        )
                        .font(
                            KinTypography.caption
                        )
                        .foregroundStyle(
                            relationshipColor(
                                for: item
                            )
                        )
                        .padding(
                            .horizontal,
                            KinSpacing.small
                        )
                        .padding(
                            .vertical,
                            KinSpacing.xSmall
                        )
                        .background(
                            relationshipColor(
                                for: item
                            )
                            .opacity(0.10)
                        )
                        .clipShape(
                            Capsule()
                        )
                    }
                    .fixedSize(
                        horizontal: true,
                        vertical: false
                    )
                }
            }
        }
        .buttonStyle(.plain)
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
            let profile =
                try await ProfileService
                    .fetchCurrentProfile()

            firstName =
                profile.firstName?
                    .trimmingCharacters(
                        in: .whitespacesAndNewlines
                    )
                ?? ""

        } catch {
            if !(error is CancellationError) {
                print(
                    "HOME PROFILE LOAD ERROR:",
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
            return .green

        case .invited:
            return KinColors.warning
        }
    }


    func gatheringIcon(
        for item: GatheringListItem
    ) -> String {

        switch item.relationship {

        case .hosting:
            return "house.fill"

        case .going:
            return "person.3.fill"

        case .invited:
            return "envelope.fill"
        }
    }


    func formattedGatheringDate(
        _ date: Date
    ) -> String {

        date.formatted(
            .dateTime
                .weekday(.wide)
                .hour()
                .minute()
        )
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


#Preview {

    HomeView()
}

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
    @State private var bellRings = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
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
                alignment: .top,
                spacing: KinSpacing.medium
            ) {

                GatheringCardImage(
                    path: gathering.coverImagePath,
                    size: 84
                )

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
            }
            .padding(
                KinSpacing.medium
            )
            .background(
                KinColors.surface
            )
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

        if !unreadNotifications.isEmpty && !reduceMotion {
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

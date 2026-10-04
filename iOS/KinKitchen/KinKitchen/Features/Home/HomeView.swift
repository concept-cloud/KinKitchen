//
//  HomeView.swift
//  KinKitchen
//
//  Created by Greg Hudler on 8/26/26.
//

import SwiftUI


struct HomeView: View {
    @Environment(\.scenePhase) private var scenePhase
    
    @State private var showingAddRecipe = false
    
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
                    
                    // MARK: - Welcome
                    
                    VStack(
                        alignment: .leading,
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
                        
                        Text("What's cookin'?")
                            .font(
                                KinTypography.body
                            )
                            .foregroundStyle(
                                KinColors.secondaryText
                            )
                    }
                    
                    // MARK: - Alerts
                    
                    KinSectionHeader(
                        title: "Alerts",
                        actionTitle: "View All"
                    ) {
                        showingAllNotifications = true
                    }

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
                    
                    // MARK: - Upcoming Gatherings
                    
                    KinSectionHeader(
                        title: "Upcoming Gatherings"
                    )
                    
                    upcomingGatheringsSection
                    
                    
                    // MARK: - Quick Actions
                    
                    KinSectionHeader(
                        title: "Quick Actions"
                    )
                    
                    HStack(
                        spacing: KinSpacing.medium
                    ) {
                        
                        // Add Recipe
                        
                        KinIconButton(
                            icon: KinIcons.add
                        ) {
                            
                            showingAddRecipe = true
                        }
                        
                        
                        // Recipes
                        
                        KinIconButton(
                            icon: KinIcons.recipes
                        ) {
                            
                            print(
                                "Recipes tapped"
                            )
                        }
                        
                        
                        // Gatherings
                        
                        KinIconButton(
                            icon: KinIcons.gatherings
                        ) {
                            
                            print(
                                "Gatherings tapped"
                            )
                        }
                        
                    }
                    
                    
                    // MARK: - My Collections
                    
                    KinSectionHeader(
                        title: "My Collections"
                    )
                    
                    KinEmptyState(
                        icon: KinIcons.cookbooks,
                        title: "No Collections Yet",
                        message:
                            "Your saved recipes and cookbooks will appear here."
                    )
                    
                    
                    // MARK: - For You
                    
                    KinSectionHeader(
                        title: "For You"
                    )
                    
                    KinCard {
                        
                        Text(
                            "Personalized recommendations will appear here."
                        )
                        .font(
                            KinTypography.body
                        )
                        .foregroundStyle(
                            KinColors.secondaryText
                        )
                    }
                }
                .padding(
                    KinSpacing.large
                )
            }
            .background(
                KinColors.background
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

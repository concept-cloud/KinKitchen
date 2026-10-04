//
//  NotificationsView.swift
//  KinKitchen
//
//  Created by Greg Hudler on 9/20/26.
//

import SwiftUI

struct NotificationsView: View {

    // MARK: - State

    @State private var notifications:
        [KinNotification] = []

    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var selectedGatheringId: UUID?

    // MARK: - Body

    var body: some View {

        ZStack {

            KinColors.background
                .ignoresSafeArea()

            if isLoading && notifications.isEmpty {

                loadingState

            } else if let errorMessage {

                errorState(
                    message: errorMessage
                )

            } else if notifications.isEmpty {

                emptyState

            } else {

                notificationList
            }
        }
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {

            if !unreadNotifications.isEmpty {

                ToolbarItem(
                    placement: .topBarTrailing
                ) {

                    Button("Mark All Read") {

                        Task {
                            await markAllAsRead()
                        }
                    }
                    .font(
                        KinTypography.subheadline
                    )
                    .foregroundStyle(
                        KinColors.primary
                    )
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
        .task {
            await loadNotifications()
        }
        .refreshable {
            await loadNotifications()
        }
    }

    // MARK: - Unread / Read

    private var unreadNotifications:
        [KinNotification] {

        notifications.filter {
            !$0.isRead
        }
    }

    private var readNotifications:
        [KinNotification] {

        notifications.filter {
            $0.isRead
        }
    }

    // MARK: - Notification List

    private var notificationList: some View {

        ScrollView {

            LazyVStack(
                alignment: .leading,
                spacing: KinSpacing.medium
            ) {

                if !unreadNotifications.isEmpty {

                    sectionTitle(
                        "New"
                    )

                    ForEach(unreadNotifications) {
                        notification in

                        notificationCard(
                            notification
                        )
                    }
                }

                if !readNotifications.isEmpty {

                    sectionTitle(
                        "Earlier"
                    )
                    .padding(
                        .top,
                        unreadNotifications.isEmpty
                            ? 0
                            : KinSpacing.medium
                    )

                    ForEach(readNotifications) {
                        notification in

                        notificationCard(
                            notification
                        )
                    }
                }
            }
            .padding(
                KinSpacing.large
            )
        }
    }

    // MARK: - Section Title

    private func sectionTitle(
        _ title: String
    ) -> some View {

        Text(title)
            .font(
                KinTypography.headline
            )
            .foregroundStyle(
                KinColors.secondaryText
            )
    }

    // MARK: - Notification Card

    private func notificationCard(
        _ notification: KinNotification
    ) -> some View {

        Button {

            openNotification(
                notification
            )

        } label: {

            KinCard {

                HStack(
                    alignment: .top,
                    spacing: KinSpacing.medium
                ) {

                    notificationIcon(
                        notification
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
                                notification.title
                            )
                            .font(
                                notification.isRead
                                    ? KinTypography.body
                                    : KinTypography.headline
                            )
                            .foregroundStyle(
                                KinColors.primaryText
                            )
                            .multilineTextAlignment(
                                .leading
                            )

                            Spacer()

                            readStateButton(
                                notification
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
                                .multilineTextAlignment(
                                    .leading
                                )
                        }

                        Text(
                            formattedDate(
                                notification.createdAt
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
                .opacity(
                    notification.isRead
                        ? 0.7
                        : 1
                )
            }
            // Unread tint and accent bar
            .overlay(
                alignment: .leading
            ) {

                if !notification.isRead {

                    ZStack(
                        alignment: .leading
                    ) {

                        notification.type.color
                            .opacity(0.06)

                        Rectangle()
                            .fill(
                                notification.type.color
                            )
                            .frame(
                                width: 4
                            )
                    }
                    .allowsHitTesting(false)
                }
            }
            .clipShape(
                RoundedRectangle(
                    cornerRadius:
                        KinRadius.large
                )
            )
        }
        .buttonStyle(.plain)
        .accessibilityValue(
            notification.isRead
                ? "Read"
                : "Unread"
        )
    }


    // MARK: - Read State Button

    private func readStateButton(
        _ notification: KinNotification
    ) -> some View {

        Button {

            Task {
                await toggleReadState(
                    notification
                )
            }

        } label: {

            Image(
                systemName:
                    notification.isRead
                        ? "bell"
                        : "bell.fill"
            )
            .font(
                .system(size: 20)
            )
            .foregroundStyle(
                notification.isRead
                    ? KinColors.secondaryText
                    : KinColors.primary
            )
            .frame(
                width: 32,
                height: 32
            )
            .contentShape(
                Rectangle()
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(
            notification.isRead
                ? "Mark as unread"
                : "Mark as read"
        )
    }
    // MARK: - Notification Icon

    private func notificationIcon(
        _ notification: KinNotification
    ) -> some View {

        let color =
            notification.type.color

        return ZStack {

            Circle()
                .fill(
                    notification.isRead
                        ? KinColors.background
                        : color.opacity(0.15)
                )
                .frame(
                    width: 44,
                    height: 44
                )

            Image(
                systemName:
                    notification.type.iconName
            )
            .font(
                .system(size: 18)
            )
            .foregroundStyle(
                notification.isRead
                    ? KinColors.secondaryText
                    : color
            )
        }
    }

    // MARK: - Loading State

    private var loadingState: some View {

        VStack(
            spacing: KinSpacing.medium
        ) {

            ProgressView()
                .tint(
                    KinColors.primary
                )

            Text(
                "Loading notifications..."
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
            maxHeight: .infinity
        )
    }

    // MARK: - Empty State

    private var emptyState: some View {

        KinEmptyState(
            icon: "bell",
            title: "No Notifications",
            message:
                "Your gathering notifications and past alerts will appear here."
        )
        .frame(
            maxWidth: .infinity,
            maxHeight: .infinity
        )
        .padding(
            KinSpacing.large
        )
    }

    // MARK: - Error State

    private func errorState(
        message: String
    ) -> some View {

        VStack(
            spacing: KinSpacing.large
        ) {

            Spacer()

            Image(
                systemName:
                    "exclamationmark.triangle"
            )
            .font(
                .system(size: 44)
            )
            .foregroundStyle(
                KinColors.error
            )

            Text(
                "Unable to Load Notifications"
            )
            .font(
                KinTypography.title
            )
            .foregroundStyle(
                KinColors.primaryText
            )

            Text(message)
                .font(
                    KinTypography.body
                )
                .foregroundStyle(
                    KinColors.secondaryText
                )
                .multilineTextAlignment(
                    .center
                )

            Button {

                Task {
                    await loadNotifications()
                }

            } label: {

                Text("Try Again")
                    .font(
                        KinTypography.body
                    )
                    .foregroundStyle(
                        KinColors.background
                    )
                    .frame(
                        maxWidth: .infinity
                    )
                    .padding(
                        .vertical,
                        KinSpacing.medium
                    )
                    .background(
                        KinColors.primary
                    )
                    .clipShape(
                        RoundedRectangle(
                            cornerRadius:
                                KinRadius.medium
                        )
                    )
            }
            .buttonStyle(.plain)

            Spacer()
        }
        .padding(
            KinSpacing.xLarge
        )
    }

    // MARK: - Open Notification

    private func openNotification(
        _ notification: KinNotification
    ) {

        if !notification.isRead {

            Task {
                await markAsRead(
                    notification
                )
            }
        }

        guard
            let gatheringId =
                notification.gatheringId
        else {
            return
        }

        selectedGatheringId =
            gatheringId
    }

    // MARK: - Mark Read

    @MainActor
    private func markAsRead(
        _ notification: KinNotification
    ) async {

        do {

            try await NotificationService
                .markAsRead(
                    notificationId:
                        notification.id
                )

            await refreshNotifications()

        } catch is CancellationError {

            return

        } catch {

            print(
                "NOTIFICATION MARK READ ERROR:",
                error.localizedDescription
            )
        }
    }

    // MARK: - Mark All Read

    @MainActor
    private func markAllAsRead() async {

        do {

            try await NotificationService
                .markAllAsRead()

            await refreshNotifications()

        } catch is CancellationError {

            return

        } catch {

            print(
                "NOTIFICATION MARK ALL READ ERROR:",
                error.localizedDescription
            )
        }
    }

    // MARK: - Toggle Read State

    @MainActor
    private func toggleReadState(
        _ notification: KinNotification
    ) async {

        do {

            if notification.isRead {

                try await NotificationService
                    .markAsUnread(
                        notificationId:
                            notification.id
                    )

            } else {

                try await NotificationService
                    .markAsRead(
                        notificationId:
                            notification.id
                    )
            }

            await refreshNotifications()

        } catch is CancellationError {

            return

        } catch {

            print(
                "NOTIFICATION READ STATE ERROR:",
                error.localizedDescription
            )
        }
    }

    // MARK: - Refresh Notifications

    /// Reloads without showing the loading state, used
    /// after read-state changes.
    @MainActor
    private func refreshNotifications() async {

        do {

            notifications =
                try await NotificationService
                    .fetchNotifications()

        } catch is CancellationError {

            return

        } catch {

            print(
                "NOTIFICATION REFRESH ERROR:",
                error.localizedDescription
            )
        }
    }

    // MARK: - Load Notifications

    @MainActor
    private func loadNotifications() async {

        isLoading = true
        errorMessage = nil

        defer {
            isLoading = false
        }

        do {

            notifications =
                try await NotificationService
                    .fetchNotifications()

        } catch is CancellationError {

            return

        } catch {

            errorMessage =
                "Please check your connection and try again."

            print(
                "NOTIFICATION LOAD ERROR:",
                error.localizedDescription
            )
        }
    }

    // MARK: - Date Formatting

    private func formattedDate(
        _ date: Date
    ) -> String {

        let calendar =
            Calendar.current

        if calendar.isDateInToday(
            date
        ) {

            return date.formatted(
                date: .omitted,
                time: .shortened
            )
        }

        if calendar.isDateInYesterday(
            date
        ) {

            return "Yesterday, \(date.formatted(date: .omitted, time: .shortened))"
        }

        return date.formatted(
            date: .abbreviated,
            time: .shortened
        )
    }
}

// MARK: - Preview

#Preview {

    NavigationStack {
        NotificationsView()
    }
}

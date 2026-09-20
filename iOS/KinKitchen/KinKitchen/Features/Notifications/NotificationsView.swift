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

    // MARK: - Body

    var body: some View {

        ZStack {

            KinColors.background
                .ignoresSafeArea()

            if isLoading {

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
        .task {
            await loadNotifications()
        }
        .refreshable {
            await loadNotifications()
        }
    }

    // MARK: - Notification List

    private var notificationList: some View {

        ScrollView {

            LazyVStack(
                spacing: KinSpacing.medium
            ) {

                ForEach(notifications) {
                    notification in

                    notificationCard(
                        notification
                    )
                }
            }
            .padding(
                KinSpacing.large
            )
        }
    }

    // MARK: - Notification Card

    private func notificationCard(
        _ notification: KinNotification
    ) -> some View {

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

                        if !notification.isRead {

                            Circle()
                                .fill(
                                    KinColors.primary
                                )
                                .frame(
                                    width: 8,
                                    height: 8
                                )
                        }
                    }

                    if
                        let message =
                            notification.message,
                        !message.isEmpty
                    {

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
    }

    // MARK: - Notification Icon

    private func notificationIcon(
        _ notification: KinNotification
    ) -> some View {

        ZStack {

            Circle()
                .fill(
                    notification.isRead
                        ? KinColors.background
                        : KinColors.primary
                            .opacity(0.15)
                )
                .frame(
                    width: 44,
                    height: 44
                )

            Image(
                systemName:
                    iconName(
                        for: notification.type
                    )
            )
            .font(
                .system(size: 18)
            )
            .foregroundStyle(
                notification.isRead
                    ? KinColors.secondaryText
                    : KinColors.primary
            )
        }
    }

    // MARK: - Notification Icon Name

    private func iconName(
        for type: KinNotificationType
    ) -> String {

        switch type {

        case .gatheringInvitation:

            return "envelope.fill"

        case .invitationAccepted:

            return "checkmark.circle.fill"

        case .invitationDeclined:

            return "xmark.circle.fill"

        case .gatheringUpdated:

            return "calendar.badge.clock"

        case .dishUpdated:

            return "fork.knife"

        case .recipeShared:

            return "book.closed.fill"
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

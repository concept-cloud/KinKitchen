//
//  NotificationsView.swift
//  KinKitchen
//
//  Created by Greg Hudler on 9/20/26.
//

import SwiftUI

struct NotificationsView: View {

    @Environment(\.dismiss) private var dismiss

    // MARK: - State

    @State private var notifications:
        [KinNotification] = []

    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var selectedNotification: KinNotification?
    @State private var selectedRecipeId: UUID?

    /// Cards opened to show the photo, full message and actions.
    /// The newest unread one starts open.
    @State private var expandedIds: Set<UUID> = []

    @AppStorage(KinDietaryBackground.storageKey)
    private var backgroundChoice = KinDietaryBackground.default.rawValue
    @State private var hasAutoExpanded = false

    // MARK: - Body

    var body: some View {

        GeometryReader { geometry in

            ScrollView {

                VStack(alignment: .leading, spacing: 0) {

                    header(topInset: geometry.safeAreaInsets.top)

                    Group {
                        if isLoading && notifications.isEmpty {
                            loadingState
                                .frame(minHeight: 360)
                        } else if let errorMessage {
                            errorState(message: errorMessage)
                        } else if notifications.isEmpty {
                            emptyState
                                .frame(minHeight: 360)
                        } else {
                            notificationList
                        }
                    }
                    // Starts in the header's curve.
                    .padding(.top, -KinSpacing.medium)
                }
            }
            .scrollEdgeEffectHidden(true, for: .top)
            .ignoresSafeArea(edges: .top)
            .background(KinColors.paper.ignoresSafeArea())
        }
        .navigationBarHidden(true)

        // MARK: - Destinations

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
        .navigationDestination(
            item: $selectedRecipeId
        ) { recipeId in
            RecipeDetailView(
                recipeId: recipeId,
                onBack: { selectedRecipeId = nil }
            )
        }
        .task {
            await loadNotifications()
        }
        .refreshable {
            await refreshNotifications()
        }
        .sensoryFeedback(.selection, trigger: expandedIds)
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


    // MARK: - Header

    /// A warm kitchen photo with a curved bottom edge, the back
    /// button, title and Mark All Read.
    private func header(
        topInset: CGFloat
    ) -> some View {

        HStack(spacing: KinSpacing.medium) {

            Button {
                dismiss()
            } label: {
                Image(systemName: KinIcons.back)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(KinColors.primary)
                    .frame(width: 44, height: 44)
                    .background(.white, in: Circle())
                    .kinFloatingShadow()
            }
            .buttonStyle(.kinPressable)
            .accessibilityLabel("Back")

            Text("Notifications")
                .font(KinTypography.title)
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .kinTextOnPhoto()
                .accessibilityAddTraits(.isHeader)

            Spacer(minLength: 0)

            if !unreadNotifications.isEmpty {
                Button {
                    Task {
                        await markAllAsRead()
                    }
                } label: {
                    Label("Mark All Read", systemImage: KinIcons.check)
                        .font(KinTypography.footnote.weight(.semibold))
                        .foregroundStyle(KinColors.primary)
                        .lineLimit(1)
                        .padding(.horizontal, KinSpacing.medium)
                        .padding(.vertical, KinSpacing.small)
                        .background(.white, in: Capsule())
                        .kinFloatingShadow()
                }
                .buttonStyle(.kinPressable)
                .transition(.opacity.combined(with: .scale))
            }
        }
        .padding(.horizontal, KinSpacing.large)
        .padding(.top, topInset + KinSpacing.small)
        .padding(.bottom, KinSpacing.xxLarge + KinSpacing.medium)
        .frame(maxWidth: .infinity)
        .background {
            Color.clear
                .overlay {
                    // The user's chosen kitchen photo, as on their
                    // Dietary Profile.
                    Image(KinDietaryBackground.saved(backgroundChoice).imageName)
                        .resizable()
                        .scaledToFill()
                }
                .overlay {
                    // Keeps the white title readable.
                    LinearGradient(
                        colors: [.black.opacity(0.45), .black.opacity(0.15)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                }
                .clipShape(CurvedBottom())
                .accessibilityHidden(true)
        }
        .animation(.easeInOut(duration: 0.2), value: unreadNotifications.isEmpty)
    }


    // MARK: - Notification List

    private var notificationList: some View {

        LazyVStack(
            alignment: .leading,
            spacing: KinSpacing.medium
        ) {

            if !unreadNotifications.isEmpty {

                sectionTitle("New")

                ForEach(unreadNotifications) { notification in
                    notificationCard(notification)
                }
            }

            if !readNotifications.isEmpty {

                sectionTitle("Earlier")
                    .padding(
                        .top,
                        unreadNotifications.isEmpty ? 0 : KinSpacing.medium
                    )

                ForEach(readNotifications) { notification in
                    notificationCard(notification)
                }
            }
        }
        .padding(.horizontal, KinSpacing.large)
        .padding(.bottom, KinSpacing.xxLarge)
    }

    // MARK: - Section Title

    private func sectionTitle(
        _ title: String
    ) -> some View {

        Text(title)
            .font(KinTypography.title2)
            .foregroundStyle(KinColors.primaryText)
            .accessibilityAddTraits(.isHeader)
    }


    // MARK: - Notification Card

    private func notificationCard(
        _ notification: KinNotification
    ) -> some View {

        let isExpanded = expandedIds.contains(notification.id)
        let color = notification.type.color
        let canExpand = notification.hasDetails

        return VStack(alignment: .leading, spacing: 0) {

            // Summary: tap to open (or, without details, to mark read).
            Button {
                if canExpand {
                    toggleExpanded(notification)
                } else if !notification.isRead {
                    Task {
                        await markAsRead(notification)
                    }
                }
            } label: {

                HStack(alignment: .top, spacing: KinSpacing.medium) {

                    notificationIcon(notification)

                    VStack(alignment: .leading, spacing: KinSpacing.xSmall) {

                        Text(notification.title)
                            .font(KinTypography.headline)
                            .foregroundStyle(KinColors.primaryText)
                            .multilineTextAlignment(.leading)

                        if let message = notification.displayMessage {
                            Text(message)
                                .font(KinTypography.callout)
                                .foregroundStyle(KinColors.secondaryText)
                                .multilineTextAlignment(.leading)
                                .lineLimit(isExpanded ? nil : 3)
                        }

                        Text(NotificationText.date(notification.createdAt))
                            .font(KinTypography.caption)
                            .foregroundStyle(KinColors.secondaryText)
                    }

                    Spacer(minLength: 0)

                    // Room for the bell and chevron drawn on top.
                    Color.clear
                        .frame(width: canExpand ? 72 : 36, height: 1)
                }
                .padding(KinSpacing.medium)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    notification.isRead ? Color.clear : color.opacity(0.08)
                )
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .overlay(alignment: .topTrailing) {
                HStack(spacing: KinSpacing.xSmall) {
                    readStateButton(notification)

                    if canExpand {
                        Button {
                            toggleExpanded(notification)
                        } label: {
                            Image(systemName: "chevron.down")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(KinColors.secondaryText)
                                .rotationEffect(.degrees(isExpanded ? 180 : 0))
                                .frame(width: 32, height: 32)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(isExpanded ? "Show less" : "Show more")
                    }
                }
                .padding(.top, KinSpacing.small)
                .padding(.trailing, KinSpacing.small)
            }

            if isExpanded {
                Divider()
                    .padding(.horizontal, KinSpacing.medium)

                expandedDetails(notification)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(
            KinColors.surface,
            in: RoundedRectangle(cornerRadius: KinRadius.large)
        )
        // Unread: a bar in the notification's color down the side.
        .overlay(alignment: .leading) {
            if !notification.isRead {
                Rectangle()
                    .fill(color)
                    .frame(width: 5)
                    .allowsHitTesting(false)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: KinRadius.large))
        .kinCardShadow()
        .accessibilityElement(children: .contain)
        .accessibilityValue(notification.isRead ? "Read" : "Unread")
    }

    /// The event's photo and a button to open what it's about.
    @ViewBuilder
    private func expandedDetails(
        _ notification: KinNotification
    ) -> some View {

        HStack(alignment: .top, spacing: KinSpacing.medium) {

            if let gatheringId = notification.gatheringId {
                NotificationEventPhoto(gatheringId: gatheringId)
                    .frame(width: 120, height: 120)
                    .clipShape(RoundedRectangle(cornerRadius: KinRadius.medium))
            }

            VStack(alignment: .leading, spacing: KinSpacing.medium) {

                Text(NotificationText.detail(for: notification))
                    .font(KinTypography.callout)
                    .foregroundStyle(KinColors.primaryText)
                    .fixedSize(horizontal: false, vertical: true)

                if let action = NotificationText.actionTitle(for: notification) {
                    Button {
                        open(notification)
                    } label: {
                        Text(action)
                            .font(KinTypography.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, KinSpacing.small + 2)
                            .background(
                                KinColors.primary,
                                in: RoundedRectangle(cornerRadius: KinRadius.medium)
                            )
                    }
                    .buttonStyle(.kinPressable)
                }
            }
        }
        .padding(KinSpacing.medium)
    }

    private func toggleExpanded(
        _ notification: KinNotification
    ) {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
            if expandedIds.contains(notification.id) {
                expandedIds.remove(notification.id)
            } else {
                expandedIds.insert(notification.id)
            }
        }
    }


    // MARK: - Read State Button

    private func readStateButton(
        _ notification: KinNotification
    ) -> some View {

        Button {
            Task {
                await toggleReadState(notification)
            }
        } label: {
            Image(systemName: notification.isRead ? "bell" : "bell.fill")
                .font(.system(size: 19))
                .foregroundStyle(
                    notification.isRead
                        ? KinColors.secondaryText
                        : KinColors.primary
                )
                .symbolEffect(.bounce, value: notification.isRead)
                .frame(width: 32, height: 32)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(
            notification.isRead ? "Mark as unread" : "Mark as read"
        )
    }

    // MARK: - Notification Icon

    /// Solid color while unread; soft and grey once read.
    private func notificationIcon(
        _ notification: KinNotification
    ) -> some View {

        let color = notification.type.color

        return Image(systemName: notification.type.iconName)
            .font(.system(size: 20, weight: .semibold))
            .foregroundStyle(notification.isRead ? color : .white)
            .frame(width: 52, height: 52)
            .background(
                notification.isRead ? color.opacity(0.14) : color,
                in: Circle()
            )
            .accessibilityHidden(true)
    }

    // MARK: - Loading State

    private var loadingState: some View {
        KinLoadingView(message: "Loading notifications...")
    }

    // MARK: - Empty State

    private var emptyState: some View {

        KinEmptyState(
            icon: "bell",
            title: "No Notifications",
            message:
                "Your event notifications and past alerts will appear here."
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

    /// Opens the event or recipe, marking the notification read.
    private func open(
        _ notification: KinNotification
    ) {

        if !notification.isRead {
            Task {
                await markAsRead(notification)
            }
        }

        if notification.gatheringId != nil {
            selectedNotification = notification
        } else if let recipeId = notification.recipeId {
            selectedRecipeId = recipeId
        }
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

        isLoading = notifications.isEmpty
        errorMessage = nil

        defer {
            isLoading = false
        }

        do {

            notifications =
                try await NotificationService
                    .fetchNotifications()

            // The newest unread notification starts open.
            if !hasAutoExpanded,
               let newest = notifications.first(where: { !$0.isRead && $0.hasDetails }) {
                expandedIds.insert(newest.id)
                hasAutoExpanded = true
            }

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
}


// MARK: - Curved Header

/// The header photo's bottom edge: a gentle wave, like the mockup.
private struct CurvedBottom: Shape {

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let dip: CGFloat = 28
        path.move(to: .zero)
        path.addLine(to: CGPoint(x: rect.maxX, y: 0))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addCurve(
            to: CGPoint(x: 0, y: rect.maxY - dip),
            control1: CGPoint(x: rect.maxX * 0.65, y: rect.maxY - dip * 2.2),
            control2: CGPoint(x: rect.maxX * 0.3, y: rect.maxY - dip * 0.2)
        )
        path.closeSubpath()
        return path
    }
}


// MARK: - Event Photo

/// The event's cover photo, loaded when a card is opened.
private struct NotificationEventPhoto: View {

    let gatheringId: UUID

    @State private var coverPath: String?
    @State private var didLoad = false

    var body: some View {
        Group {
            if didLoad {
                GatheringCardImage(path: coverPath, size: nil)
            } else {
                KinPhotoPlaceholder(icon: KinIcons.gatherings)
            }
        }
        .task {
            guard !didLoad else {
                return
            }
            coverPath =
                try? await GatheringService
                    .fetchGathering(id: gatheringId)
                    .coverImagePath
            didLoad = true
        }
        .accessibilityHidden(true)
    }
}


// MARK: - Preview

#Preview {

    NavigationStack {
        NotificationsView()
    }
}

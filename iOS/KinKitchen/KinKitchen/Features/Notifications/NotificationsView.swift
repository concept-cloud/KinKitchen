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

    /// What counted as "New" when the list loaded. A notification
    /// read while you're here stays put (shown as read) instead of
    /// jumping down to Earlier; it moves on the next visit or refresh.
    @State private var newSectionIds: Set<UUID> = []

    /// Read/unread changes waiting on Supabase, so a quick second tap
    /// can't flip one back mid-save.
    @State private var updatingIds: Set<UUID> = []

    /// Marked unread on purpose with the bell; opening these doesn't
    /// mark them read again.
    @State private var keptUnreadIds: Set<UUID> = []
    @State private var hasAutoExpanded = false

    // MARK: - Body

    var body: some View {

        GeometryReader { geometry in

            ScrollView {

                VStack(alignment: .leading, spacing: 0) {

                    header(topInset: geometry.safeAreaInsets.top)

                    // The title sits under the photo so the logo
                    // stays clear.
                    Text("Notifications")
                        .font(KinTypography.largeTitle)
                        .foregroundStyle(KinColors.primaryText)
                        .accessibilityAddTraits(.isHeader)
                        .padding(.horizontal, KinSpacing.large)
                        .padding(.top, -KinSpacing.small)
                        .padding(.bottom, KinSpacing.medium)

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
            await loadNotifications()
        }
        .sensoryFeedback(.selection, trigger: expandedIds)
    }

    // MARK: - Unread / Read

    private var newNotifications:
        [KinNotification] {

        notifications.filter {
            newSectionIds.contains($0.id)
        }
    }

    private var earlierNotifications:
        [KinNotification] {

        notifications.filter {
            !newSectionIds.contains($0.id)
        }
    }

    private var hasUnread: Bool {
        notifications.contains { !$0.isRead }
    }


    // MARK: - Header

    /// The Kin Kitchen photo and logo with a curved bottom edge, the
    /// back button and Mark All Read.
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

            Spacer(minLength: 0)

            if hasUnread {
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
        // Tall enough for the logo to show under the buttons.
        .frame(
            maxWidth: .infinity,
            minHeight: topInset + 230,
            alignment: .top
        )
        .background {
            Color.clear
                .overlay {
                    // The Kin Kitchen photo with the logo, as on Home.
                    Image("HomeHero")
                        .resizable()
                        .scaledToFill()
                }
                .clipShape(CurvedBottom())
                .accessibilityHidden(true)
        }
        .animation(.easeInOut(duration: 0.2), value: hasUnread)
    }


    // MARK: - Notification List

    private var notificationList: some View {

        LazyVStack(
            alignment: .leading,
            spacing: KinSpacing.medium
        ) {

            if !newNotifications.isEmpty {

                sectionTitle("New")

                ForEach(newNotifications) { notification in
                    notificationCard(notification)
                }
            }

            if !earlierNotifications.isEmpty {

                sectionTitle("Earlier")
                    .padding(
                        .top,
                        newNotifications.isEmpty ? 0 : KinSpacing.medium
                    )

                ForEach(earlierNotifications) { notification in
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
                        await setRead(notification, true)
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

    /// Opening a card counts as reading it.
    private func toggleExpanded(
        _ notification: KinNotification
    ) {
        let opening = !expandedIds.contains(notification.id)

        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
            if opening {
                expandedIds.insert(notification.id)
            } else {
                expandedIds.remove(notification.id)
            }
        }

        if opening,
           !notification.isRead,
           !keptUnreadIds.contains(notification.id) {
            Task {
                await setRead(notification, true)
            }
        }
    }


    // MARK: - Read State Button

    private func readStateButton(
        _ notification: KinNotification
    ) -> some View {

        Button {
            let markingUnread = notification.isRead

            if markingUnread {
                keptUnreadIds.insert(notification.id)
            } else {
                keptUnreadIds.remove(notification.id)
            }

            Task {
                await setRead(notification, !notification.isRead)
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
                await setRead(notification, true)
            }
        }

        if notification.gatheringId != nil {
            selectedNotification = notification
        } else if let recipeId = notification.recipeId {
            selectedRecipeId = recipeId
        }
    }

    // MARK: - Read State

    /// Shows the change right away, then saves it. If saving fails,
    /// the card goes back to how it was.
    @MainActor
    private func setRead(
        _ notification: KinNotification,
        _ isRead: Bool
    ) async {

        guard
            !updatingIds.contains(notification.id),
            let index =
                notifications.firstIndex(where: { $0.id == notification.id }),
            notifications[index].isRead != isRead
        else {
            return
        }

        updatingIds.insert(notification.id)

        defer {
            updatingIds.remove(notification.id)
        }

        withAnimation(.easeInOut(duration: 0.2)) {
            notifications[index] = notifications[index].withRead(isRead)
        }

        do {
            if isRead {
                try await NotificationService.markAsRead(
                    notificationId: notification.id
                )
            } else {
                try await NotificationService.markAsUnread(
                    notificationId: notification.id
                )
            }
        } catch is CancellationError {
            return
        } catch {
            if let index = notifications.firstIndex(where: { $0.id == notification.id }) {
                withAnimation {
                    notifications[index] = notifications[index].withRead(!isRead)
                }
            }
            print(
                "NOTIFICATION READ STATE ERROR:",
                error.localizedDescription
            )
        }
    }

    // MARK: - Mark All Read

    @MainActor
    private func markAllAsRead() async {

        let before = notifications

        withAnimation(.easeInOut(duration: 0.2)) {
            notifications = notifications.map { $0.withRead(true) }
        }

        do {
            try await NotificationService.markAllAsRead()
        } catch is CancellationError {
            return
        } catch {
            notifications = before
            print(
                "NOTIFICATION MARK ALL READ ERROR:",
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

            newSectionIds =
                Set(notifications.filter { !$0.isRead }.map(\.id))

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

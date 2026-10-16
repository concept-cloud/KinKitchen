//
//  NotificationDisplay.swift
//  KinKitchen
//
//  Created by Greg Hudler on 10/4/26.
//

import SwiftUI

// MARK: - Notification Type Display

extension KinNotificationType {

    var iconName: String {

        switch self {

        case .gatheringInvitation:
            return "envelope.fill"

        case .invitationAccepted:
            return KinIcons.gatherings

        case .invitationDeclined:
            return "xmark"

        case .gatheringUpdated:
            return "calendar.badge.clock"

        case .dishUpdated:
            return "fork.knife"

        case .recipeShared:
            return "book.closed.fill"
        }
    }

    var color: Color {

        switch self {

        case .invitationAccepted:
            return KinColors.success

        case .invitationDeclined:
            return KinColors.error

        case .gatheringUpdated:
            return KinColors.warning

        case .dishUpdated:
            return Color(red: 0.85, green: 0.55, blue: 0.15)

        case .gatheringInvitation, .recipeShared:
            return KinColors.primary
        }
    }
}

// MARK: - Notification Display

extension KinNotification {

    /// The gathering this notification points to, if any.
    var gatheringId: UUID? {

        guard relatedType == "gathering" else {
            return nil
        }

        return relatedId
    }

    /// A copy with a different read state, for updating the list
    /// before Supabase confirms.
    func withRead(
        _ isRead: Bool
    ) -> KinNotification {
        KinNotification(
            id: id,
            userId: userId,
            type: type,
            title: title,
            message: message,
            relatedType: relatedType,
            relatedId: relatedId,
            isRead: isRead,
            createdAt: createdAt
        )
    }

    /// The recipe this notification points to, if any.
    var recipeId: UUID? {
        relatedType == "recipe" ? relatedId : nil
    }

    /// Opens to show a photo, the full message and a button when it
    /// points at an event or recipe.
    var hasDetails: Bool {
        gatheringId != nil || recipeId != nil
    }

    /// Message shown under the title. Gathering updates
    /// created before change descriptions existed fall back
    /// to a generic description instead of showing nothing.
    var displayMessage: String? {

        let cleanMessage =
            message?.trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        if let cleanMessage, !cleanMessage.isEmpty {
            return cleanMessage
        }

        if type == .gatheringUpdated {
            return "The host updated the event details."
        }

        return nil
    }
}

// MARK: - Gathering Change Fields

enum GatheringChangeField:
    CaseIterable,
    Hashable {

    case name
    case startsAt
    case location
    case theme
    case eventType
    case dietaryNeeds
    case guestLimit
    case familySize
    case description
    case coverPhoto
}

extension KinNotification {

    /// Fields a gathering-update notification says changed.
    ///
    /// Parsed from the message text written by the Supabase
    /// function `update_gathering_with_notifications`
    /// (supabase/KINKIT-170). Keep these phrases in sync
    /// with that function if its wording changes.
    var changedGatheringFields: Set<GatheringChangeField> {

        guard
            type == .gatheringUpdated,
            let message =
                message?.lowercased()
        else {
            return []
        }

        let phrases: [(String, GatheringChangeField)] = [
            ("renamed to", .name),
            ("date and time changed", .startsAt),
            ("location changed", .location),
            ("location removed", .location),
            ("theme changed", .theme),
            ("theme removed", .theme),
            ("event type changed", .eventType),
            ("dietary needs updated", .dietaryNeeds),
            ("guest limit", .guestLimit),
            ("family size", .familySize),
            ("description updated", .description),
            ("cover photo updated", .coverPhoto)
        ]

        return Set(
            phrases
                .filter { message.contains($0.0) }
                .map(\.1)
        )
    }
}

// MARK: - Unread Lookup

extension Array where Element == KinNotification {

    /// Unread notifications for a gathering, newest first
    /// (fetchNotifications returns them in that order).
    func unread(
        forGathering gatheringId: UUID
    ) -> [KinNotification] {

        filter {
            !$0.isRead
                && $0.gatheringId == gatheringId
        }
    }

    func unreadCount(
        forGathering gatheringId: UUID
    ) -> Int {

        unread(
            forGathering: gatheringId
        )
        .count
    }
}

// MARK: - Change Highlight

extension View {

    /// Highlights a piece of gathering information with a
    /// tinted background and bell when it has just changed.
    @ViewBuilder
    func kinChangeHighlight(
        _ isChanged: Bool
    ) -> some View {

        if isChanged {

            HStack(
                alignment: .firstTextBaseline,
                spacing: KinSpacing.small
            ) {

                self

                Image(
                    systemName: "bell.fill"
                )
                .font(
                    .system(
                        size: 13,
                        weight: .semibold
                    )
                )
                .foregroundStyle(
                    KinColors.primary
                )
                .accessibilityLabel(
                    "Updated"
                )
            }
            .padding(
                .horizontal,
                KinSpacing.small
            )
            .padding(
                .vertical,
                KinSpacing.xSmall
            )
            .background(
                KinColors.primary
                    .opacity(0.12)
            )
            .clipShape(
                RoundedRectangle(
                    cornerRadius:
                        KinRadius.medium
                )
            )

        } else {

            self
        }
    }
}

// MARK: - Card Notification Line

/// Newest unread notification message, shown on gathering cards.
struct KinCardNotificationLine: View {

    let notification: KinNotification

    var body: some View {

        Label {

            Text(
                notification.displayMessage
                    ?? notification.title
            )
            .lineLimit(2)
            .multilineTextAlignment(
                .leading
            )

        } icon: {

            Image(
                systemName: "bell.fill"
            )
        }
        .font(
            KinTypography.caption
        )
        .foregroundStyle(
            KinColors.primary
        )
    }
}

// MARK: - Unread Indicator

/// Small badge shown on cards whose content has
/// unread notifications.
struct KinUnreadIndicator: View {

    let count: Int

    var body: some View {

        HStack(
            spacing: KinSpacing.xxSmall
        ) {

            Image(
                systemName: "bell.fill"
            )
            .font(
                .system(
                    size: 11,
                    weight: .bold
                )
            )

            Text(
                "\(count)"
            )
            .font(
                .system(
                    size: 12,
                    weight: .bold
                )
            )
        }
        .foregroundStyle(
            .white
        )
        .padding(
            .horizontal,
            KinSpacing.small
        )
        .padding(
            .vertical,
            KinSpacing.xxSmall
        )
        .background(
            KinColors.primary
        )
        .clipShape(
            Capsule()
        )
        .accessibilityElement(
            children: .ignore
        )
        .accessibilityLabel(
            count == 1
                ? "1 unread notification"
                : "\(count) unread notifications"
        )
    }
}


// MARK: - Notification Text

nonisolated enum NotificationText {

    /// "Today at 6:31 PM", "Yesterday at 9:02 AM", "Oct 4, 2026 at 6:31 PM"
    static func date(
        _ date: Date,
        now: Date = .now,
        calendar: Calendar = .current
    ) -> String {
        let time = date.formatted(date: .omitted, time: .shortened)
        if calendar.isDate(date, inSameDayAs: now) {
            return "Today at \(time)"
        }
        if let yesterday = calendar.date(byAdding: .day, value: -1, to: now),
           calendar.isDate(date, inSameDayAs: yesterday) {
            return "Yesterday at \(time)"
        }
        return "\(date.formatted(date: .abbreviated, time: .omitted)) at \(time)"
    }

    /// The opened card's line about what you can do next.
    static func detail(
        for notification: KinNotification
    ) -> String {
        switch notification.type {
        case .gatheringInvitation:
            return "You're invited. Open the event to see the details and respond."
        case .invitationAccepted:
            return "They're on the guest list. Open the event to see who's coming and what's being brought."
        case .invitationDeclined:
            return "They won't make it this time. Open the event to see your guest list."
        case .gatheringUpdated:
            return "Something changed. Open the event to see the latest details."
        case .dishUpdated:
            return "The menu changed. Open the event to see what everyone's bringing."
        case .recipeShared:
            return "A recipe is waiting for you. Open it to cook, save or add it to a cookbook."
        }
    }

    /// The opened card's button, if there's somewhere to go.
    static func actionTitle(
        for notification: KinNotification
    ) -> String? {
        if notification.gatheringId != nil {
            return "View Event"
        }
        if notification.recipeId != nil {
            return "View Recipe"
        }
        return nil
    }
}

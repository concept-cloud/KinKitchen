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

    var color: Color {

        switch self {

        case .invitationAccepted:
            return .green

        case .invitationDeclined:
            return KinColors.error

        default:
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
            return "The host updated the gathering details."
        }

        return nil
    }
}

// MARK: - Unread Lookup

extension Array where Element == KinNotification {

    func unreadCount(
        forGathering gatheringId: UUID
    ) -> Int {

        filter {
            !$0.isRead
                && $0.gatheringId == gatheringId
        }
        .count
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

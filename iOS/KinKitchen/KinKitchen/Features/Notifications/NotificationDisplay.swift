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

// MARK: - Gathering Change Fields

enum GatheringChangeField:
    CaseIterable,
    Hashable {

    case name
    case startsAt
    case location
    case theme
    case guestLimit
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
            ("guest limit", .guestLimit),
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

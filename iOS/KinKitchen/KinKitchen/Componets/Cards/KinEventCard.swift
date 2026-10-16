//
//  KinEventCard.swift
//  KinKitchen
//
//  Created by Greg Hudler on 10/14/26.
//

import SwiftUI

/// An event (gathering) as a card, the same on Home and the Events
/// tab: the cover photo fills the card and fades under the details on
/// the left. Shows the event type, the user's role, date, place and the newest unread
/// update. Past events show past-tense roles and Completed/Cancelled.
///
/// Only the look; wrap it in a Button or NavigationLink to open it.
struct KinEventCard: View {

    let item: GatheringListItem
    /// Unread updates for this event, newest first.
    var unread: [KinNotification] = []

    private var event: Gathering {
        item.gathering
    }

    private var isPast: Bool {
        event.isHistorical()
    }

    var body: some View {

        VStack(
            alignment: .leading,
            spacing: KinSpacing.xSmall
        ) {

            if let eventType = event.eventType {
                KinEventTypeLabel(type: eventType)
            }

            HStack(
                alignment: .top,
                spacing: KinSpacing.small
            ) {

                Text(event.name)
                    .font(KinTypography.headline)
                    .foregroundStyle(KinColors.primaryText)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
                    .frame(
                        maxWidth: .infinity,
                        alignment: .leading
                    )

                roleCapsule
            }

            Label(
                dateText,
                systemImage: KinIcons.calendar
            )
            .font(KinTypography.footnote)
            .foregroundStyle(KinColors.secondaryText)

            if let location {

                Label(
                    location,
                    systemImage: "mappin"
                )
                .font(KinTypography.footnote)
                .foregroundStyle(KinColors.secondaryText)
                .lineLimit(1)
            }

            if let status = KinEventCard.statusText(for: event) {

                Label(
                    status,
                    systemImage:
                        event.status == .cancelled
                            ? "xmark.circle"
                            : "checkmark.circle"
                )
                .font(KinTypography.caption)
                .foregroundStyle(
                    event.status == .cancelled
                        ? KinColors.error
                        : KinColors.success
                )
            }

            if let latest = unread.first {

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
                .padding(.top, KinSpacing.xxSmall)
            }
        }
        .padding(KinSpacing.medium)
        // A soft halo in the card color keeps text crisp where it
        // runs over the photo.
        .shadow(
            color: KinColors.surface,
            radius: 3
        )
        .frame(
            maxWidth: .infinity,
            minHeight: 132,
            alignment: .leading
        )
        .background {

            // Photo fills the card. The card color sits behind the
            // text on the left and fades out to the right.
            ZStack {

                GatheringCardImage(
                    path: event.coverImagePath,
                    size: nil
                )

                LinearGradient(
                    stops: [
                        .init(color: KinColors.surface.opacity(0.92), location: 0),
                        .init(color: KinColors.surface.opacity(0.82), location: 0.45),
                        .init(color: KinColors.surface.opacity(0.35), location: 0.75),
                        .init(color: KinColors.surface.opacity(0.1), location: 1)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            }
            // Past events step back a little.
            .saturation(isPast ? 0.4 : 1)
        }
        .clipShape(
            RoundedRectangle(
                cornerRadius: KinRadius.large
            )
        )
        .kinCardShadow()
        .contentShape(
            RoundedRectangle(
                cornerRadius: KinRadius.large
            )
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityText)
        .accessibilityHint("Opens the event")
        .accessibilityAddTraits(.isButton)
    }


    // MARK: - Pieces

    private var roleCapsule: some View {

        Text(KinEventCard.roleText(for: item))
            .font(.system(size: 12, weight: .bold))
            .foregroundStyle(.white)
            .padding(.horizontal, KinSpacing.small)
            .padding(.vertical, KinSpacing.xSmall)
            .background(
                KinEventCard.roleColor(for: item.relationship)
            )
            .clipShape(Capsule())
            .fixedSize()
    }

    private var dateText: String {
        if let end = event.endsAt {
            return EventDateRange.summary(from: event.startsAt, to: end)
        }
        return isPast
            ? event.startsAt.formatted(date: .abbreviated, time: .shortened)
            : HomeView.eventDateText(event.startsAt)
    }

    private var location: String? {
        let value =
            event.location?
                .trimmingCharacters(in: .whitespacesAndNewlines)
        return value?.isEmpty == false ? value : nil
    }

    private var accessibilityText: String {
        [
            event.name,
            event.eventType?.title,
            KinEventCard.roleText(for: item),
            dateText,
            location,
            KinEventCard.statusText(for: event),
            unread.isEmpty
                ? nil
                : "\(unread.count) new update\(unread.count == 1 ? "" : "s")"
        ]
        .compactMap { $0 }
        .joined(separator: ", ")
    }


    // MARK: - Shared Rules

    /// Past tense once the event is over.
    static func roleText(
        for item: GatheringListItem
    ) -> String {

        guard item.gathering.isHistorical() else {
            return item.relationship.displayName
        }

        switch item.relationship {
        case .hosting: return "Hosted"
        case .going: return "Attended"
        case .invited: return "Invited"
        }
    }

    static func roleColor(
        for relationship: GatheringRelationship
    ) -> Color {

        switch relationship {
        case .hosting: return KinColors.primary
        case .going: return KinColors.success
        case .invited: return KinColors.warning
        }
    }

    /// "Cancelled", "Completed" for past events; nil otherwise.
    static func statusText(
        for event: Gathering
    ) -> String? {

        if event.status == .cancelled {
            return "Cancelled"
        }
        return event.isHistorical() ? "Completed" : nil
    }
}

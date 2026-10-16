//
//  EventFormComponents.swift
//  KinKitchen
//
//  Created by Greg Hudler on 10/15/26.
//

import SwiftUI

// MARK: - Quick Dates and Times

/// The one-tap date and time choices on Add Event.
nonisolated enum EventDateChoices {

    struct Choice: Hashable {
        let title: String
        let date: Date
    }

    /// Today, Tomorrow, then the coming Saturday and Sunday when
    /// they aren't already one of those.
    static func quickDates(
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> [Choice] {

        let today = calendar.startOfDay(for: now)

        guard let tomorrow = calendar.date(byAdding: .day, value: 1, to: today) else {
            return [Choice(title: "Today", date: today)]
        }

        var choices = [
            Choice(title: "Today", date: today),
            Choice(title: "Tomorrow", date: tomorrow)
        ]

        let week = (0..<7).compactMap {
            calendar.date(byAdding: .day, value: $0, to: today)
        }

        // This week's Saturday (7) and Sunday (1).
        for weekday in [7, 1] {
            guard
                let day = week.first(where: {
                    calendar.component(.weekday, from: $0) == weekday
                }),
                !choices.contains(where: { calendar.isDate($0.date, inSameDayAs: day) })
            else {
                continue
            }

            choices.append(
                Choice(
                    title: day.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day()),
                    date: day
                )
            )
        }

        return choices
    }

    /// Hours offered as chips: noon, 5, 6 and 7 PM.
    static let quickHours = [12, 17, 18, 19]

    static func time(
        hour: Int,
        on day: Date,
        calendar: Calendar = .current
    ) -> Date {
        calendar.date(bySettingHour: hour, minute: 0, second: 0, of: day) ?? day
    }

    /// 6 PM today, or tomorrow once it's too late for tonight.
    static func defaultStart(
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> Date {
        let tonight = time(hour: 18, on: now, calendar: calendar)
        if tonight.timeIntervalSince(now) >= 2 * 60 * 60 {
            return tonight
        }
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: now) ?? now
        return time(hour: 18, on: tomorrow, calendar: calendar)
    }
}


// MARK: - Card

/// A white card with a tinted icon and heading, matching Edit Profile.
struct EventFormCard<Content: View>: View {

    let title: String
    let systemImage: String
    var tint: Color = KinColors.primary
    var subtitle: String? = nil
    @ViewBuilder var content: Content

    var body: some View {

        VStack(alignment: .leading, spacing: KinSpacing.medium) {

            HStack(alignment: .top, spacing: KinSpacing.small) {

                Image(systemName: systemImage)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(tint)
                    .frame(width: 30, height: 30)
                    .background(
                        tint.opacity(0.14),
                        in: RoundedRectangle(cornerRadius: KinRadius.small)
                    )
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: KinSpacing.xxSmall) {
                    Text(title)
                        .font(KinTypography.headline)
                        .foregroundStyle(KinColors.primaryText)
                        .accessibilityAddTraits(.isHeader)

                    if let subtitle {
                        Text(subtitle)
                            .font(KinTypography.caption)
                            .foregroundStyle(KinColors.secondaryText)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(.top, 5)
            }

            content
        }
        .padding(KinSpacing.large)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            KinColors.surface,
            in: RoundedRectangle(cornerRadius: KinRadius.large)
        )
        .kinCardShadow()
    }
}


// MARK: - Chip

/// A small pill choice: quick dates, times and theme ideas.
struct EventChoiceChip: View {

    let title: String
    var systemImage: String? = nil
    let isSelected: Bool
    let action: () -> Void

    var body: some View {

        Button(action: action) {

            HStack(spacing: KinSpacing.xSmall) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(.system(size: 12, weight: .semibold))
                }
                Text(title)
                    .font(KinTypography.callout)
                    .lineLimit(1)
            }
            .foregroundStyle(isSelected ? .white : KinColors.primaryText)
            .padding(.horizontal, KinSpacing.medium)
            .padding(.vertical, KinSpacing.small)
            .background(
                isSelected ? KinColors.primary : KinColors.background,
                in: Capsule()
            )
            .overlay {
                Capsule()
                    .strokeBorder(
                        KinColors.secondaryText.opacity(isSelected ? 0 : 0.25)
                    )
            }
            .contentShape(Capsule())
        }
        .buttonStyle(.kinPressable)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

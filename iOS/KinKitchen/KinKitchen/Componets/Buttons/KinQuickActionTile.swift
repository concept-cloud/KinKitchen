//
//  KinQuickActionTile.swift
//  KinKitchen
//
//  Created by Greg Hudler on 10/13/26.
//

import SwiftUI

/// A rounded shortcut tile: a tinted icon above a short label.
struct KinQuickActionTile: View {

    let title: String
    let icon: String
    let tint: Color
    var hint: String? = nil
    /// Small label in the corner, e.g. "Soon".
    var badge: String? = nil
    let action: () -> Void

    @ScaledMetric(relativeTo: .title2)
    private var iconBoxSize: CGFloat = 48

    var body: some View {

        Button(action: action) {

            VStack(
                spacing: KinSpacing.small
            ) {

                Image(systemName: icon)
                    .font(
                        .system(
                            size: iconBoxSize * 0.46,
                            weight: .semibold
                        )
                    )
                    .foregroundStyle(tint)
                    .frame(
                        width: iconBoxSize,
                        height: iconBoxSize
                    )
                    .background(
                        tint.opacity(0.14)
                    )
                    .clipShape(
                        RoundedRectangle(
                            cornerRadius: KinRadius.medium
                        )
                    )

                Text(title)
                    .font(KinTypography.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(KinColors.primaryText)
                    .multilineTextAlignment(.center)
                    // Always two lines tall, so one- and two-line
                    // labels make tiles the same size.
                    .lineLimit(
                        2,
                        reservesSpace: true
                    )
                    .minimumScaleFactor(0.85)
            }
            .padding(
                .vertical,
                KinSpacing.medium
            )
            .padding(
                .horizontal,
                KinSpacing.xSmall
            )
            .frame(
                maxWidth: .infinity,
                minHeight: 96,
                alignment: .top
            )
            .background(KinColors.surface)
            .clipShape(
                RoundedRectangle(
                    cornerRadius: KinRadius.large
                )
            )
            .overlay(
                alignment: .topTrailing
            ) {

                if let badge {

                    Text(badge)
                        .font(
                            .system(
                                size: 9,
                                weight: .bold
                            )
                        )
                        .foregroundStyle(tint)
                        .padding(
                            .horizontal,
                            KinSpacing.xSmall
                        )
                        .padding(
                            .vertical,
                            KinSpacing.xxSmall
                        )
                        .background(
                            tint.opacity(0.14)
                        )
                        .clipShape(Capsule())
                        .padding(KinSpacing.xSmall)
                }
            }
            .kinCardShadow()
            .contentShape(
                RoundedRectangle(
                    cornerRadius: KinRadius.large
                )
            )
        }
        .buttonStyle(.kinPressable)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            badge.map { "\(title), \($0)" } ?? title
        )
        .accessibilityHint(hint ?? "")
        .accessibilityAddTraits(.isButton)
    }
}


#Preview {

    HStack(
        spacing: KinSpacing.medium
    ) {

        KinQuickActionTile(
            title: "New Recipe",
            icon: "frying.pan.fill",
            tint: KinColors.primary
        ) {}

        KinQuickActionTile(
            title: "New Event",
            icon: "person.3.fill",
            tint: KinColors.success
        ) {}

        KinQuickActionTile(
            title: "My Cookbooks",
            icon: "book.fill",
            tint: KinColors.accent
        ) {}

        KinQuickActionTile(
            title: "Recipes",
            icon: "fork.knife",
            tint: .blue
        ) {}
    }
    .padding()
    .background(KinColors.background)
}

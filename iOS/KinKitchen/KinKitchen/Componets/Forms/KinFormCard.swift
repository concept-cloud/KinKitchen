//
//  KinFormCard.swift
//  KinKitchen
//
//  Created by Greg Hudler on 10/15/26.
//

import SwiftUI

// MARK: - Card

/// A white card with a tinted icon and heading, matching Edit Profile.
/// Used on Add Event and Add Recipe.
struct KinFormCard<Content: View>: View {

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

/// A small pill choice: quick dates, times, theme ideas and so on.
struct KinChoiceChip: View {

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

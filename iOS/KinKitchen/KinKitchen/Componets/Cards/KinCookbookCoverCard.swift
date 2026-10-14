//
//  KinCookbookCoverCard.swift
//  KinKitchen
//
//  Created by Greg Hudler on 10/14/26.
//

import SwiftUI

/// A cookbook shown like a book cover: the cover photo fills the card,
/// with the title and recipe count written over a dark fade.
struct KinCookbookCoverCard: View {

    let cookbook: Cookbook
    var recipeCount: Int? = nil
    /// Small label in the top corner, e.g. "Private" or "Shared by Sam".
    var badge: CookbookBadge? = nil
    var height: CGFloat = 180
    var titleFont: Font = KinTypography.title2

    var body: some View {

        KinStorageImage(
            bucket: "cookbook-covers",
            path: cookbook.coverPath,
            placeholderIcon: KinIcons.cookbooks
        )
        .frame(height: height)
        .frame(maxWidth: .infinity)
        .overlay {

            LinearGradient(
                stops: [
                    .init(color: .black.opacity(0), location: 0.35),
                    .init(color: .black.opacity(0.75), location: 1)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
        .overlay(
            alignment: .bottomLeading
        ) {

            VStack(
                alignment: .leading,
                spacing: KinSpacing.xxSmall
            ) {

                Text(cookbook.name)
                    .font(titleFont)
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                if let countText =
                    KinCookbookCoverCard.recipeCountText(recipeCount) {

                    Text(countText)
                        .font(KinTypography.subheadline)
                        .foregroundStyle(.white.opacity(0.9))
                }
            }
            .kinTextOnPhoto()
            .padding(KinSpacing.large)
        }
        .overlay(
            alignment: .topTrailing
        ) {

            if let badge {

                Label(
                    badge.title,
                    systemImage: badge.icon
                )
                .font(
                    .system(
                        size: 12,
                        weight: .semibold
                    )
                )
                .foregroundStyle(.white)
                .padding(
                    .horizontal,
                    KinSpacing.small
                )
                .padding(
                    .vertical,
                    KinSpacing.xSmall
                )
                .background(.black.opacity(0.45))
                .clipShape(Capsule())
                .padding(KinSpacing.medium)
            }
        }
        .clipShape(
            RoundedRectangle(
                cornerRadius: KinRadius.large
            )
        )
        .kinCardShadow()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            [
                cookbook.name,
                "cookbook",
                KinCookbookCoverCard.recipeCountText(recipeCount),
                badge?.title
            ]
            .compactMap { $0 }
            .joined(separator: ", ")
        )
    }


    /// "1 Recipe", "24 Recipes"; nil when the count isn't known.
    nonisolated static func recipeCountText(
        _ count: Int?
    ) -> String? {

        guard let count else {
            return nil
        }

        return count == 1
            ? "1 Recipe"
            : "\(count) Recipes"
    }
}


/// Who a cookbook belongs to, shown on its cover.
nonisolated enum CookbookBadge: Equatable {

    case mine
    case shared(by: String?)

    var title: String {

        switch self {

        case .mine:
            return "Private"

        case .shared(let owner):
            if let owner, !owner.isEmpty {
                return "Shared by \(owner)"
            }
            return "Shared"
        }
    }

    var icon: String {

        switch self {

        case .mine:
            return KinIcons.lock

        case .shared:
            return KinIcons.participants
        }
    }
}

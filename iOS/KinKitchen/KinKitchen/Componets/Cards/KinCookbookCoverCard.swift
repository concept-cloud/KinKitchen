//
//  KinCookbookCoverCard.swift
//  KinKitchen
//
//  Created by Greg Hudler on 10/14/26.
//

import SwiftUI

/// A cookbook drawn like a real book: a spine down the left, page
/// edges peeking out on the right, and either the cover photo or, with
/// no photo, a cloth-bound cover with a cream title label like an old
/// family cookbook.
struct KinCookbookCoverCard: View {

    let cookbook: Cookbook
    var recipeCount: Int? = nil
    /// Small label in the top corner, e.g. "Private" or "Shared by Sam".
    var badge: CookbookBadge? = nil
    var height: CGFloat = 180
    var titleFont: Font = KinTypography.title2
    /// On the bookshelf: title and count at the top of the cover,
    /// like a printed cookbook.
    var isShelfBook = false

    /// Foil for the spine bands and label border.
    nonisolated static let gold = Color(red: 0.80, green: 0.64, blue: 0.33)

    private static let spineWidth: CGFloat = 14
    private static let pageInset: CGFloat = 5

    /// Square-ish on the spine side, rounded on the opening side.
    private var coverShape: UnevenRoundedRectangle {
        UnevenRoundedRectangle(
            topLeadingRadius: 4,
            bottomLeadingRadius: 4,
            bottomTrailingRadius: KinRadius.large,
            topTrailingRadius: KinRadius.large
        )
    }

    private var hasPhoto: Bool {
        cookbook.coverPath?.isEmpty == false
    }

    var body: some View {

        ZStack {
            pages
            cover
        }
        .padding(.trailing, Self.pageInset)
        .frame(height: height)
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


    // MARK: - Pages

    /// Two sheets of paper showing past the cover's edge.
    private var pages: some View {

        ZStack {
            ForEach([2, 1], id: \.self) { layer in
                coverShape
                    .fill(KinColors.paper)
                    .overlay {
                        coverShape
                            .strokeBorder(KinColors.secondaryText.opacity(0.18), lineWidth: 0.5)
                    }
                    .padding(.vertical, CGFloat(layer) * 3)
                    .offset(x: CGFloat(layer) * (Self.pageInset / 2))
            }
        }
        .kinCardShadow()
    }


    // MARK: - Cover

    private var cover: some View {

        ZStack {
            switch (hasPhoto, isShelfBook) {
            case (true, false): photoCover
            case (false, false): clothCover
            case (true, true): shelfPhotoCover
            case (false, true): shelfClothCover
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay(alignment: .leading) {
            spine
        }
        .overlay(alignment: .topTrailing) {
            badgeLabel
        }
        .clipShape(coverShape)
        .shadow(color: .black.opacity(0.18), radius: 3, x: 1, y: 2)
    }

    /// Darker strip with a crease, so it reads as a bound book.
    private var spine: some View {

        HStack(spacing: 0) {
            LinearGradient(
                colors: [.black.opacity(0.35), .black.opacity(0.12)],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(width: Self.spineWidth)
            // Gold bands near the top and bottom, like a hardcover.
            .overlay {
                VStack {
                    spineBands
                    Spacer()
                    spineBands
                }
                .padding(.vertical, height * 0.08)
            }

            // The crease where the cover bends.
            LinearGradient(
                colors: [.white.opacity(0.28), .white.opacity(0)],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(width: 4)
        }
        .allowsHitTesting(false)
    }

    private var spineBands: some View {
        VStack(spacing: 2) {
            Rectangle().frame(height: 1.5)
            Rectangle().frame(height: 1.5)
        }
        .foregroundStyle(Self.gold.opacity(0.85))
    }

    private var photoCover: some View {

        KinStorageImage(
            bucket: "cookbook-covers",
            path: cookbook.coverPath,
            placeholderIcon: KinIcons.cookbooks
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
        .overlay(alignment: .bottomLeading) {

            VStack(alignment: .leading, spacing: KinSpacing.xSmall) {

                Text(cookbook.name)
                    .font(titleFont)
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                if let countText = KinCookbookCoverCard.recipeCountText(recipeCount) {
                    Label(countText, systemImage: KinIcons.recipes)
                        .font(KinTypography.footnote.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, KinSpacing.small)
                        .padding(.vertical, KinSpacing.xxSmall + 1)
                        .background(.white.opacity(0.22), in: Capsule())
                }
            }
            .kinTextOnPhoto()
            .padding(KinSpacing.large)
            .padding(.leading, Self.spineWidth)
        }
    }

    /// No photo: cloth in one of a few warm colors, picked from the
    /// cookbook so each keeps its own, with a cream label.
    private var clothCover: some View {

        let cloth = KinCookbookCoverCard.clothColor(for: cookbook.id)

        return ZStack {

            cloth

            // Soft light across the cloth.
            LinearGradient(
                colors: [.white.opacity(0.16), .clear, .black.opacity(0.18)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Fine linen weave.
            Canvas { context, size in
                var path = Path()
                var x: CGFloat = 0
                while x < size.width {
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x, y: size.height))
                    x += 3
                }
                context.stroke(path, with: .color(.white.opacity(0.04)), lineWidth: 1)
            }

            titleLabel
                .padding(.leading, Self.spineWidth)
                .padding(.horizontal, KinSpacing.medium)
        }
    }

    // MARK: - Shelf Covers

    /// Dark ink for titles printed on a light cover.
    private static let ink = Color(red: 0.20, green: 0.15, blue: 0.12)

    /// Title and count printed at the top, like the books on a shelf.
    private func printedTitle(color: Color, countColor: Color) -> some View {

        VStack(alignment: .leading, spacing: KinSpacing.xSmall) {

            Text(cookbook.name)
                .font(titleFont)
                .foregroundStyle(color)
                .lineLimit(3)
                .minimumScaleFactor(0.8)
                .multilineTextAlignment(.leading)

            if let countText = KinCookbookCoverCard.recipeCountText(recipeCount) {
                Text(countText.uppercased())
                    .font(.system(size: 10, weight: .semibold))
                    .tracking(1.4)
                    .foregroundStyle(countColor)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.leading, Self.spineWidth + KinSpacing.small)
        .padding(.trailing, KinSpacing.medium)
        // Clears the badge in the corner.
        .padding(.top, badge == nil ? KinSpacing.medium : 36)
    }

    /// Photo with a cream wash at the top so the dark title reads.
    private var shelfPhotoCover: some View {

        KinStorageImage(
            bucket: "cookbook-covers",
            path: cookbook.coverPath,
            placeholderIcon: KinIcons.cookbooks
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay {
            LinearGradient(
                stops: [
                    .init(color: Color(red: 0.99, green: 0.96, blue: 0.9).opacity(0.94), location: 0),
                    .init(color: Color(red: 0.99, green: 0.96, blue: 0.9).opacity(0.7), location: 0.35),
                    .init(color: Color(red: 0.99, green: 0.96, blue: 0.9).opacity(0), location: 0.62)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
        .overlay(alignment: .top) {
            printedTitle(
                color: Self.ink,
                countColor: Self.ink.opacity(0.75)
            )
        }
    }

    /// Cloth with a cream title, a gold rule and a faint emblem.
    private var shelfClothCover: some View {

        let cloth = KinCookbookCoverCard.clothColor(for: cookbook.id)

        return ZStack {

            cloth

            LinearGradient(
                colors: [.white.opacity(0.16), .clear, .black.opacity(0.2)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Canvas { context, size in
                var path = Path()
                var x: CGFloat = 0
                while x < size.width {
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x, y: size.height))
                    x += 3
                }
                context.stroke(path, with: .color(.white.opacity(0.04)), lineWidth: 1)
            }

            Image(systemName: "fork.knife")
                .font(.system(size: height * 0.32, weight: .semibold))
                .foregroundStyle(Self.gold.opacity(0.3))
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                .padding(KinSpacing.medium)
        }
        .overlay(alignment: .top) {
            VStack(alignment: .leading, spacing: KinSpacing.small) {
                printedTitle(
                    color: Color(red: 0.99, green: 0.96, blue: 0.89),
                    countColor: Self.gold
                )
                Rectangle()
                    .fill(Self.gold.opacity(0.8))
                    .frame(width: 36, height: 1.5)
                    .padding(.leading, Self.spineWidth + KinSpacing.small)
            }
        }
    }

    /// The cream label on a cloth cover, with a double border.
    private var titleLabel: some View {

        VStack(spacing: KinSpacing.xSmall) {

            Image(systemName: "fork.knife")
                .font(.system(size: height > 150 ? 14 : 11, weight: .semibold))
                .foregroundStyle(KinColors.primary)

            Text(cookbook.name)
                .font(titleFont)
                .foregroundStyle(Color(red: 0.2, green: 0.15, blue: 0.12))
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.75)

            if let countText = KinCookbookCoverCard.recipeCountText(recipeCount) {
                Text(countText.uppercased())
                    .font(.system(size: 10, weight: .bold))
                    .tracking(1.2)
                    .foregroundStyle(Color(red: 0.45, green: 0.38, blue: 0.32))
            }
        }
        .padding(.horizontal, KinSpacing.medium)
        .padding(.vertical, KinSpacing.small)
        .frame(maxWidth: 220)
        .background(
            Color(red: 0.99, green: 0.96, blue: 0.89),
            in: RoundedRectangle(cornerRadius: 6)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 4)
                .strokeBorder(Self.gold.opacity(0.8), lineWidth: 1)
                .padding(3)
        }
        .shadow(color: .black.opacity(0.25), radius: 2, y: 1)
    }

    @ViewBuilder
    private var badgeLabel: some View {

        if let badge {
            Label(badge.title, systemImage: badge.icon)
                .font(.system(size: isShelfBook ? 10 : 12, weight: .semibold))
                .padding(.horizontal, isShelfBook ? KinSpacing.small - 2 : KinSpacing.small)
                .padding(.vertical, KinSpacing.xSmall)
                .background(.black.opacity(0.4), in: Capsule())
                .foregroundStyle(.white)
                .padding(isShelfBook ? KinSpacing.small : KinSpacing.medium)
        }
    }


    // MARK: - Cloth Colors

    /// Deep red, forest, navy, mustard, plum and teal.
    nonisolated static let clothColors: [Color] = [
        Color(red: 0.62, green: 0.16, blue: 0.16),
        Color(red: 0.20, green: 0.38, blue: 0.27),
        Color(red: 0.16, green: 0.24, blue: 0.40),
        Color(red: 0.74, green: 0.55, blue: 0.20),
        Color(red: 0.42, green: 0.22, blue: 0.38),
        Color(red: 0.15, green: 0.42, blue: 0.44)
    ]

    /// The same cookbook always gets the same color.
    nonisolated static func clothColorIndex(for id: UUID) -> Int {
        let sum = id.uuidString.unicodeScalars.reduce(0) { $0 + Int($1.value) }
        return sum % clothColors.count
    }

    nonisolated static func clothColor(for id: UUID) -> Color {
        clothColors[clothColorIndex(for: id)]
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

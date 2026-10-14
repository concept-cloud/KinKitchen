//
//  CookbookSectionRail.swift
//  KinKitchen
//
//  Created by Greg Hudler on 10/14/26.
//

import SwiftUI

/// The cookbook's thumb index: colored section tabs down the right
/// edge, like the dividers in a recipe binder. Tap a tab, or hold and
/// slide along the rail, to move between sections.
struct CookbookSectionRail: View {

    struct Tab: Identifiable, Equatable {
        let id: CookbookPage
        let title: String
        let recipeCount: Int
    }

    let tabs: [Tab]
    let selectedId: CookbookPage
    let onSelect: (CookbookPage) -> Void

    static let width: CGFloat = 58
    static let spacing: CGFloat = 4
    static let maxTabHeight: CGFloat = 76
    static let minTabHeight: CGFloat = 30

    @GestureState private var isDragging = false

    private var selectedIndex: Int {
        tabs.firstIndex { $0.id == selectedId } ?? 0
    }

    var body: some View {

        GeometryReader { proxy in

            let tabHeight =
                Self.tabHeight(
                    available: proxy.size.height,
                    count: tabs.count
                )

            VStack(
                alignment: .trailing,
                spacing: Self.spacing
            ) {

                ForEach(
                    Array(tabs.enumerated()),
                    id: \.element.id
                ) { index, tab in

                    tabView(
                        tab,
                        index: index,
                        height: tabHeight
                    )
                }
            }
            .frame(
                maxWidth: .infinity,
                alignment: .trailing
            )
            // One gesture for the whole rail: touching a tab selects it,
            // and sliding up or down moves through sections.
            .contentShape(Rectangle())
            .gesture(
                DragGesture(
                    minimumDistance: 0
                )
                .updating($isDragging) { _, state, _ in
                    state = true
                }
                .onChanged { value in

                    let index =
                        Self.index(
                            forY: value.location.y,
                            tabHeight: tabHeight,
                            count: tabs.count
                        )

                    if tabs.indices.contains(index),
                       tabs[index].id != selectedId {
                        onSelect(tabs[index].id)
                    }
                }
            )
        }
        .frame(width: Self.width + KinSpacing.small)
        .sensoryFeedback(
            .selection,
            trigger: selectedId
        )
        // VoiceOver: one adjustable control instead of a gesture.
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Sections")
        .accessibilityValue(
            tabs.isEmpty
                ? ""
                : "\(tabs[selectedIndex].title), \(selectedIndex + 1) of \(tabs.count)"
        )
        .accessibilityHint("Swipe up or down to change section")
        .accessibilityAdjustableAction { direction in

            switch direction {

            case .increment where selectedIndex + 1 < tabs.count:
                onSelect(tabs[selectedIndex + 1].id)

            case .decrement where selectedIndex > 0:
                onSelect(tabs[selectedIndex - 1].id)

            default:
                break
            }
        }
    }


    // MARK: - Tab

    private func tabView(
        _ tab: Tab,
        index: Int,
        height: CGFloat
    ) -> some View {

        let isSelected =
            tab.id == selectedId

        let color =
            Self.color(at: index)

        let showsLabel =
            height >= 52

        return VStack(
            spacing: KinSpacing.xxSmall
        ) {

            Image(
                systemName: Self.icon(for: tab.title)
            )
            .font(
                .system(
                    size: height >= 44 ? 17 : 13,
                    weight: .semibold
                )
            )

            if showsLabel {

                Text(tab.title)
                    .font(
                        .system(
                            size: 9,
                            weight: .semibold
                        )
                    )
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .padding(.horizontal, 2)
            }
        }
        .foregroundStyle(.white)
        .frame(
            width: isSelected
                ? Self.width + KinSpacing.small
                : Self.width,
            height: height
        )
        .background(
            color.opacity(isSelected ? 1 : 0.78)
        )
        .clipShape(
            UnevenRoundedRectangle(
                topLeadingRadius: KinRadius.medium,
                bottomLeadingRadius: KinRadius.medium
            )
        )
        .overlay(
            alignment: .leading
        ) {

            // Bright edge on the open section.
            if isSelected {
                Capsule()
                    .fill(.white)
                    .frame(
                        width: 3,
                        height: height * 0.5
                    )
                    .padding(.leading, 4)
            }
        }
        .shadow(
            color: .black.opacity(isSelected ? 0.25 : 0.1),
            radius: isSelected ? 5 : 2,
            x: -1
        )
        .scaleEffect(
            isSelected && isDragging ? 1.04 : 1,
            anchor: .trailing
        )
        .animation(
            .easeOut(duration: 0.15),
            value: isSelected
        )
    }
}


// MARK: - Layout & Style

extension CookbookSectionRail {

    /// Tabs share the rail's height, between the min and max sizes,
    /// so many sections still fit.
    nonisolated static func tabHeight(
        available: CGFloat,
        count: Int
    ) -> CGFloat {

        guard count > 0 else {
            return maxTabHeight
        }

        let fitted =
            (available - spacing * CGFloat(count - 1))
                / CGFloat(count)

        return min(
            maxTabHeight,
            max(minTabHeight, fitted)
        )
    }


    /// Which tab sits under a point on the rail, clamped to the ends
    /// so sliding past the first or last tab keeps it selected.
    nonisolated static func index(
        forY y: CGFloat,
        tabHeight: CGFloat,
        count: Int
    ) -> Int {

        guard count > 0 else {
            return 0
        }

        let raw =
            Int(
                (y / (tabHeight + spacing))
                    .rounded(.down)
            )

        return min(
            count - 1,
            max(0, raw)
        )
    }


    /// Binder-divider colors, repeating after six.
    static func color(
        at index: Int
    ) -> Color {

        let palette: [Color] = [
            KinColors.primary,
            Color(red: 0.93, green: 0.69, blue: 0.13),
            Color(red: 0.30, green: 0.62, blue: 0.35),
            Color(red: 0.91, green: 0.45, blue: 0.24),
            Color(red: 0.27, green: 0.52, blue: 0.80),
            Color(red: 0.58, green: 0.42, blue: 0.75)
        ]

        return palette[index % palette.count]
    }


    /// A matching icon for common section names, otherwise a bookmark.
    nonisolated static func icon(
        for title: String
    ) -> String {

        let name =
            title.lowercased()

        let matches: [(keywords: [String], icon: String)] = [
            (["breakfast", "brunch", "morning"], "sun.horizon.fill"),
            (["lunch", "sandwich"], "takeoutbag.and.cup.and.straw.fill"),
            (["dinner", "main", "entree", "supper"], "fork.knife"),
            (["side", "salad", "vegetable", "veggie"], "leaf.fill"),
            (["dessert", "sweet", "cake", "cookie", "bake", "pie"], "birthday.cake.fill"),
            (["drink", "beverage", "cocktail", "smoothie"], "cup.and.saucer.fill"),
            (["soup", "stew", "chili"], "flame.fill"),
            (["snack", "appetizer", "starter"], "carrot.fill"),
            (["holiday", "christmas", "thanksgiving", "easter"], "gift.fill"),
            (["favorite", "family"], "heart.fill"),
            (["grill", "bbq", "barbecue"], "flame.fill"),
            (["unsorted", "all recipes"], "tray.fill")
        ]

        return matches.first { entry in
            entry.keywords.contains { name.contains($0) }
        }?.icon ?? "bookmark.fill"
    }
}

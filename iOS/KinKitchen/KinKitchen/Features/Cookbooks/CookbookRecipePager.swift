//
//  CookbookRecipePager.swift
//  KinKitchen
//
//  Created by Greg Hudler on 10/14/26.
//

import SwiftUI

/// Recipes in one cookbook section, one per page, in saved order.
/// Swipe left or right to turn pages (or use the arrows); scroll up and
/// down within a recipe as usual. Pages stop at the section's first
/// and last recipe.
struct CookbookRecipePager: View {

    let sectionTitle: String
    let recipeIds: [UUID]
    let onClose: () -> Void

    @State private var currentId: UUID

    init(
        sectionTitle: String,
        recipeIds: [UUID],
        startingAt startId: UUID,
        onClose: @escaping () -> Void
    ) {
        self.sectionTitle = sectionTitle
        // Always include the recipe that was tapped.
        self.recipeIds =
            recipeIds.contains(startId) ? recipeIds : [startId]
        self.onClose = onClose
        _currentId = State(initialValue: startId)
    }

    private var position: RecipePagePosition {
        RecipePagePosition(
            ids: recipeIds,
            current: currentId
        )
    }

    var body: some View {

        TabView(selection: $currentId) {

            ForEach(recipeIds, id: \.self) { id in

                RecipeDetailView(
                    recipeId: id,
                    onBack: onClose
                )
                .tag(id)
            }
        }
        .tabViewStyle(
            .page(indexDisplayMode: .never)
        )
        .background(KinColors.background)
        .ignoresSafeArea(edges: .bottom)
        .safeAreaInset(edge: .bottom) {
            if recipeIds.count > 1 {
                pageBar
            }
        }
        .sensoryFeedback(
            .selection,
            trigger: currentId
        )
        .navigationBarHidden(true)
    }


    // MARK: - Page Bar

    /// "‹  Desserts · 3 of 8  ›": where you are, plus buttons for
    /// anyone who'd rather not swipe.
    private var pageBar: some View {

        HStack(spacing: KinSpacing.medium) {

            pageButton(
                systemImage: KinIcons.back,
                label: "Previous recipe",
                target: position.previous
            )

            VStack(spacing: KinSpacing.xxSmall) {

                Text(sectionTitle)
                    .font(KinTypography.caption)
                    .foregroundStyle(KinColors.secondaryText)
                    .lineLimit(1)

                Text(position.text)
                    .font(KinTypography.subheadline)
                    .foregroundStyle(KinColors.primaryText)
                    .monospacedDigit()
            }
            .frame(minWidth: 120)
            .accessibilityElement(children: .combine)

            pageButton(
                systemImage: KinIcons.forward,
                label: "Next recipe",
                target: position.next
            )
        }
        .padding(.horizontal, KinSpacing.small)
        .padding(.vertical, KinSpacing.xSmall)
        .background(.regularMaterial)
        .clipShape(Capsule())
        .shadow(color: .black.opacity(0.12), radius: 8, y: 2)
        .padding(.bottom, KinSpacing.small)
    }

    private func pageButton(
        systemImage: String,
        label: String,
        target: UUID?
    ) -> some View {

        Button {
            if let target {
                withAnimation {
                    currentId = target
                }
            }
        } label: {
            Image(systemName: systemImage)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(
                    target == nil
                        ? KinColors.secondaryText.opacity(0.4)
                        : KinColors.primary
                )
                .frame(width: 44, height: 44)
        }
        .buttonStyle(.plain)
        .disabled(target == nil)
        .accessibilityLabel(label)
    }
}


// MARK: - Position

/// Where the reader is within a section's recipes.
nonisolated struct RecipePagePosition: Equatable {

    let ids: [UUID]
    let current: UUID

    var index: Int {
        ids.firstIndex(of: current) ?? 0
    }

    /// nil on the first recipe: the section's start is a hard stop.
    var previous: UUID? {
        index > 0 ? ids[index - 1] : nil
    }

    /// nil on the last recipe.
    var next: UUID? {
        index + 1 < ids.count ? ids[index + 1] : nil
    }

    /// "3 of 8"
    var text: String {
        "\(index + 1) of \(ids.count)"
    }
}

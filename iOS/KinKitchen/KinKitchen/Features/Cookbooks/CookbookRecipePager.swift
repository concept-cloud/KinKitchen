//
//  CookbookRecipePager.swift
//  KinKitchen
//
//  Created by Greg Hudler on 10/14/26.
//

import SwiftUI

/// Reading a cookbook: one recipe per page, in saved order.
///
/// - Swipe left or right (or use the arrows) to turn pages within the
///   section; pages stop at its first and last recipe.
/// - The section tabs stay on the right edge. Tapping one goes back
///   to the cookbook open on that section's list, not straight into
///   one of its recipes.
/// - Scroll up and down within a recipe as usual.
struct CookbookRecipePager: View {

    struct Chapter: Identifiable, Equatable {
        let id: CookbookPage
        let title: String
        let recipeIds: [UUID]
    }

    let chapters: [Chapter]
    /// Hands back the section being read so the cookbook can open on it.
    let onClose: (CookbookPage) -> Void

    /// The section being read; fixed for the pager's life, since
    /// picking another section returns to the cookbook.
    @State private var chapterId: CookbookPage
    @State private var currentId: UUID
    @State private var fullDetailsId: UUID?

    init(
        chapters: [Chapter],
        startingIn chapterId: CookbookPage,
        at recipeId: UUID,
        onClose: @escaping (CookbookPage) -> Void
    ) {
        // Always include the recipe that was tapped.
        let found =
            chapters.contains {
                $0.id == chapterId && $0.recipeIds.contains(recipeId)
            }

        self.chapters =
            found
                ? chapters
                : [Chapter(id: chapterId, title: "Recipe", recipeIds: [recipeId])]

        self.onClose = onClose
        _chapterId = State(initialValue: chapterId)
        _currentId = State(initialValue: recipeId)
    }

    private var chapter: Chapter {
        chapters.first { $0.id == chapterId } ?? chapters[0]
    }

    private var position: RecipePagePosition {
        RecipePagePosition(
            ids: chapter.recipeIds,
            current: currentId
        )
    }

    private var showsRail: Bool {
        chapters.count > 1
    }

    var body: some View {

        Group {
            if chapter.recipeIds.isEmpty {
                emptyChapter
            } else {
                pages
            }
        }
        .background(KinColors.background)
        .overlay(alignment: .topTrailing) {
            if showsRail {
                CookbookSectionRail(
                    tabs: chapters.map {
                        CookbookSectionRail.Tab(
                            id: $0.id,
                            title: $0.title,
                            recipeCount: $0.recipeIds.count
                        )
                    },
                    selectedId: chapterId,
                    onSelect: { onClose($0) }
                )
                .padding(.top, 220)
                .padding(.bottom, 90)
                .ignoresSafeArea(edges: .trailing)
            }
        }
        .safeAreaInset(edge: .bottom) {
            if chapter.recipeIds.count > 1 {
                pageBar
            }
        }
        .sensoryFeedback(.selection, trigger: currentId)
        .navigationBarHidden(true)
        .kinKeepsScreenAwake()
        .navigationDestination(item: $fullDetailsId) { id in
            RecipeDetailView(
                recipeId: id,
                onBack: { fullDetailsId = nil }
            )
        }
    }

    private var pages: some View {

        TabView(selection: $currentId) {
            ForEach(chapter.recipeIds, id: \.self) { id in
                CookbookReadingPage(
                    recipeId: id,
                    trailingInset: showsRail ? CookbookSectionRail.width : 0,
                    onBack: { onClose(chapterId) },
                    onFullDetails: { fullDetailsId = id }
                )
                .tag(id)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .ignoresSafeArea(edges: .top)
        // A new section starts a fresh set of pages.
        .id(chapterId)
    }

    private var emptyChapter: some View {
        VStack(spacing: KinSpacing.medium) {
            Image(systemName: KinIcons.cookbooks)
                .font(.system(size: 36))
                .foregroundStyle(KinColors.secondaryText)
            Text("No recipes in \(chapter.title) yet.")
                .font(KinTypography.body)
                .foregroundStyle(KinColors.secondaryText)
            Button("Back to Cookbook") {
                onClose(chapterId)
            }
            .font(KinTypography.headline)
            .foregroundStyle(KinColors.primary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.trailing, showsRail ? CookbookSectionRail.width : 0)
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
                Text(chapter.title)
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
        .kinFloatingShadow()
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

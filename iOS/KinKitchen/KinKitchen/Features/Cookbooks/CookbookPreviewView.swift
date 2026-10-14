//
//  CookbookPreviewView.swift
//  KinKitchen
//
//  Created by Greg Hudler on 10/11/26.
//

import SwiftUI

// MARK: - Cookbook Preview Chapter

/// One section of the cookbook as it will be presented: a title, its
/// recipes in saved order, and which of them are featured. Built from
/// the live cookbook data.
struct CookbookPreviewChapter: Identifiable, Hashable {
    let id: String
    let title: String
    let recipes: [Recipe]
    let featuredRecipeIds: Set<UUID>

    func isFeatured(_ recipe: Recipe) -> Bool {
        featuredRecipeIds.contains(recipe.id)
    }
}

// MARK: - Preview Mode

enum CookbookPreviewMode: String, CaseIterable, Identifiable {
    /// Every recipe in full, for following your own cookbook.
    case fullBook = "Full Book"
    /// What a reader would see: only featured recipes in full.
    case reader = "Reader Preview"

    var id: String { rawValue }
}

// MARK: - Cookbook Preview View

/// Book-style preview: cover, contents, then each section followed by
/// its recipes in full. Swipe between pages. Nothing here changes the
/// cookbook.
struct CookbookPreviewView: View {

    @Environment(\.dismiss) private var dismiss

    let cookbook: Cookbook
    let coverImage: UIImage?
    let chapters: [CookbookPreviewChapter]

    @State private var mode: CookbookPreviewMode = .fullBook
    @State private var pageIndex = 0

    @State private var ingredientsByRecipe: [UUID: [RecipeIngredient]] = [:]
    @State private var isLoadingIngredients = true
    @State private var ingredientsFailed = false


    // MARK: Pages

    fileprivate enum Page: Hashable {
        case cover
        case contents
        case chapter(Int)
        case recipe(chapter: Int, recipeId: UUID)
    }

    /// Cover, contents, then each chapter followed by the recipes
    /// shown in full for the current mode.
    private var pages: [Page] {
        var result: [Page] = [.cover, .contents]

        for (index, chapter) in chapters.enumerated() {
            result.append(.chapter(index))

            for recipe in chapter.recipes
            where showsInFull(recipe, in: chapter) {
                result.append(
                    .recipe(chapter: index, recipeId: recipe.id)
                )
            }
        }

        return result
    }

    private func showsInFull(
        _ recipe: Recipe,
        in chapter: CookbookPreviewChapter
    ) -> Bool {
        mode == .fullBook || chapter.isFeatured(recipe)
    }

    private func pageIndex(
        of page: Page
    ) -> Int? {
        pages.firstIndex(of: page)
    }

    private var featuredCount: Int {
        chapters.reduce(0) {
            $0 + $1.recipes.filter($1.isFeatured).count
        }
    }

    private var recipeCount: Int {
        chapters.reduce(0) { $0 + $1.recipes.count }
    }


    var body: some View {

        ZStack(alignment: .top) {

            KinColors.background
                .ignoresSafeArea()

            TabView(selection: $pageIndex) {
                ForEach(
                    Array(pages.enumerated()),
                    id: \.offset
                ) { index, page in
                    pageView(page)
                        .tag(index)
                }
            }
            .tabViewStyle(
                .page(indexDisplayMode: .never)
            )
            .id(mode)

            topBar
        }
        .safeAreaInset(edge: .bottom) {
            pageProgress
        }
        .onChange(of: mode) {
            pageIndex = 0
        }
        .task {
            await loadIngredients()
        }
    }


    @ViewBuilder
    private func pageView(
        _ page: Page
    ) -> some View {
        switch page {
        case .cover:
            coverPage
        case .contents:
            contentsPage
        case .chapter(let index):
            chapterPage(chapters[index])
        case .recipe(let chapterIndex, let recipeId):
            if let recipe =
                chapters[chapterIndex].recipes
                    .first(where: { $0.id == recipeId }) {
                CookbookRecipePage(
                    recipe: recipe,
                    chapterTitle: chapters[chapterIndex].title,
                    ingredients: ingredientsByRecipe[recipe.id] ?? [],
                    isLoadingIngredients: isLoadingIngredients,
                    ingredientsFailed: ingredientsFailed
                )
            }
        }
    }


    @MainActor
    private func loadIngredients() async {

        let recipeIds =
            chapters.flatMap { $0.recipes.map(\.id) }

        do {
            let ingredients =
                try await RecipeService.fetchIngredients(
                    recipeIds: recipeIds
                )

            ingredientsByRecipe =
                Dictionary(grouping: ingredients, by: \.recipeId)
                    .mapValues {
                        $0.sorted { $0.sortOrder < $1.sortOrder }
                    }

        } catch {
            if !(error is CancellationError) {
                ingredientsFailed = true
            }
        }

        isLoadingIngredients = false
    }
}

// MARK: - Top Bar

private extension CookbookPreviewView {

    var topBar: some View {

        HStack(spacing: KinSpacing.medium) {

            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(KinColors.primaryText)
                    .frame(width: 36, height: 36)
                    .background(.regularMaterial)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Close Preview")

            Picker("Preview", selection: $mode) {
                ForEach(CookbookPreviewMode.allCases) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.segmented)
        }
        .padding(.horizontal, KinSpacing.large)
        .padding(.vertical, KinSpacing.small)
    }

    /// Section shortcuts (plus the cover and contents), then a thin
    /// progress line and "5 / 24", like the edge of a book.
    var pageProgress: some View {

        VStack(spacing: KinSpacing.xSmall) {

            sectionShortcuts

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(KinColors.secondaryText.opacity(0.2))
                    Capsule()
                        .fill(KinColors.primary)
                        .frame(
                            width: proxy.size.width
                                * CGFloat(pageIndex + 1)
                                / CGFloat(max(pages.count, 1))
                        )
                }
            }
            .frame(height: 3)
            .padding(.horizontal, KinSpacing.xxLarge)
            .padding(.top, KinSpacing.xSmall)
            .accessibilityHidden(true)

            Text("\(pageIndex + 1) / \(pages.count)")
                .font(KinTypography.caption2)
                .foregroundStyle(KinColors.secondaryText)
                .monospacedDigit()
                .accessibilityLabel("Page \(pageIndex + 1) of \(pages.count)")
        }
        .padding(.vertical, KinSpacing.small)
        .background(KinColors.background.opacity(0.95))
        .animation(.easeInOut(duration: 0.2), value: pageIndex)
    }

    /// The section being read, if any (nil on the cover and contents).
    var currentChapterIndex: Int? {
        guard pages.indices.contains(pageIndex) else {
            return nil
        }
        switch pages[pageIndex] {
        case .chapter(let index), .recipe(let index, _):
            return index
        case .cover, .contents:
            return nil
        }
    }

    /// Cover, Contents, then one chip per section in its tab color.
    /// The current one is filled in.
    var sectionShortcuts: some View {

        ScrollViewReader { proxy in

            ScrollView(.horizontal, showsIndicators: false) {

                HStack(spacing: KinSpacing.small) {

                    shortcut(
                        "Cover",
                        icon: KinIcons.cookbooks,
                        color: KinColors.primaryText,
                        isCurrent: pages.first == pages[safe: pageIndex]
                    ) {
                        jump(to: .cover)
                    }
                    .id("cover")

                    shortcut(
                        "Contents",
                        icon: "list.bullet",
                        color: KinColors.primaryText,
                        isCurrent: pages[safe: pageIndex] == .contents
                    ) {
                        jump(to: .contents)
                    }

                    ForEach(Array(chapters.enumerated()), id: \.element.id) { index, chapter in
                        shortcut(
                            chapter.title,
                            icon: CookbookSectionRail.icon(for: chapter.title),
                            color: CookbookSectionRail.color(at: index),
                            isCurrent: currentChapterIndex == index
                        ) {
                            jump(to: .chapter(index))
                        }
                        .id(index)
                    }
                }
                .padding(.horizontal, KinSpacing.large)
            }
            // Keep the current section's chip in view while swiping.
            .onChange(of: currentChapterIndex) { _, index in
                withAnimation {
                    if let index {
                        proxy.scrollTo(index, anchor: .center)
                    } else {
                        proxy.scrollTo("cover", anchor: .leading)
                    }
                }
            }
        }
    }

    func shortcut(
        _ title: String,
        icon: String,
        color: Color,
        isCurrent: Bool,
        action: @escaping () -> Void
    ) -> some View {

        Button(action: action) {
            Label(title, systemImage: icon)
                .font(KinTypography.footnote)
                .lineLimit(1)
                .foregroundStyle(isCurrent ? .white : color)
                .padding(.horizontal, KinSpacing.medium)
                .padding(.vertical, KinSpacing.small)
                .background(isCurrent ? color : color.opacity(0.12))
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isCurrent ? .isSelected : [])
    }

    /// Room for the top bar above each page's content.
    static let topInset: CGFloat = 60
}

// MARK: - Cover Page

private extension CookbookPreviewView {

    /// A real book cover: the photo fills the page, the title is set
    /// over it, and a darker spine runs down the left edge.
    var coverPage: some View {

        ZStack {

            if let coverImage {
                Color.clear
                    .overlay {
                        Image(uiImage: coverImage)
                            .resizable()
                            .scaledToFill()
                    }
                    .clipped()
            } else {
                LinearGradient(
                    colors: [KinColors.primary, KinColors.primary.opacity(0.7)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .overlay {
                    Image(systemName: KinIcons.cookbooks)
                        .font(.system(size: 90, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.25))
                }
            }

            LinearGradient(
                stops: [
                    .init(color: .black.opacity(0.35), location: 0),
                    .init(color: .black.opacity(0), location: 0.3),
                    .init(color: .black.opacity(0.1), location: 0.5),
                    .init(color: .black.opacity(0.8), location: 1)
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            // Book spine.
            HStack(spacing: 0) {
                LinearGradient(
                    colors: [.black.opacity(0.45), .black.opacity(0.1)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(width: 22)

                Rectangle()
                    .fill(.white.opacity(0.18))
                    .frame(width: 1)

                Spacer()
            }
        }
        .ignoresSafeArea()
        .overlay(alignment: .bottomLeading) {

            VStack(alignment: .leading, spacing: KinSpacing.small) {

                Text("A KIN KITCHEN COOKBOOK")
                    .font(.system(size: 12, weight: .bold))
                    .tracking(2)
                    .foregroundStyle(.white.opacity(0.85))

                Text(cookbook.name)
                    .font(.custom("Arvo-Bold", size: 40, relativeTo: .largeTitle))
                    .foregroundStyle(.white)
                    .lineLimit(3)
                    .minimumScaleFactor(0.6)

                if let description = cookbook.description,
                   !description.isEmpty {
                    Text(description)
                        .font(KinTypography.body)
                        .foregroundStyle(.white.opacity(0.9))
                        .lineLimit(3)
                }

                Text(summary)
                    .font(KinTypography.footnote)
                    .foregroundStyle(.white.opacity(0.85))
                    .padding(.top, KinSpacing.xSmall)

                Label("Swipe to open", systemImage: "hand.draw")
                    .font(KinTypography.caption)
                    .foregroundStyle(.white.opacity(0.75))
                    .padding(.top, KinSpacing.medium)
            }
            .shadow(color: .black.opacity(0.4), radius: 4, y: 1)
            .padding(.leading, KinSpacing.xLarge + 22)
            .padding(.trailing, KinSpacing.xLarge)
            .padding(.bottom, KinSpacing.xxLarge)
        }
        .overlay(alignment: .topTrailing) {
            Text(cookbook.displayPrice)
                .font(KinTypography.headline)
                .foregroundStyle(.white)
                .padding(.horizontal, KinSpacing.medium)
                .padding(.vertical, KinSpacing.xSmall)
                .background(KinColors.primary)
                .clipShape(Capsule())
                .padding(.top, Self.topInset + KinSpacing.medium)
                .padding(.trailing, KinSpacing.large)
        }
        .accessibilityElement(children: .combine)
    }

    var summary: String {
        let recipes =
            recipeCount == 1 ? "1 recipe" : "\(recipeCount) recipes"
        let sections =
            chapters.count == 1 ? "1 section" : "\(chapters.count) sections"

        switch mode {
        case .fullBook:
            return "\(recipes) · \(sections)"
        case .reader:
            return "\(recipes) · \(featuredCount) shown in this preview"
        }
    }
}

// MARK: - Contents Page

private extension CookbookPreviewView {

    var contentsPage: some View {

        ScrollView {

            VStack(alignment: .leading, spacing: KinSpacing.large) {

                Text("Contents")
                    .font(KinTypography.largeTitle)
                    .foregroundStyle(KinColors.primaryText)

                if chapters.isEmpty {
                    Text("This cookbook doesn't have any recipes yet.")
                        .font(KinTypography.body)
                        .foregroundStyle(KinColors.secondaryText)
                } else {
                    ForEach(
                        Array(chapters.enumerated()),
                        id: \.element.id
                    ) { index, chapter in
                        contentsChapter(chapter, index: index)
                    }
                }

                if mode == .reader && featuredCount == 0 {
                    Text("Feature up to \(CookbookRecipe.maxFeaturedPerSection) recipes per section to show them in full here.")
                        .font(KinTypography.footnote)
                        .foregroundStyle(KinColors.secondaryText)
                }
            }
            .padding(.horizontal, KinSpacing.large)
            .padding(.top, Self.topInset)
            .padding(.bottom, KinSpacing.xxLarge)
        }
    }

    /// Every recipe is listed so readers can see what's included.
    func contentsChapter(
        _ chapter: CookbookPreviewChapter,
        index: Int
    ) -> some View {

        let color = CookbookSectionRail.color(at: index)

        return VStack(alignment: .leading, spacing: KinSpacing.small) {

            Button {
                jump(to: .chapter(index))
            } label: {
                HStack(spacing: KinSpacing.medium) {
                    Image(systemName: CookbookSectionRail.icon(for: chapter.title))
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 36, height: 36)
                        .background(color)
                        .clipShape(RoundedRectangle(cornerRadius: KinRadius.small))

                    Text(chapter.title)
                        .font(KinTypography.title3)
                        .foregroundStyle(KinColors.primaryText)
                        .multilineTextAlignment(.leading)

                    Spacer(minLength: 0)

                    pageNumber(of: .chapter(index))
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            ForEach(chapter.recipes) { recipe in
                let inFull = showsInFull(recipe, in: chapter)
                let page = Page.recipe(chapter: index, recipeId: recipe.id)

                Button {
                    jump(to: page)
                } label: {
                    HStack(spacing: KinSpacing.small) {
                        if chapter.isFeatured(recipe) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 10))
                                .foregroundStyle(KinColors.warning)
                                .frame(width: 14)
                        } else if !inFull {
                            Image(systemName: KinIcons.lock)
                                .font(.system(size: 10))
                                .foregroundStyle(KinColors.secondaryText)
                                .frame(width: 14)
                        } else {
                            Color.clear.frame(width: 14, height: 1)
                        }

                        Text(recipe.name)
                            .font(KinTypography.body)
                            .foregroundStyle(
                                inFull ? KinColors.primaryText : KinColors.secondaryText
                            )
                            .lineLimit(1)

                        // Dotted leader to the page number, like a
                        // printed table of contents.
                        DottedLeader()

                        if inFull {
                            pageNumber(of: page)
                        }
                    }
                    .padding(.leading, 36 + KinSpacing.medium - 14 - KinSpacing.small)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .disabled(!inFull)
            }
        }
        .padding(KinSpacing.large)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(KinColors.surface)
        .overlay(alignment: .leading) {
            // Section color down the edge, like a divider tab.
            UnevenRoundedRectangle(
                topLeadingRadius: KinRadius.large,
                bottomLeadingRadius: KinRadius.large
            )
            .fill(color)
            .frame(width: 5)
        }
        .clipShape(RoundedRectangle(cornerRadius: KinRadius.large))
    }

    func pageNumber(of page: Page) -> some View {
        Text(pageIndex(of: page).map { "\($0 + 1)" } ?? "")
            .font(KinTypography.footnote)
            .foregroundStyle(KinColors.secondaryText)
            .monospacedDigit()
    }

    func jump(to page: Page) {
        guard let index = pageIndex(of: page) else {
            return
        }
        withAnimation {
            pageIndex = index
        }
    }
}

// MARK: - Chapter Page

private extension CookbookPreviewView {

    /// A full-color divider page, like the tabbed dividers in a
    /// recipe binder, listing what's in the section.
    func chapterPage(
        _ chapter: CookbookPreviewChapter
    ) -> some View {

        let chapterIndex = chapters.firstIndex(of: chapter) ?? 0
        let color = CookbookSectionRail.color(at: chapterIndex)

        return ScrollView {

            VStack(alignment: .leading, spacing: KinSpacing.large) {

                VStack(alignment: .leading, spacing: KinSpacing.small) {

                    Image(systemName: CookbookSectionRail.icon(for: chapter.title))
                        .font(.system(size: 44, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.9))

                    Text("SECTION \(chapterIndex + 1)")
                        .font(.system(size: 12, weight: .bold))
                        .tracking(2)
                        .foregroundStyle(.white.opacity(0.8))

                    Text(chapter.title)
                        .font(.custom("Arvo-Bold", size: 38, relativeTo: .largeTitle))
                        .foregroundStyle(.white)
                        .lineLimit(3)
                        .minimumScaleFactor(0.6)

                    Text(KinCookbookCoverCard.recipeCountText(chapter.recipes.count) ?? "")
                        .font(KinTypography.subheadline)
                        .foregroundStyle(.white.opacity(0.85))
                }
                .padding(.top, KinSpacing.xxLarge)
                .accessibilityElement(children: .combine)
                .accessibilityAddTraits(.isHeader)

                if chapter.recipes.isEmpty {
                    Text("No recipes in this section yet.")
                        .font(KinTypography.body)
                        .foregroundStyle(.white.opacity(0.85))
                } else {
                    ForEach(chapter.recipes) { recipe in
                        let inFull = showsInFull(recipe, in: chapter)

                        Button {
                            jump(
                                to: .recipe(
                                    chapter: chapterIndex,
                                    recipeId: recipe.id
                                )
                            )
                        } label: {
                            CookbookPreviewRecipeRow(
                                recipe: recipe,
                                isFeatured: chapter.isFeatured(recipe),
                                isLocked: !inFull
                            )
                        }
                        .buttonStyle(.plain)
                        .disabled(!inFull)
                    }
                }
            }
            .padding(.horizontal, KinSpacing.large)
            .padding(.top, Self.topInset)
            .padding(.bottom, KinSpacing.xxLarge)
        }
        .background(
            LinearGradient(
                colors: [color, color.opacity(0.75)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
    }
}

// MARK: - Recipe Row

/// A recipe in a section's list: photo, name, category and time.
/// Locked rows are recipes a reader can't see in full.
private struct CookbookPreviewRecipeRow: View {

    let recipe: Recipe
    let isFeatured: Bool
    let isLocked: Bool

    var body: some View {

        HStack(alignment: .top, spacing: KinSpacing.medium) {

            CookbookRecipePhoto(
                path: recipe.photoPath,
                size: 72
            )

            VStack(alignment: .leading, spacing: KinSpacing.xSmall) {

                Text(recipe.name)
                    .font(KinTypography.headline)
                    .foregroundStyle(KinColors.primaryText)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)

                if !recipe.previewDetails.isEmpty {
                    Text(recipe.previewDetails)
                        .font(KinTypography.caption)
                        .foregroundStyle(KinColors.secondaryText)
                }

                if isFeatured {
                    Label("Featured", systemImage: "star.fill")
                        .font(KinTypography.caption)
                        .foregroundStyle(KinColors.warning)
                } else if isLocked {
                    Label(
                        "Full recipe available in the cookbook",
                        systemImage: "lock.fill"
                    )
                    .font(KinTypography.caption)
                    .foregroundStyle(KinColors.secondaryText)
                }
            }

            Spacer(minLength: 0)

            if !isLocked {
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(KinColors.secondaryText)
            }
        }
        .padding(KinSpacing.medium)
        .background(KinColors.surface)
        .clipShape(
            RoundedRectangle(cornerRadius: KinRadius.large)
        )
        .opacity(isLocked ? 0.8 : 1)
    }
}

// MARK: - Recipe Page

/// A recipe printed in full, like a cookbook page: photo, details,
/// ingredients, steps, and its story.
private struct CookbookRecipePage: View {

    let recipe: Recipe
    let chapterTitle: String
    let ingredients: [RecipeIngredient]
    let isLoadingIngredients: Bool
    let ingredientsFailed: Bool


    var body: some View {

        ScrollView {

            VStack(spacing: 0) {

                // Photo across the top of the page.
                CookbookRecipePhoto(
                    path: recipe.photoPath,
                    size: nil
                )
                .frame(height: 280)

                VStack(alignment: .leading, spacing: KinSpacing.xLarge) {

                    VStack(alignment: .leading, spacing: KinSpacing.small) {

                        Text(chapterTitle.uppercased())
                            .font(.system(size: 12, weight: .bold))
                            .tracking(1.5)
                            .foregroundStyle(KinColors.primary)

                        Text(recipe.name)
                            .font(KinTypography.largeTitle)
                            .foregroundStyle(KinColors.primaryText)

                        if !metadata.isEmpty {
                            Text(metadata)
                                .font(KinTypography.footnote)
                                .foregroundStyle(KinColors.secondaryText)
                        }
                    }

                    if let description = cleaned(recipe.description) {
                        Text(description)
                            .font(KinTypography.body)
                            .italic()
                            .foregroundStyle(KinColors.secondaryText)
                    }

                    ingredientsSection

                    instructionsSection

                    storySection
                }
                .padding(KinSpacing.large)
                .padding(.bottom, KinSpacing.xxLarge)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    UnevenRoundedRectangle(
                        topLeadingRadius: KinRadius.xLarge,
                        topTrailingRadius: KinRadius.xLarge
                    )
                    .fill(CookbookReadingPage.paper)
                    .shadow(color: .black.opacity(0.08), radius: 10, y: -2)
                )
                .offset(y: -28)
            }
        }
    }


    /// e.g. "Dinner · Serves 6 · Prep 20 min · Cook 3 hrs"
    private var metadata: String {
        var parts: [String] = []

        if let category = cleaned(recipe.category) {
            parts.append(category)
        }
        if let servings = recipe.servings, servings > 0 {
            parts.append("Serves \(servings)")
        }
        if (recipe.prepTimeMinutes ?? 0) > 0 {
            parts.append("Prep \(recipe.formattedPrepTime)")
        }
        if (recipe.cookTimeMinutes ?? 0) > 0 {
            parts.append("Cook \(recipe.formattedCookTime)")
        }

        return parts.joined(separator: " · ")
    }


    private var ingredientsSection: some View {

        VStack(alignment: .leading, spacing: KinSpacing.small) {

            pageHeading("Ingredients")

            if isLoadingIngredients {
                ProgressView()
                    .tint(KinColors.primary)
            } else if ingredientsFailed {
                Text("Ingredients couldn't be loaded.")
                    .font(KinTypography.body)
                    .foregroundStyle(KinColors.secondaryText)
            } else if ingredients.isEmpty {
                Text("No ingredients listed.")
                    .font(KinTypography.body)
                    .foregroundStyle(KinColors.secondaryText)
            } else {
                ForEach(ingredients) { ingredient in
                    HStack(alignment: .firstTextBaseline, spacing: KinSpacing.small) {
                        Text("•")
                            .foregroundStyle(KinColors.primary)

                        Text(ingredientLine(ingredient))
                            .foregroundStyle(KinColors.primaryText)
                    }
                    .font(KinTypography.body)
                }
            }
        }
    }


    private var instructionsSection: some View {

        VStack(alignment: .leading, spacing: KinSpacing.small) {

            pageHeading("Instructions")

            let steps = instructionSteps

            if steps.isEmpty {
                Text("No instructions listed.")
                    .font(KinTypography.body)
                    .foregroundStyle(KinColors.secondaryText)
            } else {
                ForEach(
                    Array(steps.enumerated()),
                    id: \.offset
                ) { index, step in
                    HStack(alignment: .top, spacing: KinSpacing.medium) {
                        Text("\(index + 1)")
                            .font(KinTypography.headline)
                            .foregroundStyle(.white)
                            .frame(width: 28, height: 28)
                            .background(KinColors.primary)
                            .clipShape(Circle())

                        Text(step)
                            .font(KinTypography.body)
                            .foregroundStyle(KinColors.primaryText)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
    }


    @ViewBuilder
    private var storySection: some View {

        let contributor = cleaned(recipe.originalContributor)
        let story = cleaned(recipe.story)

        if contributor != nil || story != nil {
            VStack(alignment: .leading, spacing: KinSpacing.small) {

                pageHeading("Story & Legacy")

                if let contributor {
                    Text("Originally from \(contributor)")
                        .font(KinTypography.headline)
                        .foregroundStyle(KinColors.primaryText)
                }

                if let story {
                    Text(story)
                        .font(KinTypography.body)
                        .italic()
                        .foregroundStyle(KinColors.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(KinSpacing.large)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(KinColors.surface)
            .clipShape(
                RoundedRectangle(cornerRadius: KinRadius.large)
            )
        }
    }


    private func pageHeading(
        _ title: String
    ) -> some View {
        Text(title)
            .font(KinTypography.title2)
            .foregroundStyle(KinColors.primaryText)
    }


    /// e.g. "1 1/2 cups flour"
    private func ingredientLine(
        _ ingredient: RecipeIngredient
    ) -> String {
        [
            ingredient.quantity.map(IngredientQuantityFormatter.format),
            cleaned(ingredient.unit),
            ingredient.name
        ]
        .compactMap { $0 }
        .joined(separator: " ")
    }


    /// Steps are stored as "1. …" lines; the numbers are drawn
    /// separately, so strip them here.
    private var instructionSteps: [String] {
        (recipe.instructions ?? "")
            .split(whereSeparator: \.isNewline)
            .map {
                $0.replacingOccurrences(
                    of: #"^\s*\d+[.)]\s*"#,
                    with: "",
                    options: .regularExpression
                )
                .trimmingCharacters(in: .whitespaces)
            }
            .filter { !$0.isEmpty }
    }


    private func cleaned(
        _ value: String?
    ) -> String? {
        let trimmed =
            value?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmed.isEmpty ? nil : trimmed
    }
}

// MARK: - Recipe Photo

/// Loads a recipe photo. A fixed `size` gives a square thumbnail;
/// nil gives a full-width banner.
private struct CookbookRecipePhoto: View {

    let path: String?
    let size: CGFloat?

    @State private var photo: UIImage?

    var body: some View {

        ZStack {
            RoundedRectangle(cornerRadius: KinRadius.medium)
                .fill(KinColors.primary.opacity(0.12))

            if let photo {
                // Color.clear takes the space offered; the photo fills
                // it without widening the page.
                Color.clear
                    .overlay {
                        Image(uiImage: photo)
                            .resizable()
                            .scaledToFill()
                    }
                    .clipped()
            } else {
                Image(systemName: "fork.knife")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(KinColors.primary)
            }
        }
        .frame(width: size, height: size ?? 280)
        .frame(maxWidth: size == nil ? .infinity : nil)
        .clipShape(
            RoundedRectangle(
                cornerRadius: size == nil ? 0 : KinRadius.medium
            )
        )
        .task(id: path) {
            await loadPhoto()
        }
    }

    @MainActor
    private func loadPhoto() async {
        guard
            let path,
            !path.isEmpty,
            let data =
                try? await RecipeService.fetchRecipePhoto(path: path)
        else {
            return
        }

        photo = UIImage(data: data)
    }
}

// MARK: - Recipe Preview Details

private extension Recipe {

    /// e.g. "Dinner · 45 min"
    var previewDetails: String {
        var parts: [String] = []

        if let category = category?
            .trimmingCharacters(in: .whitespacesAndNewlines),
           !category.isEmpty {
            parts.append(category)
        }

        if totalTimeMinutes > 0 {
            parts.append(formattedTotalTime)
        }

        return parts.joined(separator: " · ")
    }
}


// MARK: - Dotted Leader

/// "Sunday Gravy ........ 7" dots between a title and its page number.
private struct DottedLeader: View {

    var body: some View {
        GeometryReader { proxy in
            Path { path in
                let y = proxy.size.height * 0.7
                path.move(to: CGPoint(x: 0, y: y))
                path.addLine(to: CGPoint(x: proxy.size.width, y: y))
            }
            .stroke(
                KinColors.secondaryText.opacity(0.5),
                style: StrokeStyle(lineWidth: 1, dash: [1, 4])
            )
        }
        .frame(height: 14)
        .frame(minWidth: 12)
        .accessibilityHidden(true)
    }
}


// MARK: - Safe Index

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

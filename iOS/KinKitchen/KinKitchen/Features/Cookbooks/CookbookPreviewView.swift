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

        VStack(spacing: KinSpacing.small) {

            HStack {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(KinColors.primaryText)
                        .frame(width: 40, height: 40)
                        .background(KinColors.surface)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Close Preview")

                Spacer()

                Text("Page \(pageIndex + 1) of \(pages.count)")
                    .font(KinTypography.caption)
                    .foregroundStyle(KinColors.secondaryText)
                    .padding(.horizontal, KinSpacing.medium)
                    .padding(.vertical, KinSpacing.xSmall)
                    .background(KinColors.surface)
                    .clipShape(Capsule())
            }

            Picker("Preview", selection: $mode) {
                ForEach(CookbookPreviewMode.allCases) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.segmented)
        }
        .padding(.horizontal, KinSpacing.large)
        .padding(.top, KinSpacing.small)
        .padding(.bottom, KinSpacing.small)
        .background(KinColors.background.opacity(0.95))
    }

    /// Room for the top bar above each page's content.
    static let topInset: CGFloat = 112
}

// MARK: - Cover Page

private extension CookbookPreviewView {

    var coverPage: some View {

        ScrollView {

            VStack(spacing: KinSpacing.xLarge) {

                ZStack(alignment: .topTrailing) {
                    ZStack {
                        RoundedRectangle(cornerRadius: KinRadius.large)
                            .fill(KinColors.primary.opacity(0.12))

                        if let coverImage {
                            Image(uiImage: coverImage)
                                .resizable()
                                .scaledToFill()
                        } else {
                            Image(systemName: KinIcons.cookbooks)
                                .font(.system(size: 72, weight: .semibold))
                                .foregroundStyle(KinColors.primary)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 340)
                    .clipShape(
                        RoundedRectangle(cornerRadius: KinRadius.large)
                    )

                    Text(cookbook.displayPrice)
                        .font(KinTypography.headline)
                        .foregroundStyle(.white)
                        .padding(.horizontal, KinSpacing.medium)
                        .padding(.vertical, KinSpacing.xSmall)
                        .background(KinColors.primary)
                        .clipShape(Capsule())
                        .padding(KinSpacing.medium)
                }
                .shadow(color: .black.opacity(0.12), radius: 12, y: 6)

                VStack(spacing: KinSpacing.medium) {

                    Text(cookbook.name)
                        .font(KinTypography.largeTitle)
                        .foregroundStyle(KinColors.primaryText)
                        .multilineTextAlignment(.center)

                    if let description = cookbook.description,
                       !description.isEmpty {
                        Text(description)
                            .font(KinTypography.body)
                            .foregroundStyle(KinColors.secondaryText)
                            .multilineTextAlignment(.center)
                    }

                    Text(summary)
                        .font(KinTypography.caption)
                        .foregroundStyle(KinColors.secondaryText)
                        .multilineTextAlignment(.center)
                }

                Label("Swipe to turn the page", systemImage: "hand.draw")
                    .font(KinTypography.caption)
                    .foregroundStyle(KinColors.secondaryText)
            }
            .padding(.horizontal, KinSpacing.large)
            .padding(.top, Self.topInset)
            .padding(.bottom, KinSpacing.xxLarge)
        }
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

        VStack(alignment: .leading, spacing: KinSpacing.small) {

            Button {
                jump(to: .chapter(index))
            } label: {
                HStack(alignment: .firstTextBaseline) {
                    Text("\(index + 1)")
                        .font(KinTypography.headline)
                        .foregroundStyle(KinColors.primary)
                        .frame(width: 24, alignment: .leading)

                    Text(chapter.title)
                        .font(KinTypography.title3)
                        .foregroundStyle(KinColors.primaryText)
                        .multilineTextAlignment(.leading)

                    Spacer(minLength: 0)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            ForEach(chapter.recipes) { recipe in
                let inFull = showsInFull(recipe, in: chapter)

                Button {
                    jump(to: .recipe(chapter: index, recipeId: recipe.id))
                } label: {
                    HStack(spacing: KinSpacing.small) {
                        Image(
                            systemName:
                                chapter.isFeatured(recipe)
                                    ? "star.fill"
                                    : inFull ? "circle.fill" : "lock.fill"
                        )
                        .font(.system(size: chapter.isFeatured(recipe) ? 11 : 6))
                        .foregroundStyle(
                            chapter.isFeatured(recipe)
                                ? KinColors.warning
                                : KinColors.secondaryText
                        )
                        .frame(width: 16)

                        Text(recipe.name)
                            .font(KinTypography.body)
                            .foregroundStyle(
                                inFull
                                    ? KinColors.primaryText
                                    : KinColors.secondaryText
                            )
                            .multilineTextAlignment(.leading)

                        Spacer(minLength: 0)
                    }
                    .padding(.leading, 24)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .disabled(!inFull)
            }
        }
        .padding(KinSpacing.large)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(KinColors.surface)
        .clipShape(
            RoundedRectangle(cornerRadius: KinRadius.large)
        )
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

    func chapterPage(
        _ chapter: CookbookPreviewChapter
    ) -> some View {

        let chapterIndex =
            chapters.firstIndex(of: chapter) ?? 0

        return ScrollView {

            VStack(alignment: .leading, spacing: KinSpacing.large) {

                VStack(alignment: .leading, spacing: KinSpacing.xSmall) {
                    Text(chapter.title)
                        .font(KinTypography.largeTitle)
                        .foregroundStyle(KinColors.primaryText)

                    Rectangle()
                        .fill(KinColors.primary)
                        .frame(width: 48, height: 3)
                        .clipShape(Capsule())
                }

                if chapter.recipes.isEmpty {
                    Text("No recipes in this section yet.")
                        .font(KinTypography.body)
                        .foregroundStyle(KinColors.secondaryText)
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

            VStack(alignment: .leading, spacing: KinSpacing.xLarge) {

                VStack(alignment: .leading, spacing: KinSpacing.small) {

                    Text(chapterTitle.uppercased())
                        .font(KinTypography.caption)
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

                if recipe.photoPath?.isEmpty == false {
                    CookbookRecipePhoto(
                        path: recipe.photoPath,
                        size: nil
                    )
                }

                if let description = cleaned(recipe.description) {
                    Text(description)
                        .font(KinTypography.body)
                        .foregroundStyle(KinColors.secondaryText)
                }

                ingredientsSection

                instructionsSection

                storySection
            }
            .padding(.horizontal, KinSpacing.large)
            .padding(.top, CookbookPreviewView.topInset)
            .padding(.bottom, KinSpacing.xxLarge)
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
                    HStack(alignment: .firstTextBaseline, spacing: KinSpacing.medium) {
                        Text("\(index + 1)")
                            .font(KinTypography.headline)
                            .foregroundStyle(KinColors.primary)
                            .frame(width: 22, alignment: .leading)

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
                Image(uiImage: photo)
                    .resizable()
                    .scaledToFill()
            } else {
                Image(systemName: "fork.knife")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(KinColors.primary)
            }
        }
        .frame(width: size, height: size ?? 220)
        .frame(maxWidth: size == nil ? .infinity : nil)
        .clipShape(
            RoundedRectangle(cornerRadius: KinRadius.medium)
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

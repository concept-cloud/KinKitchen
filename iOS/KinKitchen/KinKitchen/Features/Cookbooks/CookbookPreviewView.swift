//
//  CookbookPreviewView.swift
//  KinKitchen
//
//  Created by Greg Hudler on 10/11/26.
//

import SwiftUI

// MARK: - Cookbook Preview Chapter

/// One section of the cookbook as it will be presented: a title and
/// its recipes in saved order. Built from the live cookbook data.
struct CookbookPreviewChapter: Identifiable, Hashable {
    let id: String
    let title: String
    let recipes: [Recipe]
}

// MARK: - Cookbook Preview View

/// Read-only, book-style preview: cover, contents, then one page per
/// section. Swipe between pages. Nothing here changes the cookbook.
struct CookbookPreviewView: View {

    @Environment(\.dismiss) private var dismiss

    let cookbook: Cookbook
    let coverImage: UIImage?
    let chapters: [CookbookPreviewChapter]

    @State private var pageIndex = 0


    /// Cover, contents, then a page per chapter.
    private var pageCount: Int {
        2 + chapters.count
    }

    private var recipeCount: Int {
        chapters.reduce(0) { $0 + $1.recipes.count }
    }


    var body: some View {

        ZStack(alignment: .top) {

            KinColors.background
                .ignoresSafeArea()

            TabView(selection: $pageIndex) {

                coverPage
                    .tag(0)

                contentsPage
                    .tag(1)

                ForEach(
                    Array(chapters.enumerated()),
                    id: \.element.id
                ) { index, chapter in
                    chapterPage(chapter)
                        .tag(index + 2)
                }
            }
            .tabViewStyle(
                .page(indexDisplayMode: .never)
            )

            topBar
        }
    }
}

// MARK: - Top Bar

private extension CookbookPreviewView {

    var topBar: some View {

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

            Text("Page \(pageIndex + 1) of \(pageCount)")
                .font(KinTypography.caption)
                .foregroundStyle(KinColors.secondaryText)
                .padding(.horizontal, KinSpacing.medium)
                .padding(.vertical, KinSpacing.xSmall)
                .background(KinColors.surface)
                .clipShape(Capsule())
        }
        .padding(.horizontal, KinSpacing.large)
        .padding(.top, KinSpacing.small)
    }
}

// MARK: - Cover Page

private extension CookbookPreviewView {

    var coverPage: some View {

        ScrollView {

            VStack(spacing: KinSpacing.xLarge) {

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
                .frame(height: 360)
                .clipShape(
                    RoundedRectangle(cornerRadius: KinRadius.large)
                )
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
                }

                swipeHint
            }
            .padding(.horizontal, KinSpacing.large)
            .padding(.top, 72)
            .padding(.bottom, KinSpacing.xxLarge)
        }
    }

    var summary: String {
        let recipes =
            recipeCount == 1 ? "1 recipe" : "\(recipeCount) recipes"
        let sections =
            chapters.count == 1 ? "1 section" : "\(chapters.count) sections"
        return "\(recipes) · \(sections)"
    }

    var swipeHint: some View {
        Label("Swipe to turn the page", systemImage: "hand.draw")
            .font(KinTypography.caption)
            .foregroundStyle(KinColors.secondaryText)
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
                    VStack(spacing: 0) {
                        ForEach(
                            Array(chapters.enumerated()),
                            id: \.element.id
                        ) { index, chapter in
                            Button {
                                withAnimation {
                                    pageIndex = index + 2
                                }
                            } label: {
                                contentsRow(
                                    chapter,
                                    number: index + 1
                                )
                            }
                            .buttonStyle(.plain)

                            if index < chapters.count - 1 {
                                Divider()
                            }
                        }
                    }
                    .padding(.horizontal, KinSpacing.large)
                    .background(KinColors.surface)
                    .clipShape(
                        RoundedRectangle(cornerRadius: KinRadius.large)
                    )
                }
            }
            .padding(.horizontal, KinSpacing.large)
            .padding(.top, 72)
            .padding(.bottom, KinSpacing.xxLarge)
        }
    }

    func contentsRow(
        _ chapter: CookbookPreviewChapter,
        number: Int
    ) -> some View {

        HStack(alignment: .firstTextBaseline, spacing: KinSpacing.medium) {

            Text("\(number)")
                .font(KinTypography.headline)
                .foregroundStyle(KinColors.primary)
                .frame(width: 24, alignment: .leading)

            Text(chapter.title)
                .font(KinTypography.title3)
                .foregroundStyle(KinColors.primaryText)
                .multilineTextAlignment(.leading)
                .lineLimit(2)

            Spacer(minLength: KinSpacing.small)

            Text(
                chapter.recipes.count == 1
                    ? "1 recipe"
                    : "\(chapter.recipes.count) recipes"
            )
            .font(KinTypography.caption)
            .foregroundStyle(KinColors.secondaryText)
        }
        .padding(.vertical, KinSpacing.medium)
        .contentShape(Rectangle())
    }
}

// MARK: - Chapter Page

private extension CookbookPreviewView {

    func chapterPage(
        _ chapter: CookbookPreviewChapter
    ) -> some View {

        ScrollView {

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
                        CookbookPreviewRecipeRow(recipe: recipe)
                    }
                }
            }
            .padding(.horizontal, KinSpacing.large)
            .padding(.top, 72)
            .padding(.bottom, KinSpacing.xxLarge)
        }
    }
}

// MARK: - Recipe Row

/// A recipe as it appears in the preview: photo, name, category and
/// time, plus a short description when there is one.
private struct CookbookPreviewRecipeRow: View {

    let recipe: Recipe

    @State private var photo: UIImage?


    var body: some View {

        HStack(alignment: .top, spacing: KinSpacing.medium) {

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
            .frame(width: 72, height: 72)
            .clipShape(
                RoundedRectangle(cornerRadius: KinRadius.medium)
            )

            VStack(alignment: .leading, spacing: KinSpacing.xSmall) {

                Text(recipe.name)
                    .font(KinTypography.headline)
                    .foregroundStyle(KinColors.primaryText)
                    .lineLimit(2)

                if !details.isEmpty {
                    Text(details)
                        .font(KinTypography.caption)
                        .foregroundStyle(KinColors.secondaryText)
                }

                if let description = recipe.description?
                    .trimmingCharacters(in: .whitespacesAndNewlines),
                   !description.isEmpty {
                    Text(description)
                        .font(KinTypography.footnote)
                        .foregroundStyle(KinColors.secondaryText)
                        .lineLimit(2)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(KinSpacing.medium)
        .background(KinColors.surface)
        .clipShape(
            RoundedRectangle(cornerRadius: KinRadius.large)
        )
        .task(id: recipe.photoPath) {
            await loadPhoto()
        }
    }


    private var details: String {
        var parts: [String] = []

        if let category = recipe.category?
            .trimmingCharacters(in: .whitespacesAndNewlines),
           !category.isEmpty {
            parts.append(category)
        }

        if recipe.totalTimeMinutes > 0 {
            parts.append(recipe.formattedTotalTime)
        }

        return parts.joined(separator: " · ")
    }


    @MainActor
    private func loadPhoto() async {

        guard
            let path = recipe.photoPath,
            !path.isEmpty,
            let data =
                try? await RecipeService.fetchRecipePhoto(path: path)
        else {
            return
        }

        photo = UIImage(data: data)
    }
}

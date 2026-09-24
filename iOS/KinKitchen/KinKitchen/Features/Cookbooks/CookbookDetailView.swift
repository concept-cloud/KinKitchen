//
//  CookbookDetailView.swift
//  KinKitchen
//
//  Created by Greg Hudler on 9/23/26.
//

import SwiftUI

struct CookbookDetailView: View {

    let cookbookId: UUID

    @Environment(\.dismiss) private var dismiss

    @State private var cookbook: Cookbook?
    @State private var recipes: [Recipe] = []
    @State private var selectedRecipeId: UUID?
    @State private var isLoading = true
    @State private var errorMessage: String?

    var body: some View {
        ZStack {
            KinColors.background
                .ignoresSafeArea()

            content
        }
        .navigationBarHidden(true)
        .task {
            await loadCookbook()
        }
        .refreshable {
            await loadCookbook()
        }
        .navigationDestination(
            isPresented: Binding(
                get: { selectedRecipeId != nil },
                set: {
                    if !$0 {
                        selectedRecipeId = nil
                    }
                }
            )
        ) {
            if let selectedRecipeId {
                RecipeDetailView(
                    recipeId: selectedRecipeId,
                    onBack: {
                        self.selectedRecipeId = nil
                    }
                )
            }
        }
    }
}

// MARK: - Content

private extension CookbookDetailView {

    @ViewBuilder
    var content: some View {
        if isLoading {
            loadingState
        } else if let errorMessage {
            errorState(errorMessage)
        } else if let cookbook {
            cookbookContent(cookbook)
        }
    }
}

// MARK: - Cookbook Content

private extension CookbookDetailView {

    func cookbookContent(
        _ cookbook: Cookbook
    ) -> some View {
        ScrollView {
            VStack(
                alignment: .leading,
                spacing: KinSpacing.xLarge
            ) {
                header(cookbook)

                cookbookInformation(cookbook)

                recipesSection
            }
            .padding(
                .horizontal,
                KinSpacing.large
            )
            .padding(
                .bottom,
                KinSpacing.xxLarge
            )
        }
    }
}

// MARK: - Header

private extension CookbookDetailView {

    func header(
        _ cookbook: Cookbook
    ) -> some View {
        VStack(
            alignment: .leading,
            spacing: KinSpacing.large
        ) {
            HStack {
                Button {
                    dismiss()
                } label: {
                    Image(
                        systemName: "chevron.left"
                    )
                    .font(
                        .system(
                            size: 20,
                            weight: .semibold
                        )
                    )
                    .foregroundStyle(
                        KinColors.primaryText
                    )
                    .frame(
                        width: 44,
                        height: 44
                    )
                    .background(
                        KinColors.surface
                    )
                    .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Back")

                Spacer()

                Menu {
                    Button {
                    } label: {
                        Label(
                            "Edit Cookbook",
                            systemImage: "pencil"
                        )
                    }

                    Button(
                        role: .destructive
                    ) {
                    } label: {
                        Label(
                            "Delete Cookbook",
                            systemImage: "trash"
                        )
                    }
                } label: {
                    Image(
                        systemName: "ellipsis"
                    )
                    .font(
                        .system(
                            size: 20,
                            weight: .semibold
                        )
                    )
                    .foregroundStyle(
                        KinColors.primaryText
                    )
                    .frame(
                        width: 44,
                        height: 44
                    )
                    .background(
                        KinColors.surface
                    )
                    .clipShape(Circle())
                }
            }

            cookbookCover(cookbook)

            Text(cookbook.name)
                .font(
                    KinTypography.largeTitle
                )
                .foregroundStyle(
                    KinColors.primaryText
                )
        }
        .padding(
            .top,
            KinSpacing.large
        )
    }
}

// MARK: - Cookbook Cover

private extension CookbookDetailView {

    func cookbookCover(
        _ cookbook: Cookbook
    ) -> some View {
        ZStack {
            RoundedRectangle(
                cornerRadius: KinRadius.medium
            )
            .fill(
                KinColors.primary.opacity(0.12)
            )

            Image(
                systemName: KinIcons.cookbooks
            )
            .font(
                .system(
                    size: 54,
                    weight: .semibold
                )
            )
            .foregroundStyle(
                KinColors.primary
            )
        }
        .frame(
            maxWidth: .infinity
        )
        .frame(
            height: 190
        )
    }
}

// MARK: - Cookbook Information

private extension CookbookDetailView {

    @ViewBuilder
    func cookbookInformation(
        _ cookbook: Cookbook
    ) -> some View {
        if let description = cookbook.description,
           !description.isEmpty {
            Text(description)
                .font(
                    KinTypography.body
                )
                .foregroundStyle(
                    KinColors.secondaryText
                )
        }
    }
}

// MARK: - Recipes

private extension CookbookDetailView {

    var recipesSection: some View {
        VStack(
            alignment: .leading,
            spacing: KinSpacing.medium
        ) {
            HStack {
                Text("Recipes")
                    .font(
                        KinTypography.title
                    )
                    .foregroundStyle(
                        KinColors.primaryText
                    )

                Spacer()

                Text("\(recipes.count)")
                    .font(
                        KinTypography.headline
                    )
                    .foregroundStyle(
                        KinColors.secondaryText
                    )
            }

            if recipes.isEmpty {
                emptyRecipesState
            } else {
                LazyVStack(
                    spacing: KinSpacing.medium
                ) {
                    ForEach(recipes) { recipe in
                        Button {
                            selectedRecipeId = recipe.id
                        } label: {
                            recipeCard(recipe)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    var emptyRecipesState: some View {
        VStack(
            spacing: KinSpacing.medium
        ) {
            Image(
                systemName: "fork.knife"
            )
            .font(
                .system(size: 36)
            )
            .foregroundStyle(
                KinColors.primary
            )

            Text("No Recipes Yet")
                .font(
                    KinTypography.title3
                )
                .foregroundStyle(
                    KinColors.primaryText
                )

            Text(
                "Recipes added to this cookbook will appear here."
            )
            .font(
                KinTypography.body
            )
            .foregroundStyle(
                KinColors.secondaryText
            )
            .multilineTextAlignment(.center)
        }
        .frame(
            maxWidth: .infinity
        )
        .padding(
            .vertical,
            KinSpacing.xxLarge
        )
        .padding(
            .horizontal,
            KinSpacing.large
        )
        .background(
            KinColors.surface
        )
        .clipShape(
            RoundedRectangle(
                cornerRadius: KinRadius.medium
            )
        )
    }

    func recipeCard(
        _ recipe: Recipe
    ) -> some View {
        HStack(
            spacing: KinSpacing.medium
        ) {
            ZStack {
                RoundedRectangle(
                    cornerRadius: KinRadius.medium
                )
                .fill(
                    KinColors.primary.opacity(0.12)
                )

                Image(
                    systemName: "fork.knife"
                )
                .font(
                    .system(
                        size: 24,
                        weight: .semibold
                    )
                )
                .foregroundStyle(
                    KinColors.primary
                )
            }
            .frame(
                width: 64,
                height: 64
            )

            Text(recipe.name)
                .font(
                    KinTypography.headline
                )
                .foregroundStyle(
                    KinColors.primaryText
                )
                .multilineTextAlignment(
                    .leading
                )
                .lineLimit(2)

            Spacer()

            Image(
                systemName: "chevron.right"
            )
            .font(
                .system(
                    size: 14,
                    weight: .semibold
                )
            )
            .foregroundStyle(
                KinColors.secondaryText
            )
        }
        .padding(
            KinSpacing.medium
        )
        .frame(
            maxWidth: .infinity,
            alignment: .leading
        )
        .background(
            KinColors.surface
        )
        .clipShape(
            RoundedRectangle(
                cornerRadius: KinRadius.medium
            )
        )
    }
}

// MARK: - Loading State

private extension CookbookDetailView {

    var loadingState: some View {
        VStack(
            spacing: KinSpacing.medium
        ) {
            ProgressView()
                .tint(
                    KinColors.primary
                )

            Text("Loading cookbook...")
                .font(
                    KinTypography.body
                )
                .foregroundStyle(
                    KinColors.secondaryText
                )
        }
        .frame(
            maxWidth: .infinity,
            maxHeight: .infinity
        )
    }
}

// MARK: - Error State

private extension CookbookDetailView {

    func errorState(
        _ message: String
    ) -> some View {
        VStack(
            spacing: KinSpacing.medium
        ) {
            Spacer()

            Image(
                systemName:
                    "exclamationmark.triangle.fill"
            )
            .font(
                .system(size: 42)
            )
            .foregroundStyle(
                KinColors.error
            )

            Text("Unable to Load Cookbook")
                .font(
                    KinTypography.title
                )
                .foregroundStyle(
                    KinColors.primaryText
                )

            Text(message)
                .font(
                    KinTypography.body
                )
                .foregroundStyle(
                    KinColors.secondaryText
                )
                .multilineTextAlignment(
                    .center
                )
                .padding(
                    .horizontal,
                    KinSpacing.xxLarge
                )

            Button {
                Task {
                    await loadCookbook()
                }
            } label: {
                Text("Try Again")
                    .font(
                        KinTypography.headline
                    )
                    .foregroundStyle(.white)
                    .padding(
                        .horizontal,
                        KinSpacing.large
                    )
                    .padding(
                        .vertical,
                        KinSpacing.medium
                    )
                    .background(
                        KinColors.primary
                    )
                    .clipShape(
                        RoundedRectangle(
                            cornerRadius:
                                KinRadius.medium
                        )
                    )
            }
            .buttonStyle(.plain)

            Spacer()
        }
        .frame(
            maxWidth: .infinity,
            maxHeight: .infinity
        )
    }
}

// MARK: - Load Cookbook

private extension CookbookDetailView {

    @MainActor
    func loadCookbook() async {
        isLoading = true
        errorMessage = nil

        do {
            async let cookbookRequest =
                CookbookService.fetchCookbook(
                    id: cookbookId
                )

            async let recipesRequest =
                CookbookService.fetchRecipes(
                    cookbookId: cookbookId
                )

            let (
                loadedCookbook,
                loadedRecipes
            ) = try await (
                cookbookRequest,
                recipesRequest
            )

            cookbook = loadedCookbook
            recipes = loadedRecipes
            isLoading = false
        } catch is CancellationError {
            isLoading = false
        } catch {
            errorMessage =
                error.localizedDescription

            isLoading = false
        }
    }
}

#Preview {
    NavigationStack {
        CookbookDetailView(
            cookbookId: UUID()
        )
    }
}

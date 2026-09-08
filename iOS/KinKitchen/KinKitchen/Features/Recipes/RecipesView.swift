//
//  RecipesView.swift
//  KinKitchen
//
//  Created by Greg Hudler on 8/26/26.
//

import SwiftUI

struct RecipesView: View {

    enum RecipeFilter: String, CaseIterable {
        case all = "All"
        case mine = "Mine"
        case shared = "Shared"
        case favorites = "Favorites"
    }

    @State private var selectedFilter:
        RecipeFilter = .all

    @State private var recipes: [Recipe] = []

    @State private var isLoading = true
    @State private var errorMessage: String?

    @State private var selectedRecipe:
        Recipe?

    @State private var showingAddRecipe = false


    var body: some View {

        NavigationStack {

            ZStack(
                alignment: .bottomTrailing
            ) {

                content

                // MARK: - Add Recipe

                Button {

                    showingAddRecipe = true

                } label: {

                    Image(
                        systemName: "plus"
                    )
                    .font(.title.bold())
                    .foregroundStyle(.white)
                    .frame(
                        width: 58,
                        height: 58
                    )
                    .background(
                        KinColors.primary
                    )
                    .clipShape(Circle())
                    .shadow(radius: 6)
                }
                .padding(
                    .trailing,
                    KinSpacing.large
                )
                .padding(
                    .bottom,
                    KinSpacing.large
                )
                .buttonStyle(.plain)
            }
            .background(
                KinColors.background
                    .ignoresSafeArea()
            )
            .navigationBarHidden(true)

            // MARK: - Recipe Detail

            .navigationDestination(
                item: $selectedRecipe
            ) { recipe in

                RecipeDetailPlaceholderView(
                    recipe: recipe
                )
            }

            // MARK: - Add Recipe

            .navigationDestination(
                isPresented: $showingAddRecipe
            ) {

                AddRecipeView { recipe in

                    recipes.insert(
                        recipe,
                        at: 0
                    )
                }
            }

            // MARK: - Load

            .task {

                await loadRecipes()
            }
        }
    }


    // MARK: - Content

    @ViewBuilder
    private var content: some View {

        if isLoading {

            KinLoadingView(
                message: "Loading recipes..."
            )
            .frame(
                maxWidth: .infinity,
                maxHeight: .infinity
            )

        } else if let errorMessage {

            errorState(
                message: errorMessage
            )

        } else if filteredRecipes.isEmpty {

            emptyState

        } else {

            recipeList
        }
    }


    // MARK: - Recipe List

    private var recipeList: some View {

        ScrollView {

            VStack(
                alignment: .leading,
                spacing: KinSpacing.large
            ) {

                // MARK: Header

                HStack {

                    Text("Recipes")
                        .font(
                            KinTypography.largeTitle
                        )
                        .foregroundStyle(
                            KinColors.primaryText
                        )

                    Spacer()

                    Button {

                        print("Recipe filter tapped")

                    } label: {

                        Image(
                            systemName:
                                "line.3.horizontal.decrease"
                        )
                        .font(.title2)
                        .foregroundStyle(
                            KinColors.primary
                        )
                        .frame(
                            width: 46,
                            height: 46
                        )
                        .background(
                            KinColors.surface
                        )
                        .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                }


                // MARK: - Filters

                HStack(
                    spacing: KinSpacing.small
                ) {

                    ForEach(
                        RecipeFilter.allCases,
                        id: \.self
                    ) { filter in

                        Button {

                            selectedFilter = filter

                        } label: {

                            Text(filter.rawValue)
                                .font(
                                    KinTypography.caption
                                )
                                .foregroundStyle(
                                    selectedFilter == filter
                                        ? .white
                                        : KinColors.primaryText
                                )
                                .frame(
                                    maxWidth: .infinity
                                )
                                .padding(
                                    .vertical,
                                    KinSpacing.small
                                )
                                .background(
                                    selectedFilter == filter
                                        ? KinColors.primary
                                        : KinColors.surface
                                )
                                .clipShape(
                                    Capsule()
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }


                // MARK: - Cards

                LazyVStack(
                    spacing: KinSpacing.medium
                ) {

                    ForEach(filteredRecipes) { recipe in

                        Button {

                            selectedRecipe = recipe

                        } label: {

                            recipeCard(
                                recipe
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(KinSpacing.large)
            .padding(
                .bottom,
                90
            )
        }
    }


    // MARK: - Filtered Recipes

    private var filteredRecipes:
        [Recipe] {

        switch selectedFilter {

        case .all:

            return recipes

        case .mine:

            return recipes

        case .shared:

            return []

        case .favorites:

            return []
        }
    }


    // MARK: - Recipe Card

    private func recipeCard(
        _ recipe: Recipe
    ) -> some View {

        KinCard {

            HStack(
                spacing: KinSpacing.medium
            ) {

                // MARK: - Image / Placeholder

                RoundedRectangle(
                    cornerRadius:
                        KinRadius.medium
                )
                .fill(
                    KinColors.background
                )
                .frame(
                    width: 100,
                    height: 100
                )
                .overlay {

                    if recipe.photoPath != nil {

                        Image(
                            systemName: "photo"
                        )
                        .font(.title2)
                        .foregroundStyle(
                            KinColors.primary
                        )

                    } else {

                        Image(
                            systemName:
                                placeholderIcon(
                                    for: recipe
                                )
                        )
                        .font(.title)
                        .foregroundStyle(
                            KinColors.primary
                        )
                    }
                }


                // MARK: - Recipe Info

                VStack(
                    alignment: .leading,
                    spacing: KinSpacing.small
                ) {

                    Text(recipe.name)
                        .font(
                            KinTypography.title3
                        )
                        .foregroundStyle(
                            KinColors.primaryText
                        )
                        .multilineTextAlignment(
                            .leading
                        )
                        .lineLimit(2)

                    Text(
                        recipeMetadata(
                            recipe
                        )
                    )
                    .font(
                        KinTypography.caption
                    )
                    .foregroundStyle(
                        KinColors.secondaryText
                    )
                }

                Spacer()


                // MARK: - Favorite Placeholder

                Image(
                    systemName: "star"
                )
                .font(.title2)
                .foregroundStyle(
                    KinColors.primary
                )
            }
        }
    }


    // MARK: - Metadata

    private func recipeMetadata(
        _ recipe: Recipe
    ) -> String {

        let category =
            recipe.category?
                .trimmingCharacters(
                    in: .whitespacesAndNewlines
                )

        let time =
            recipe.formattedTotalTime

        if let category,
           !category.isEmpty,
           time != "—" {

            return "\(category) • \(time)"
        }

        if let category,
           !category.isEmpty {

            return category
        }

        if time != "—" {

            return time
        }

        return "Recipe"
    }


    // MARK: - Placeholder Icon

    private func placeholderIcon(
        for recipe: Recipe
    ) -> String {

        let category =
            recipe.category?
                .lowercased() ?? ""

        if category.contains(
            "breakfast"
        ) {

            return "cup.and.saucer.fill"
        }

        if category.contains(
            "salad"
        ) ||
        category.contains(
            "vegetarian"
        ) ||
        category.contains(
            "side"
        ) {

            return "leaf.fill"
        }

        return KinIcons.recipes
    }


    // MARK: - Empty State

    private var emptyState: some View {

        VStack(
            spacing: KinSpacing.large
        ) {

            Spacer()

            KinEmptyState(
                icon: KinIcons.recipes,
                title: "No Recipes Yet",
                message:
                    "Add your first recipe to start building your collection."
            )

            Button {

                showingAddRecipe = true

            } label: {

                Label(
                    "Add Recipe",
                    systemImage: "plus"
                )
                .font(
                    KinTypography.button
                )
                .foregroundStyle(.white)
                .frame(
                    maxWidth: .infinity
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
            .padding(
                .horizontal,
                KinSpacing.xLarge
            )

            Spacer()
        }
        .padding(KinSpacing.large)
    }


    // MARK: - Error State

    private func errorState(
        message: String
    ) -> some View {

        VStack(
            spacing: KinSpacing.large
        ) {

            Spacer()

            Image(
                systemName:
                    "exclamationmark.triangle"
            )
            .font(
                .system(size: 44)
            )
            .foregroundStyle(
                KinColors.error
            )

            Text(
                "Unable to Load Recipes"
            )
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

            Button {

                Task {

                    await loadRecipes()
                }

            } label: {

                Text("Try Again")
                    .font(
                        KinTypography.button
                    )
                    .foregroundStyle(.white)
                    .frame(
                        maxWidth: .infinity
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
            .padding(
                .horizontal,
                KinSpacing.xLarge
            )

            Spacer()
        }
        .padding(KinSpacing.large)
    }


    // MARK: - Load Recipes

    @MainActor
    private func loadRecipes() async {

        isLoading = true
        errorMessage = nil

        defer {

            isLoading = false
        }

        do {

            recipes =
                try await RecipeService
                    .fetchCurrentUserRecipes()

        } catch {

            errorMessage =
                "Please check your connection and try again."

            print(
                "RECIPE LIST LOAD ERROR:",
                error.localizedDescription
            )
        }
    }
}


// MARK: - Temporary Recipe Detail

private struct RecipeDetailPlaceholderView:
    View {

    let recipe: Recipe

    var body: some View {

        VStack(
            spacing: KinSpacing.large
        ) {

            Text(recipe.name)
                .font(
                    KinTypography.largeTitle
                )

            Text(
                "Recipe Detail will be implemented in the next ticket."
            )
            .font(
                KinTypography.body
            )
            .foregroundStyle(
                KinColors.secondaryText
            )
        }
        .padding(KinSpacing.large)
        .frame(
            maxWidth: .infinity,
            maxHeight: .infinity
        )
        .background(
            KinColors.background
        )
        .navigationTitle("Recipe")
        .navigationBarTitleDisplayMode(.inline)
    }
}


#Preview {

    RecipesView()
}

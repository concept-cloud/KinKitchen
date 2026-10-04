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
    @State private var sharedRecipes: [Recipe] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var showingAddRecipe = false
    @State private var selectedRecipeId: UUID?
    @State private var recipePhotoData: [UUID: Data] = [:]
    @State private var showingFilters = false
    @State private var criteria = RecipeDiscoveryCriteria()

    
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
                isPresented: Binding(
                    get: { selectedRecipeId != nil },
                    set: { if !$0 { selectedRecipeId = nil } }
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
            // MARK: - Add Recipe
            .navigationDestination(
                isPresented: $showingAddRecipe
            ) {
                AddRecipeView(
                    onRecipeCreated: { recipe in
                        recipes.insert(
                            recipe,
                            at: 0
                        )
                    },
                    onCancel: {
                        showingAddRecipe = false
                    }
                )
            }
            // MARK: - Filters
            .sheet(
                isPresented: $showingFilters
            ) {
                RecipeFilterSheet(
                    criteria: $criteria
                )
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
        } else if recipes.isEmpty &&
                    sharedRecipes.isEmpty {
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
                        showingFilters = true
                    } label: {
                        Image(
                            systemName:
                                "line.3.horizontal.decrease"
                        )
                        .font(.title2)
                        .foregroundStyle(
                            criteria.hasActiveFilters
                                ? .white
                                : KinColors.primary
                        )
                        .frame(
                            width: 46,
                            height: 46
                        )
                        .background(
                            criteria.hasActiveFilters
                                ? KinColors.primary
                                : KinColors.surface
                        )
                        .clipShape(Circle())
                        .overlay(
                            alignment: .topTrailing
                        ) {
                            if criteria.hasActiveFilters {
                                Text(
                                    "\(criteria.activeFilterCount)"
                                )
                                .font(
                                    .system(
                                        size: 11,
                                        weight: .bold
                                    )
                                )
                                .foregroundStyle(
                                    KinColors.primary
                                )
                                .frame(
                                    width: 18,
                                    height: 18
                                )
                                .background(.white)
                                .clipShape(Circle())
                                .offset(x: 2, y: -2)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Filters")
                    .accessibilityValue(
                        criteria.hasActiveFilters
                            ? "\(criteria.activeFilterCount) active"
                            : "None active"
                    )
                }
                // MARK: - Search
                KinSearchBar(
                    text: $criteria.searchText,
                    placeholder: "Search recipes"
                )
                // MARK: - Active Filters
                if criteria.hasActiveFilters {
                    ScrollView(
                        .horizontal,
                        showsIndicators: false
                    ) {
                        HStack(
                            spacing: KinSpacing.small
                        ) {
                            ForEach(
                                criteria.sortedCategories
                            ) { category in
                                activeFilterChip(
                                    title: category.rawValue
                                ) {
                                    criteria.categories.remove(
                                        category
                                    )
                                }
                            }
                        }
                    }
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
                if filteredRecipes.isEmpty {
                    filteredEmptyState
                } else if displayedRecipes.isEmpty {
                    noResultsState
                } else {
                    LazyVStack(
                        spacing: KinSpacing.medium
                    ) {
                        ForEach(displayedRecipes) { recipe in
                            Button {
                                selectedRecipeId = recipe.id
                            } label: {
                                recipeCard(
                                    recipe
                                )
                            }
                            .buttonStyle(.plain)
                        }
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
    // MARK: - Filtered Empty State
    private var filteredEmptyState: some View {
        VStack(
            spacing: KinSpacing.medium
        ) {
            Image(
                systemName: "tray"
            )
            .font(
                .system(size: 36)
            )
            .foregroundStyle(
                KinColors.secondaryText
            )
            Text(
                "No \(selectedFilter.rawValue) Recipes"
            )
            .font(
                KinTypography.title3
            )
            .foregroundStyle(
                KinColors.primaryText
            )
            Text(
                selectedFilter == .shared
                ? "Recipes shared with you will appear here."
                : "This feature is coming in Milestone B1."
            )
            .font(
                KinTypography.body
            )
            .foregroundStyle(
                KinColors.secondaryText
            )
            .multilineTextAlignment(
                .center
            )
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, KinSpacing.xLarge)
    }
    // MARK: - No Results State
    private var noResultsState: some View {
        VStack(
            spacing: KinSpacing.medium
        ) {
            Image(
                systemName: "magnifyingglass"
            )
            .font(
                .system(size: 36)
            )
            .foregroundStyle(
                KinColors.secondaryText
            )
            Text(
                "No Matching Recipes"
            )
            .font(
                KinTypography.title3
            )
            .foregroundStyle(
                KinColors.primaryText
            )
            Text(
                noResultsMessage
            )
            .font(
                KinTypography.body
            )
            .foregroundStyle(
                KinColors.secondaryText
            )
            .multilineTextAlignment(
                .center
            )
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, KinSpacing.xLarge)
    }

    private var noResultsMessage: String {
        if criteria.isSearching,
           criteria.hasActiveFilters {
            return "No recipes match \"\(criteria.trimmedSearchText)\" with the selected filters."
        }
        if criteria.isSearching {
            return "No recipes match \"\(criteria.trimmedSearchText)\"."
        }
        return "No recipes match the selected filters."
    }

    // MARK: - Active Filter Chip
    private func activeFilterChip(
        title: String,
        onRemove: @escaping () -> Void
    ) -> some View {
        Button(action: onRemove) {
            HStack(
                spacing: KinSpacing.xSmall
            ) {
                Text(title)
                    .font(
                        KinTypography.caption
                    )
                Image(
                    systemName: "xmark"
                )
                .font(
                    .system(
                        size: 10,
                        weight: .bold
                    )
                )
            }
            .foregroundStyle(
                KinColors.primary
            )
            .padding(
                .horizontal,
                KinSpacing.medium
            )
            .padding(
                .vertical,
                KinSpacing.xSmall
            )
            .background(
                KinColors.primary
                    .opacity(0.12)
            )
            .clipShape(
                Capsule()
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(
            "Remove \(title) filter"
        )
    }

    // MARK: - Displayed Recipes

    /// The selected tab's recipes narrowed by search.
    private var displayedRecipes: [Recipe] {
        criteria.apply(
            to: filteredRecipes
        )
    }

    // MARK: - Filtered Recipes

    private var filteredRecipes: [Recipe] {
        switch selectedFilter {
        case .all:
            return combinedRecipes

        case .mine:
            return recipes

        case .shared:
            return sharedRecipes

        case .favorites:
            return []
        }
    }

    // MARK: - Combined Recipes

    private var combinedRecipes: [Recipe] {
        var seen: Set<UUID> = []

        return (recipes + sharedRecipes)
            .filter {
                seen.insert($0.id).inserted
            }
            .sorted {
                $0.updatedAt > $1.updatedAt
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
                ZStack {
                    RoundedRectangle(
                        cornerRadius: KinRadius.medium
                    )
                    .fill(KinColors.background)
                    if let data = recipePhotoData[recipe.id],
                       let image = UIImage(data: data) {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 100, height: 100)
                            .clipped()
                            .clipShape(
                                RoundedRectangle(
                                    cornerRadius: KinRadius.medium
                                )
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
                .frame(width: 100, height: 100)
                .task(id: recipe.photoPath) {
                    await loadRecipePhoto(
                        for: recipe
                    )
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
            async let ownedRecipeRequest =
                RecipeService
                    .fetchCurrentUserRecipes()

            async let receivedShareRequest =
                RecipeSharingService
                    .fetchReceivedShares()

            let ownedRecipes =
                try await ownedRecipeRequest

            let receivedShares =
                try await receivedShareRequest

            var receivedRecipes: [Recipe] = []

            for share in receivedShares {
                do {
                    let recipe =
                        try await RecipeService
                            .fetchRecipe(
                                id: share.recipeId
                            )

                    receivedRecipes.append(
                        recipe
                    )
                } catch {
                    print(
                        "SHARED RECIPE LOAD ERROR:",
                        error.localizedDescription
                    )
                }
            }

            recipes = ownedRecipes

            var seen: Set<UUID> = []

            sharedRecipes =
                receivedRecipes.filter {
                    seen.insert($0.id).inserted
                }
        } catch {
            errorMessage =
                "Please check your connection and try again."

            print(
                "RECIPE LIST LOAD ERROR:",
                error.localizedDescription
            )
        }
    }
    
    
    @MainActor
    private func loadRecipePhoto(
        for recipe: Recipe
    ) async {
        guard recipePhotoData[recipe.id] == nil else {
            return
        }
        guard let path = recipe.photoPath,
              !path.isEmpty else {
            return
        }
        do {
            recipePhotoData[recipe.id] =
                try await RecipeService.fetchRecipePhoto(
                    path: path
                )
        } catch {
            print(
                "RECIPE CARD PHOTO LOAD ERROR:",
                error.localizedDescription
            )
        }
    }
}
#Preview {
    RecipesView()
}

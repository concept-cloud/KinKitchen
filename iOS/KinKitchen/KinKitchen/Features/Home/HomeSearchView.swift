//
//  HomeSearchView.swift
//  KinKitchen
//
//  Created by Greg Hudler on 10/13/26.
//

import SwiftUI

/// Searches everything the signed-in user can open: their recipes and
/// recipes shared with them, their cookbooks, and their gatherings.
/// Everything loads through Supabase, so RLS decides what's included.
struct HomeSearchView: View {

    @State private var query = ""
    @FocusState private var isFieldFocused: Bool

    @State private var recipes: [Recipe] = []
    @State private var cookbooks: [Cookbook] = []
    @State private var gatherings: [GatheringListItem] = []
    @State private var isLoading = true

    @State private var selectedRecipeId: UUID?
    @State private var selectedCookbookId: UUID?
    @State private var selectedGatheringId: UUID?

    var body: some View {

        VStack(
            spacing: 0
        ) {

            KinSearchBar(
                text: $query,
                placeholder: HomeSearch.placeholder
            )
            .focused($isFieldFocused)
            .submitLabel(.search)
            .padding(.horizontal, KinSpacing.large)
            .padding(.vertical, KinSpacing.small)

            results
        }
        .background(KinColors.background)
        .navigationTitle("Search")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            isFieldFocused = true
            await load()
        }
        .navigationDestination(item: $selectedRecipeId) { id in
            RecipeDetailView(recipeId: id)
        }
        .navigationDestination(item: $selectedCookbookId) { id in
            CookbookDetailView(cookbookId: id)
        }
        .navigationDestination(item: $selectedGatheringId) { id in
            GatheringDetailView(gatheringId: id)
        }
    }


    // MARK: - Results

    @ViewBuilder
    private var results: some View {

        let trimmed =
            query.trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        let matchedRecipes =
            HomeSearch.filter(recipes, query: trimmed) {
                [$0.name, $0.category]
            }

        let matchedCookbooks =
            HomeSearch.filter(cookbooks, query: trimmed) {
                [$0.name, $0.description]
            }

        let matchedGatherings =
            HomeSearch.filter(gatherings, query: trimmed) {
                [$0.gathering.name, $0.gathering.location, $0.gathering.theme]
            }

        if trimmed.isEmpty {

            hint(
                icon: KinIcons.search,
                text: "Search your recipes, cookbooks, and events."
            )

        } else if isLoading {

            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)

        } else if matchedRecipes.isEmpty
                    && matchedCookbooks.isEmpty
                    && matchedGatherings.isEmpty {

            hint(
                icon: "magnifyingglass",
                text: "Nothing matches “\(trimmed)”."
            )

        } else {

            List {

                if !matchedRecipes.isEmpty {

                    Section("Recipes") {

                        ForEach(matchedRecipes) { recipe in

                            row(
                                title: recipe.name,
                                detail: recipe.category,
                                icon: KinIcons.recipes
                            ) {
                                selectedRecipeId = recipe.id
                            }
                        }
                    }
                }

                if !matchedCookbooks.isEmpty {

                    Section("Cookbooks") {

                        ForEach(matchedCookbooks) { cookbook in

                            row(
                                title: cookbook.name,
                                detail: cookbook.description,
                                icon: KinIcons.cookbooks
                            ) {
                                selectedCookbookId = cookbook.id
                            }
                        }
                    }
                }

                if !matchedGatherings.isEmpty {

                    Section("Events") {

                        ForEach(matchedGatherings) { item in

                            row(
                                title: item.gathering.name,
                                detail: HomeView.eventDateText(
                                    item.gathering.startsAt
                                ),
                                icon: KinIcons.gatherings
                            ) {
                                selectedGatheringId = item.gathering.id
                            }
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .scrollDismissesKeyboard(.immediately)
        }
    }


    private func row(
        title: String,
        detail: String?,
        icon: String,
        action: @escaping () -> Void
    ) -> some View {

        Button(action: action) {

            HStack(
                spacing: KinSpacing.medium
            ) {

                Image(systemName: icon)
                    .foregroundStyle(KinColors.primary)
                    .frame(width: 28)
                    .accessibilityHidden(true)

                VStack(
                    alignment: .leading,
                    spacing: KinSpacing.xxSmall
                ) {

                    Text(title)
                        .font(KinTypography.headline)
                        .foregroundStyle(KinColors.primaryText)

                    if let detail,
                       !detail.isEmpty {

                        Text(detail)
                            .font(KinTypography.footnote)
                            .foregroundStyle(KinColors.secondaryText)
                            .lineLimit(1)
                    }
                }

                Spacer()

                Image(systemName: KinIcons.forward)
                    .font(.footnote)
                    .foregroundStyle(KinColors.secondaryText)
                    .accessibilityHidden(true)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .listRowBackground(KinColors.surface)
    }


    private func hint(
        icon: String,
        text: String
    ) -> some View {

        VStack(
            spacing: KinSpacing.medium
        ) {

            Image(systemName: icon)
                .font(.system(size: 32))
                .foregroundStyle(KinColors.secondaryText)
                .accessibilityHidden(true)

            Text(text)
                .font(KinTypography.body)
                .foregroundStyle(KinColors.secondaryText)
                .multilineTextAlignment(.center)
        }
        .padding(KinSpacing.xLarge)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }


    // MARK: - Load

    @MainActor
    private func load() async {

        defer {
            isLoading = false
        }

        // Each source loads on its own, so one failure doesn't hide
        // the others.
        var all: [Recipe] = []

        if let own = try? await RecipeService.fetchCurrentUserRecipes() {
            all += own
        }

        if
            let shares = try? await RecipeSharingService.fetchReceivedShares(),
            let shared = try? await RecipeService.fetchRecipes(
                ids: shares.map(\.recipeId)
            )
        {
            all += shared.filter { $0.archivedAt == nil }
        }

        recipes =
            HomeSearch.uniqueById(all)
                .sorted {
                    $0.name.localizedCaseInsensitiveCompare($1.name)
                        == .orderedAscending
                }

        cookbooks =
            (try? await CookbookService.fetchCurrentUserCookbooks()) ?? []

        let upcoming =
            (try? await GatheringService.fetchUpcomingGatheringItems()) ?? []

        let past =
            (try? await GatheringService.fetchPastGatheringItems()) ?? []

        gatherings = HomeSearch.uniqueById(upcoming + past)
    }
}


// MARK: - Matching

/// Search rules shared by Home and its tests.
nonisolated enum HomeSearch {

    static let placeholder = "Search recipes, cookbooks, or events"

    /// Items where any field contains every word of the query,
    /// ignoring case and accents. An empty query matches nothing.
    static func filter<Item>(
        _ items: [Item],
        query: String,
        fields: (Item) -> [String?]
    ) -> [Item] {

        let words =
            query
                .split(whereSeparator: \.isWhitespace)
                .map(String.init)

        guard !words.isEmpty else {
            return []
        }

        return items.filter { item in

            let text =
                fields(item)
                    .compactMap { $0 }
                    .joined(separator: " ")

            return words.allSatisfy {
                text.range(
                    of: $0,
                    options: [.caseInsensitive, .diacriticInsensitive]
                ) != nil
            }
        }
    }

    static func uniqueById<Item: Identifiable>(
        _ items: [Item]
    ) -> [Item] {

        var seen = Set<Item.ID>()

        return items.filter {
            seen.insert($0.id).inserted
        }
    }
}

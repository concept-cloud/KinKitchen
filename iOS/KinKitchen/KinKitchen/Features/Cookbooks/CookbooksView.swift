//
//  CookbooksView.swift
//  KinKitchen
//
//  Created by Greg Hudler on 8/26/26.
//

import SwiftUI
import Supabase

struct CookbooksView: View {

    @State private var cookbooks: [Cookbook] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var navigationPath = NavigationPath()
    @State private var isShowingCreateCookbook = false
    @State private var selectedCookbookId: UUID?
    @State private var recipeCounts: [UUID: Int] = [:]
    @State private var searchText = ""

    /// The bookcase look, once there are cookbooks to put on it.
    private var showsShelf: Bool {
        !isLoading && errorMessage == nil && !cookbooks.isEmpty
    }

    private var shownCookbooks: [Cookbook] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else {
            return cookbooks
        }
        return cookbooks.filter {
            $0.name.localizedCaseInsensitiveContains(query)
        }
    }

    var body: some View {
        NavigationStack(path: $navigationPath) {
            ZStack {
                if showsShelf {
                    KinBookcaseWall()
                        .ignoresSafeArea()
                        .transition(.opacity)
                } else {
                    KinColors.background
                        .ignoresSafeArea()
                }

                VStack(spacing: 0) {
                    header
                    content
                }
            }
            .animation(.easeInOut(duration: 0.3), value: showsShelf)
            .navigationBarHidden(true)
            .navigationDestination(
                for: UUID.self
            ) { cookbookId in
                CookbookDetailView(
                    cookbookId: cookbookId
                )
                .onDisappear {
                    Task {
                        await loadCookbooks()
                    }
                }
            }
            .task {
                await loadCookbooks()
            }
            .refreshable {
                await loadCookbooks()
            }
            .sheet(
                isPresented: $isShowingCreateCookbook
            ) {
                CreateCookbookView { cookbook in
                    cookbooks.insert(
                        cookbook,
                        at: 0
                    )
                }
            }
        }
    }
}

// MARK: - Header

private extension CookbooksView {

    var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: KinSpacing.xxSmall) {
                Text("My Cookbooks")
                    .font(KinTypography.largeTitle)
                    .foregroundStyle(showsShelf ? .white : KinColors.primaryText)
                    .kinTextOnPhoto()

                if !cookbooks.isEmpty {
                    Text(cookbooks.count == 1 ? "1 cookbook on your shelf" : "\(cookbooks.count) cookbooks on your shelf")
                        .font(KinTypography.footnote)
                        .foregroundStyle(showsShelf ? .white.opacity(0.8) : KinColors.secondaryText)
                }
            }

            Spacer()

            Button {
                isShowingCreateCookbook = true
            } label: {
                Image(systemName: "plus")
                    .font(
                        .system(
                            size: 22,
                            weight: .bold
                        )
                    )
                    .foregroundStyle(.white)
                    .frame(
                        width: 52,
                        height: 52
                    )
                    .background(KinColors.primary)
                    .clipShape(Circle())
                    .kinFloatingShadow()
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Create Cookbook")
        }

        .padding(
            .horizontal,
            KinSpacing.large
        )
        .padding(
            .top,
            KinSpacing.large
        )
        .padding(
            .bottom,
            KinSpacing.medium
        )
    }
}

// MARK: - Search

private extension CookbooksView {

    /// Smoked glass over the wood, like the mockup.
    var searchBar: some View {

        HStack(spacing: KinSpacing.small) {

            Image(systemName: KinIcons.search)
                .foregroundStyle(.white.opacity(0.85))

            TextField(
                "Search cookbooks",
                text: $searchText,
                prompt: Text("Search cookbooks...").foregroundStyle(.white.opacity(0.65))
            )
            .font(KinTypography.callout)
            .foregroundStyle(.white)
            .tint(.white)
            .submitLabel(.search)

            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.white.opacity(0.7))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Clear search")
            }
        }
        .padding(.horizontal, KinSpacing.medium)
        .padding(.vertical, KinSpacing.medium)
        .background(.black.opacity(0.28), in: Capsule())
        .overlay {
            Capsule().strokeBorder(.white.opacity(0.12))
        }
        .padding(.horizontal, KinSpacing.large)
        .padding(.bottom, KinSpacing.medium)
    }
}

// MARK: - Content

private extension CookbooksView {

    @ViewBuilder
    var content: some View {
        if showsShelf {
            searchBar
        }

        if isLoading {
            loadingState
        } else if let errorMessage {
            errorState(errorMessage)
        } else if cookbooks.isEmpty {
            emptyState
        } else {
            cookbookList
        }
    }
}

// MARK: - Cookbook List

private extension CookbooksView {

    /// A bookshelf: two books to a shelf, scrolling up and down, with
    /// a "New Cookbook" book after the last one.
    var cookbookList: some View {
        ScrollView {
            LazyVStack(
                spacing: KinSpacing.xxLarge
            ) {
                if shownCookbooks.isEmpty {
                    Text("No cookbooks match \"\(searchText)\".")
                        .font(KinTypography.callout)
                        .foregroundStyle(.white.opacity(0.85))
                        .padding(.top, KinSpacing.xLarge)
                }

                ForEach(
                    Array(
                        CookbookShelfLayout.shelves(
                            for: shownCookbooks.map(\.id),
                            includesAdd: searchText.isEmpty
                        ).enumerated()
                    ),
                    id: \.offset
                ) { _, shelf in
                    shelfRow(shelf)
                }
            }
            .padding(
                .top,
                KinSpacing.small
            )
            .padding(
                .bottom,
                KinSpacing.xxLarge
            )
        }
    }

    static var bookHeight: CGFloat { 180 }

    func shelfRow(
        _ shelf: [CookbookShelfLayout.Slot]
    ) -> some View {

        VStack(spacing: 0) {

            HStack(
                alignment: .bottom,
                spacing: KinSpacing.large
            ) {
                ForEach(shelf, id: \.self) { slot in
                    shelfSlot(slot)
                        .frame(maxWidth: .infinity)
                }

                // Keeps a lone book the same width.
                if shelf.count < CookbookShelfLayout.booksPerShelf {
                    Color.clear
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, KinSpacing.xLarge)

            // Books stand on the plank's top edge, which runs the
            // full width like a real bookcase. The shade below hangs
            // into the space before the next shelf.
            KinWoodShelf()
                .padding(.top, -6)
                .padding(.bottom, -28)
        }
    }

    @ViewBuilder
    func shelfSlot(
        _ slot: CookbookShelfLayout.Slot
    ) -> some View {

        switch slot {

        case .cookbook(let id):
            if let cookbook = cookbooks.first(where: { $0.id == id }) {
                KinShelfBookButton {
                    navigationPath.append(cookbook.id)
                } label: {
                    KinCookbookCoverCard(
                        cookbook: cookbook,
                        recipeCount: recipeCounts[cookbook.id] ?? 0,
                        badge: badge(for: cookbook),
                        height: Self.bookHeight,
                        titleFont: KinTypography.title3,
                        isShelfBook: true
                    )
                }
                .accessibilityHint("Opens the cookbook")
            }

        case .add:
            Button {
                isShowingCreateCookbook = true
            } label: {
                KinAddCookbookBook(height: Self.bookHeight)
            }
            .buttonStyle(.kinPressable)
        }
    }


    /// Owned cookbooks say Private; anything else (cookbook sharing
    /// isn't built yet) would say Shared.
    func badge(
        for cookbook: Cookbook
    ) -> CookbookBadge {

        let userId =
            SupabaseManager.client.auth.currentUser?.id

        return cookbook.ownerId == userId
            ? .mine
            : .shared(by: nil)
    }
}

// MARK: - Loading State

private extension CookbooksView {

    var loadingState: some View {
        KinLoadingView(message: "Loading cookbooks...")
    }
}

// MARK: - Empty State

private extension CookbooksView {

    var emptyState: some View {
        KinEmptyState(
            icon: KinIcons.cookbooks,
            title: "No Cookbooks Yet",
            message: "Gather your family's favorite recipes into a cookbook, organized your way.",
            actionTitle: "Create a Cookbook"
        ) {
            isShowingCreateCookbook = true
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Error State

private extension CookbooksView {

    func errorState(
        _ message: String
    ) -> some View {
        KinErrorView(message: message) {
            Task {
                await loadCookbooks()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Load Cookbooks

private extension CookbooksView {

    @MainActor
    func loadCookbooks() async {
        // Spinner only when there's nothing to show yet; otherwise
        // refresh quietly behind the current list.
        isLoading = cookbooks.isEmpty
        errorMessage = nil

        do {
            cookbooks =
                try await CookbookService
                    .fetchCurrentUserCookbooks()

            isLoading = false

            // Counts are extra; the library still shows without them.
            recipeCounts =
                (try? await CookbookService.fetchRecipeCounts(
                    cookbookIds: cookbooks.map(\.id)
                )) ?? recipeCounts
        } catch is CancellationError {
            isLoading = false
        } catch {
            // A failed quiet refresh keeps the list that's showing.
            if cookbooks.isEmpty {
                errorMessage =
                    error.localizedDescription
            }

            isLoading = false
        }
    }
}

#Preview {
    CookbooksView()
}

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

    var body: some View {
        NavigationStack(path: $navigationPath) {
            ZStack {
                KinColors.background
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    header
                    content
                }
            }
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
            Text("My Cookbooks")
                .font(KinTypography.largeTitle)
                .foregroundStyle(KinColors.primaryText)

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

// MARK: - Content

private extension CookbooksView {

    @ViewBuilder
    var content: some View {
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

    var cookbookList: some View {
        ScrollView {
            LazyVStack(
                spacing: KinSpacing.large
            ) {
                ForEach(cookbooks) { cookbook in
                    cookbookCard(cookbook)
                }
            }
            .padding(
                .horizontal,
                KinSpacing.large
            )
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

    func cookbookCard(
        _ cookbook: Cookbook
    ) -> some View {

        Button {
            navigationPath.append(cookbook.id)
        } label: {
            KinCookbookCoverCard(
                cookbook: cookbook,
                recipeCount: recipeCounts[cookbook.id] ?? 0,
                badge: badge(for: cookbook)
            )
        }
        .buttonStyle(.plain)
        .accessibilityHint("Opens the cookbook")
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
        VStack(
            spacing: KinSpacing.medium
        ) {
            ProgressView()
                .tint(KinColors.primary)

            Text("Loading cookbooks...")
                .font(KinTypography.body)
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

// MARK: - Empty State

private extension CookbooksView {

    var emptyState: some View {
        VStack(
            spacing: KinSpacing.medium
        ) {
            Spacer()

            ZStack {
                Circle()
                    .fill(
                        KinColors.primary.opacity(0.12)
                    )
                    .frame(
                        width: 96,
                        height: 96
                    )

                Image(
                    systemName: KinIcons.cookbooks
                )
                .font(
                    .system(
                        size: 42
                    )
                )
                .foregroundStyle(
                    KinColors.primary
                )
            }

            Text("No Cookbooks Yet")
                .font(KinTypography.title)
                .foregroundStyle(
                    KinColors.primaryText
                )

            Text(
                "Gather your family's favorite recipes into a cookbook, organized your way."
            )
            .font(KinTypography.body)
            .foregroundStyle(
                KinColors.secondaryText
            )
            .multilineTextAlignment(.center)
            .padding(
                .horizontal,
                KinSpacing.xxLarge
            )

            Button {
                isShowingCreateCookbook = true
            } label: {
                Label(
                    "Create a Cookbook",
                    systemImage: KinIcons.add
                )
                .font(KinTypography.headline)
                .foregroundStyle(.white)
                .padding(
                    .horizontal,
                    KinSpacing.large
                )
                .padding(
                    .vertical,
                    KinSpacing.medium
                )
                .background(KinColors.primary)
                .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            .padding(.top, KinSpacing.small)

            Spacer()
        }
        .frame(
            maxWidth: .infinity,
            maxHeight: .infinity
        )
    }
}

// MARK: - Error State

private extension CookbooksView {

    func errorState(
        _ message: String
    ) -> some View {
        VStack(
            spacing: KinSpacing.medium
        ) {
            Spacer()

            Image(
                systemName: "exclamationmark.triangle.fill"
            )
            .font(
                .system(
                    size: 42
                )
            )
            .foregroundStyle(
                KinColors.error
            )

            Text("Unable to Load Cookbooks")
                .font(KinTypography.title)
                .foregroundStyle(
                    KinColors.primaryText
                )

            Text(message)
                .font(KinTypography.body)
                .foregroundStyle(
                    KinColors.secondaryText
                )
                .multilineTextAlignment(.center)
                .padding(
                    .horizontal,
                    KinSpacing.xxLarge
                )

            Button {
                Task {
                    await loadCookbooks()
                }
            } label: {
                Text("Try Again")
                    .font(KinTypography.headline)
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

// MARK: - Load Cookbooks

private extension CookbooksView {

    @MainActor
    func loadCookbooks() async {
        isLoading = true
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
            errorMessage =
                error.localizedDescription

            isLoading = false
        }
    }
}

#Preview {
    CookbooksView()
}

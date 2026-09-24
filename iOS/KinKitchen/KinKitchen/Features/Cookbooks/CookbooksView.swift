//
//  CookbooksView.swift
//  KinKitchen
//
//  Created by Greg Hudler on 8/26/26.
//

import SwiftUI

struct CookbooksView: View {

    @State private var cookbooks: [Cookbook] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var navigationPath = NavigationPath()
    @State private var isShowingCreateCookbook = false

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
            Text("Cookbooks")
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
                spacing: KinSpacing.medium
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
            HStack(
                spacing: KinSpacing.medium
            ) {
                cookbookCover(cookbook)

                VStack(
                    alignment: .leading,
                    spacing: KinSpacing.small
                ) {
                    Text(cookbook.name)
                        .font(KinTypography.headline)
                        .foregroundStyle(
                            KinColors.primaryText
                        )
                        .multilineTextAlignment(.leading)

                    if let description =
                        cookbook.description,
                       !description.isEmpty {

                        Text(description)
                            .font(KinTypography.body)
                            .foregroundStyle(
                                KinColors.secondaryText
                            )
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                    }
                }

                Spacer()

                Image(
                    systemName: "chevron.right"
                )
                .font(
                    .system(
                        size: 16,
                        weight: .semibold
                    )
                )
                .foregroundStyle(
                    KinColors.secondaryText
                )
            }
            .padding(KinSpacing.medium)
            .frame(
                maxWidth: .infinity,
                alignment: .leading
            )
            .background(KinColors.surface)
            .clipShape(
                RoundedRectangle(
                    cornerRadius: KinRadius.medium
                )
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(
            "Open \(cookbook.name)"
        )
    }
}

// MARK: - Cookbook Cover

private extension CookbooksView {

    @ViewBuilder
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
                    size: 28,
                    weight: .semibold
                )
            )
            .foregroundStyle(
                KinColors.primary
            )
        }
        .frame(
            width: 76,
            height: 76
        )
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
                "Create a cookbook to organize your favorite recipes."
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

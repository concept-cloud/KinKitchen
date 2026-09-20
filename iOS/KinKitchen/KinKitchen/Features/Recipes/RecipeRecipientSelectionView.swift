//
//  RecipeRecipientSelectionView.swift
//  KinKitchen
//
//  Created by Greg Hudler on 9/20/26.
//

import SwiftUI

// MARK: - Recipe Recipient Selection View

struct RecipeRecipientSelectionView: View {
    @Environment(\.dismiss) private var dismiss

    let onSelect: (ProfileSearchResult) -> Void

    @State private var searchText = ""
    @State private var results: [ProfileSearchResult] = []
    @State private var selectedUser: ProfileSearchResult?
    @State private var isSearching = false
    @State private var searchCompleted = false
    @State private var errorMessage: String?

    var body: some View {
        ZStack {
            KinColors.background
                .ignoresSafeArea()

            VStack(
                spacing: 0
            ) {
                navigationHeader

                ScrollView {
                    VStack(
                        alignment: .leading,
                        spacing: KinSpacing.large
                    ) {
                        searchField
                        searchContent

                        if selectedUser != nil {
                            selectRecipientButton
                        }
                    }
                    .padding(
                        .horizontal,
                        KinSpacing.large
                    )
                    .padding(
                        .bottom,
                        KinSpacing.xxxLarge
                    )
                }
            }
        }
        .navigationBarHidden(true)
        .task(
            id: searchText
        ) {
            await searchUsers()
        }
    }
}

// MARK: - Navigation

private extension RecipeRecipientSelectionView {
    var navigationHeader: some View {
        ZStack {
            Text("Share Recipe")
                .font(
                    KinTypography.navigationTitle
                )
                .foregroundStyle(
                    KinColors.primaryText
                )

            HStack {
                Button {
                    dismiss()
                } label: {
                    Image(
                        systemName:
                            "chevron.left"
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
                        width: 48,
                        height: 48
                    )
                    .background(
                        KinColors.surface
                    )
                    .clipShape(
                        Circle()
                    )
                }
                .buttonStyle(.plain)

                Spacer()
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
            KinSpacing.large
        )
    }
}

// MARK: - Search Field

private extension RecipeRecipientSelectionView {
    var searchField: some View {
        HStack(
            spacing: KinSpacing.small
        ) {
            Image(
                systemName:
                    "magnifyingglass"
            )
            .foregroundStyle(
                KinColors.secondaryText
            )

            TextField(
                "Search by name or username",
                text: $searchText
            )
            .font(
                KinTypography.body
            )
            .foregroundStyle(
                KinColors.primaryText
            )
            .textInputAutocapitalization(
                .never
            )
            .autocorrectionDisabled()
        }
        .padding(
            KinSpacing.medium
        )
        .background(
            KinColors.surface
        )
        .clipShape(
            RoundedRectangle(
                cornerRadius:
                    KinRadius.medium
            )
        )
    }
}

// MARK: - Search Content

private extension RecipeRecipientSelectionView {
    @ViewBuilder
    var searchContent: some View {
        if searchText
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )
            .isEmpty {
            searchPrompt
        } else if isSearching {
            ProgressView()
                .tint(
                    KinColors.primary
                )
                .frame(
                    maxWidth: .infinity
                )
                .padding(
                    .vertical,
                    KinSpacing.xLarge
                )
        } else if let errorMessage {
            errorState(
                message: errorMessage
            )
        } else if searchCompleted &&
                    results.isEmpty {
            noResultsState
        } else {
            VStack(
                spacing: KinSpacing.medium
            ) {
                ForEach(
                    results
                ) { user in
                    userRow(
                        user
                    )
                }
            }
        }
    }

    var searchPrompt: some View {
        VStack(
            spacing: KinSpacing.medium
        ) {
            Image(
                systemName:
                    "person.2.fill"
            )
            .font(
                .system(
                    size: 32
                )
            )
            .foregroundStyle(
                KinColors.primary
            )

            Text(
                "Choose a Recipient"
            )
            .font(
                KinTypography.sectionTitle
            )
            .foregroundStyle(
                KinColors.primaryText
            )

            Text(
                "Search for a Kin Kitchen user by name or username."
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
        .frame(
            maxWidth: .infinity
        )
        .padding(
            .vertical,
            KinSpacing.xxxLarge
        )
    }

    var noResultsState: some View {
        VStack(
            spacing: KinSpacing.medium
        ) {
            Image(
                systemName:
                    "person.crop.circle.badge.questionmark"
            )
            .font(
                .system(
                    size: 32
                )
            )
            .foregroundStyle(
                KinColors.secondaryText
            )

            Text(
                "No Users Found"
            )
            .font(
                KinTypography.headline
            )
            .foregroundStyle(
                KinColors.primaryText
            )

            Text(
                "Try searching with a different name or username."
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
        .frame(
            maxWidth: .infinity
        )
        .padding(
            .vertical,
            KinSpacing.xLarge
        )
    }

    func errorState(
        message: String
    ) -> some View {
        VStack(
            spacing: KinSpacing.medium
        ) {
            Image(
                systemName:
                    "exclamationmark.triangle"
            )
            .font(
                .system(
                    size: 30
                )
            )
            .foregroundStyle(
                KinColors.error
            )

            Text(
                message
            )
            .font(
                KinTypography.body
            )
            .foregroundStyle(
                KinColors.primaryText
            )
            .multilineTextAlignment(
                .center
            )
        }
        .frame(
            maxWidth: .infinity
        )
        .padding(
            .vertical,
            KinSpacing.xLarge
        )
    }
}

// MARK: - User Row

private extension RecipeRecipientSelectionView {
    func userRow(
        _ user: ProfileSearchResult
    ) -> some View {
        Button {
            selectedUser = user
        } label: {
            HStack(
                spacing: KinSpacing.medium
            ) {
                ZStack {
                    Circle()
                        .fill(
                            KinColors.primary
                                .opacity(0.10)
                        )
                        .frame(
                            width: 48,
                            height: 48
                        )

                    Image(
                        systemName:
                            "person.fill"
                    )
                    .foregroundStyle(
                        KinColors.primary
                    )
                }

                VStack(
                    alignment: .leading,
                    spacing: KinSpacing.xSmall
                ) {
                    Text(
                        displayName(
                            for: user
                        )
                    )
                    .font(
                        KinTypography.headline
                    )
                    .foregroundStyle(
                        KinColors.primaryText
                    )

                    if let username =
                        cleaned(
                            user.username
                        ) {
                        Text(
                            "@\(username)"
                        )
                        .font(
                            KinTypography.footnote
                        )
                        .foregroundStyle(
                            KinColors.secondaryText
                        )
                    }
                }

                Spacer()

                Image(
                    systemName:
                        selectedUser?.id ==
                        user.id
                            ? "checkmark.circle.fill"
                            : "circle"
                )
                .font(
                    .system(
                        size: 24
                    )
                )
                .foregroundStyle(
                    selectedUser?.id ==
                    user.id
                        ? KinColors.primary
                        : KinColors.secondaryText
                )
            }
            .padding(
                KinSpacing.large
            )
            .background(
                KinColors.surface
            )
            .clipShape(
                RoundedRectangle(
                    cornerRadius:
                        KinRadius.large
                )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Select Recipient

private extension RecipeRecipientSelectionView {
    var selectRecipientButton: some View {
        Button {
            guard let selectedUser else {
                return
            }

            onSelect(
                selectedUser
            )

            dismiss()
        } label: {
            Text(
                "Select Recipient"
            )
            .font(
                KinTypography.headline
            )
            .foregroundStyle(
                Color.white
            )
            .frame(
                maxWidth: .infinity
            )
            .padding(
                .vertical,
                KinSpacing.large
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
    }
}

// MARK: - Search

private extension RecipeRecipientSelectionView {
    @MainActor
    func searchUsers() async {
        let query =
            searchText.trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        guard !query.isEmpty else {
            results = []
            selectedUser = nil
            searchCompleted = false
            errorMessage = nil
            isSearching = false
            return
        }

        isSearching = true
        errorMessage = nil

        do {
            try await Task.sleep(
                for: .milliseconds(300)
            )

            guard !Task.isCancelled else {
                return
            }

            results =
                try await ProfileSearchService
                    .searchUsers(
                        query: query
                    )

            searchCompleted = true
        } catch is CancellationError {
            return
        } catch {
            results = []
            searchCompleted = true
            errorMessage =
                "Unable to search users. Please try again."

            print(
                "RECIPE RECIPIENT SEARCH ERROR:",
                error.localizedDescription
            )
        }

        isSearching = false
    }
}

// MARK: - Helpers

private extension RecipeRecipientSelectionView {
    func displayName(
        for user: ProfileSearchResult
    ) -> String {
        if let displayName =
            cleaned(
                user.displayName
            ) {
            return displayName
        }

        let firstName =
            cleaned(
                user.firstName
            ) ?? ""

        let lastName =
            cleaned(
                user.lastName
            ) ?? ""

        let fullName =
            "\(firstName) \(lastName)"
                .trimmingCharacters(
                    in: .whitespacesAndNewlines
                )

        if !fullName.isEmpty {
            return fullName
        }

        if let username =
            cleaned(
                user.username
            ) {
            return username
        }

        return "Kin Kitchen User"
    }

    func cleaned(
        _ value: String?
    ) -> String? {
        guard let value else {
            return nil
        }

        let cleanedValue =
            value.trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        return cleanedValue.isEmpty
            ? nil
            : cleanedValue
    }
}

//
//  HomeView.swift
//  KinKitchen
//
//  Created by Greg Hudler on 8/26/26.
//

import SwiftUI


struct HomeView: View {

    @State private var showingAddRecipe = false

    @State private var upcomingGatherings:
        [GatheringListItem] = []

    @State private var isLoadingGatherings = true

    @State private var firstName = ""


    var body: some View {

        NavigationStack {

            ScrollView {

                VStack(
                    alignment: .leading,
                    spacing: KinSpacing.xLarge
                ) {

                    // MARK: - Welcome

                    VStack(
                        alignment: .leading,
                        spacing: KinSpacing.xSmall
                    ) {

                        Text("Welcome back,")
                            .font(
                                KinTypography.body
                            )
                            .foregroundStyle(
                                KinColors.secondaryText
                            )

                        Text(
                            firstName.isEmpty
                                ? "Chef"
                                : firstName
                        )
                        .font(
                            KinTypography.largeTitle
                        )
                        .foregroundStyle(
                            KinColors.primaryText
                        )

                        Text("What's cookin'?")
                            .font(
                                KinTypography.body
                            )
                            .foregroundStyle(
                                KinColors.secondaryText
                            )
                    }

                    // MARK: - Upcoming Gatherings

                    KinSectionHeader(
                        title: "Upcoming Gatherings"
                    )

                    upcomingGatheringsSection


                    // MARK: - Quick Actions

                    KinSectionHeader(
                        title: "Quick Actions"
                    )

                    HStack(
                        spacing: KinSpacing.medium
                    ) {

                        // Add Recipe

                        KinIconButton(
                            icon: KinIcons.add
                        ) {

                            showingAddRecipe = true
                        }


                        // Recipes

                        KinIconButton(
                            icon: KinIcons.recipes
                        ) {

                            print(
                                "Recipes tapped"
                            )
                        }


                        // Gatherings

                        KinIconButton(
                            icon: KinIcons.gatherings
                        ) {

                            print(
                                "Gatherings tapped"
                            )
                        }
                    }


                    // MARK: - My Collections

                    KinSectionHeader(
                        title: "My Collections"
                    )

                    KinEmptyState(
                        icon: KinIcons.cookbooks,
                        title: "No Collections Yet",
                        message:
                            "Your saved recipes and cookbooks will appear here."
                    )


                    // MARK: - For You

                    KinSectionHeader(
                        title: "For You"
                    )

                    KinCard {

                        Text(
                            "Personalized recommendations will appear here."
                        )
                        .font(
                            KinTypography.body
                        )
                        .foregroundStyle(
                            KinColors.secondaryText
                        )
                    }
                }
                .padding(
                    KinSpacing.large
                )
            }
            .background(
                KinColors.background
            )
            .task {

                await loadHome()
            }
            .refreshable {

                await loadHome()
            }


            // MARK: - Add Recipe Destination

            .navigationDestination(
                isPresented: $showingAddRecipe
            ) {

                AddRecipeView()
            }
        }
    }
}


// MARK: - Upcoming Gatherings

private extension HomeView {

    @ViewBuilder
    var upcomingGatheringsSection:
        some View {

        if isLoadingGatherings {

            KinCard {

                HStack(
                    spacing: KinSpacing.medium
                ) {

                    ProgressView()

                    Text(
                        "Loading gatherings..."
                    )
                    .font(
                        KinTypography.body
                    )
                    .foregroundStyle(
                        KinColors.secondaryText
                    )
                }
            }

        } else if upcomingGatherings.isEmpty {

            KinCard {

                VStack(
                    alignment: .leading,
                    spacing: KinSpacing.small
                ) {

                    Text(
                        "No upcoming gatherings"
                    )
                    .font(
                        KinTypography.title3
                    )
                    .foregroundStyle(
                        KinColors.primaryText
                    )

                    Text(
                        "Your upcoming community meals will appear here."
                    )
                    .font(
                        KinTypography.body
                    )
                    .foregroundStyle(
                        KinColors.secondaryText
                    )
                }
            }

        } else {

            VStack(
                spacing: KinSpacing.medium
            ) {

                ForEach(
                    upcomingGatherings
                ) { item in

                    homeGatheringCard(
                        item
                    )
                }
            }
        }
    }


    func homeGatheringCard(
        _ item: GatheringListItem
    ) -> some View {

        let gathering =
            item.gathering

        return KinCard {

            HStack(
                spacing: KinSpacing.medium
            ) {

                Image(
                    systemName:
                        gatheringIcon(
                            for: item
                        )
                )
                .font(
                    .system(
                        size: 22,
                        weight: .semibold
                    )
                )
                .foregroundStyle(
                    relationshipColor(
                        for: item
                    )
                )
                .frame(
                    width: 44,
                    height: 44
                )
                .background(
                    relationshipColor(
                        for: item
                    )
                    .opacity(0.10)
                )
                .clipShape(
                    Circle()
                )


                VStack(
                    alignment: .leading,
                    spacing: KinSpacing.xSmall
                ) {

                    Text(
                        gathering.name
                    )
                    .font(
                        KinTypography.headline
                    )
                    .foregroundStyle(
                        KinColors.primaryText
                    )
                    .lineLimit(2)


                    Text(
                        formattedGatheringDate(
                            gathering.startsAt
                        )
                    )
                    .font(
                        KinTypography.caption
                    )
                    .foregroundStyle(
                        KinColors.secondaryText
                    )


                    if let location =
                        cleaned(
                            gathering.location
                        ) {

                        Text(
                            location
                        )
                        .font(
                            KinTypography.caption
                        )
                        .foregroundStyle(
                            KinColors.secondaryText
                        )
                        .lineLimit(1)
                    }
                }
                .frame(
                    maxWidth: .infinity,
                    alignment: .leading
                )


                VStack(
                    alignment: .trailing,
                    spacing: KinSpacing.small
                ) {

                    Text(
                        item.relationship
                            .displayName
                    )
                    .font(
                        KinTypography.caption
                    )
                    .foregroundStyle(
                        relationshipColor(
                            for: item
                        )
                    )
                    .padding(
                        .horizontal,
                        KinSpacing.small
                    )
                    .padding(
                        .vertical,
                        KinSpacing.xSmall
                    )
                    .background(
                        relationshipColor(
                            for: item
                        )
                        .opacity(0.10)
                    )
                    .clipShape(
                        Capsule()
                    )
                }
                .fixedSize(
                    horizontal: true,
                    vertical: false
                )
            }
        }
    }
}


// MARK: - Home Data

private extension HomeView {

    @MainActor
    func loadHome() async {

        isLoadingGatherings = true

        async let profileTask =
            ProfileService
                .fetchCurrentProfile()

        async let gatheringsTask =
            GatheringService
                .fetchUpcomingGatheringItems()

        do {

            let (
                profile,
                gatherings
            ) = try await (
                profileTask,
                gatheringsTask
            )

            firstName =
                profile.firstName?
                    .trimmingCharacters(
                        in:
                            .whitespacesAndNewlines
                    )
                ?? ""

            upcomingGatherings =
                Array(
                    gatherings.prefix(3)
                )

        } catch {

            print(
                "HOME LOAD ERROR:",
                error.localizedDescription
            )
        }

        isLoadingGatherings = false
    }
}


// MARK: - Gathering Helpers

private extension HomeView {

    func relationshipColor(
        for item: GatheringListItem
    ) -> Color {

        switch item.relationship {

        case .hosting:
            return KinColors.primary

        case .going:
            return .green

        case .invited:
            return KinColors.warning
        }
    }


    func gatheringIcon(
        for item: GatheringListItem
    ) -> String {

        switch item.relationship {

        case .hosting:
            return "house.fill"

        case .going:
            return "person.3.fill"

        case .invited:
            return "envelope.fill"
        }
    }


    func formattedGatheringDate(
        _ date: Date
    ) -> String {

        date.formatted(
            .dateTime
                .weekday(.wide)
                .hour()
                .minute()
        )
    }


    func cleaned(
        _ value: String?
    ) -> String? {

        guard let value else {

            return nil
        }

        let cleanedValue =
            value.trimmingCharacters(
                in:
                    .whitespacesAndNewlines
            )

        return cleanedValue.isEmpty
            ? nil
            : cleanedValue
    }
}


#Preview {

    HomeView()
}

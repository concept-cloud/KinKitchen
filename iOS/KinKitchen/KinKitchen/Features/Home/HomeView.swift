//
//  HomeView.swift
//  KinKitchen
//
//  Created by Greg Hudler on 8/26/26.
//

import SwiftUI

struct HomeView: View {

    @State private var showingAddRecipe = false

    var body: some View {

        NavigationStack {

            ScrollView {

                VStack(
                    alignment: .leading,
                    spacing: KinSpacing.xLarge
                ) {

                    Text("Good morning")
                        .font(KinTypography.largeTitle)
                        .foregroundStyle(
                            KinColors.primaryText
                        )

                    Text("Welcome to Kin Kitchen")
                        .font(KinTypography.body)
                        .foregroundStyle(
                            KinColors.secondaryText
                        )


                    // MARK: - Upcoming Gatherings

                    KinSectionHeader(
                        title: "Upcoming Gatherings"
                    )

                    KinCard {

                        VStack(
                            alignment: .leading,
                            spacing: KinSpacing.small
                        ) {

                            Text(
                                "No upcoming gatherings"
                            )
                            .font(KinTypography.title3)
                            .foregroundStyle(
                                KinColors.primaryText
                            )

                            Text(
                                "Your upcoming community meals will appear here."
                            )
                            .font(KinTypography.body)
                            .foregroundStyle(
                                KinColors.secondaryText
                            )
                        }
                    }


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

                            print("Recipes tapped")
                        }


                        // Gatherings

                        KinIconButton(
                            icon: KinIcons.gatherings
                        ) {

                            print("Gatherings tapped")
                        }
                        
                        // test buttons
                        
                        Button("Test Gathering Service") {
                            Task {
                                do {
                                    let created =
                                        try await GatheringService.createGathering(
                                            name: "Test Gathering",
                                            description: "KINKIT-108 service test",
                                            location: "Oxford, PA",
                                            startsAt: Date().addingTimeInterval(86_400),
                                            guestLimit: 12
                                        )

                                    print("CREATED:", created.id)
                                    print("STATUS:", created.status.rawValue)

                                    let fetched =
                                        try await GatheringService.fetchGathering(
                                            id: created.id
                                        )

                                    print("FETCHED:", fetched.name)

                                    let updated =
                                        try await GatheringService.updateGathering(
                                            id: created.id,
                                            name: "Updated Test Gathering",
                                            description: "Updated description",
                                            location: "Oxford, PA",
                                            startsAt: created.startsAt,
                                            guestLimit: 20
                                        )

                                    print("UPDATED:", updated.name)
                                    print("GUEST LIMIT:", updated.guestLimit ?? 0)

                                    let cancelled =
                                        try await GatheringService.cancelGathering(
                                            id: created.id
                                        )

                                    print(
                                        "CANCELLED:",
                                        cancelled.status.rawValue
                                    )

                                } catch {
                                    print(
                                        "GATHERING SERVICE ERROR:",
                                        error.localizedDescription
                                    )
                                }
                            }
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
                        .font(KinTypography.body)
                        .foregroundStyle(
                            KinColors.secondaryText
                        )
                    }
                }
                .padding(KinSpacing.large)
            }
            .background(
                KinColors.background
            )

            // MARK: - Add Recipe Destination

            .navigationDestination(
                isPresented: $showingAddRecipe
            ) {

                AddRecipeView()
            }
        }
    }
}


#Preview {

    HomeView()
}

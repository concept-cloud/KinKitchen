//
//  HomeView.swift
//  KinKitchen
//
//  Created by Greg Hudler on 8/26/26.
//

import SwiftUI

struct HomeView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: KinSpacing.xLarge) {

                Text("Good morning")
                    .font(KinTypography.largeTitle)
                    .foregroundStyle(KinColors.primaryText)

                Text("Welcome to Kin Kitchen")
                    .font(KinTypography.body)
                    .foregroundStyle(KinColors.secondaryText)

                KinSectionHeader(title: "Upcoming Gatherings")

                KinCard {
                    VStack(alignment: .leading, spacing: KinSpacing.small) {
                        Text("No upcoming gatherings")
                            .font(KinTypography.title3)
                            .foregroundStyle(KinColors.primaryText)

                        Text("Your upcoming community meals will appear here.")
                            .font(KinTypography.body)
                            .foregroundStyle(KinColors.secondaryText)
                    }
                }

                KinSectionHeader(title: "Quick Actions")

                HStack(spacing: KinSpacing.medium) {
                    KinIconButton(icon: KinIcons.add) {
                        print("Add tapped")
                    }

                    KinIconButton(icon: KinIcons.recipes) {
                        print("Recipes tapped")
                    }

                    KinIconButton(icon: KinIcons.gatherings) {
                        print("Gatherings tapped")
                    }
                }

                KinSectionHeader(title: "My Collections")

                KinEmptyState(
                    icon: KinIcons.cookbooks,
                    title: "No Collections Yet",
                    message: "Your saved recipes and cookbooks will appear here."
                )

                KinSectionHeader(title: "For You")

                KinCard {
                    Text("Personalized recommendations will appear here.")
                        .font(KinTypography.body)
                        .foregroundStyle(KinColors.secondaryText)
                }
            }
            .padding(KinSpacing.large)
        }
        .background(KinColors.background)
    }
}

#Preview {
    HomeView()
}

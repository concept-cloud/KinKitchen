//
//  ContentView.swift
//  KinKitchen
//
//  Created by Greg Hudler on 8/26/26.
//

import SwiftUI

struct ContentView: View {

    @State private var selectedTab = 0

    private let tabItems = [

        KinTabBarItem(
            title: "Home",
            icon: KinIcons.home
        ),

        KinTabBarItem(
            title: "Gatherings",
            icon: KinIcons.gatherings
        ),

        KinTabBarItem(
            title: "Recipes",
            icon: KinIcons.recipes
        ),

        KinTabBarItem(
            title: "Cookbooks",
            icon: KinIcons.cookbooks
        ),

        KinTabBarItem(
            title: "Profile",
            icon: KinIcons.profile
        )
    ]

    var body: some View {

        VStack(spacing: 0) {

            ZStack {

                HomeView()
                    .opacity(selectedTab == 0 ? 1 : 0)
                    .allowsHitTesting(selectedTab == 0)

                GatheringsView()
                    .opacity(selectedTab == 1 ? 1 : 0)
                    .allowsHitTesting(selectedTab == 1)

                RecipesView()
                    .opacity(selectedTab == 2 ? 1 : 0)
                    .allowsHitTesting(selectedTab == 2)

                CookbooksView()
                    .opacity(selectedTab == 3 ? 1 : 0)
                    .allowsHitTesting(selectedTab == 3)

                ProfileView()
                    .opacity(selectedTab == 4 ? 1 : 0)
                    .allowsHitTesting(selectedTab == 4)
            }
            .frame(
                maxWidth: .infinity,
                maxHeight: .infinity
            )
            .background(
                KinColors.background
            )

            KinTabBar(
                items: tabItems,
                selectedIndex: $selectedTab
            )
        }
        .background(
            KinColors.background
                .ignoresSafeArea()
        )
        .ignoresSafeArea(.keyboard)
    }
}

#Preview {

    ContentView()
}

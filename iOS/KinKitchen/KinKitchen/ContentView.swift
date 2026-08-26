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
            
            Group {
                switch selectedTab {
                case 0:
                    Text("Home")
                    
                case 1:
                    Text("Gatherings")
                    
                case 2:
                    Text("Recipes")
                    
                case 3:
                    Text("Cookbooks")
                    
                case 4:
                    Text("Profile")
                    
                default:
                    Text("Home")
                }
            }
            .font(KinTypography.largeTitle)
            .foregroundStyle(KinColors.primaryText)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(KinColors.background)
            
            KinTabBar(
                items: tabItems,
                selectedIndex: $selectedTab
            )
        }
        .ignoresSafeArea(.keyboard)
    }
}

#Preview {
    ContentView()
}

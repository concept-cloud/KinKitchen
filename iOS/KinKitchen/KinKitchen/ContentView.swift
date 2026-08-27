//
//  ContentView.swift
//  KinKitchen
//
//  Created by Greg Hudler on 8/26/26.
//

import SwiftUI
import Supabase

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
                    HomeView()
                    
                case 1:
                    GatheringsView()
                    
                case 2:
                    RecipesView()
                    
                case 3:
                    CookbooksView()
                    
                case 4:
                    ProfileView()
                    
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
        .task {
            do {
                let allergens: [AllergenTest] = try await SupabaseManager.client
                    .from("allergens")
                    .select()
                    .limit(1)
                    .execute()
                    .value

                print("Supabase connection successful:", allergens)
            } catch {
                print("Supabase connection failed:", error)
            }
        }
    }
}

struct AllergenTest: Decodable {
    let id: UUID
    let name: String
}

#Preview {
    ContentView()
}

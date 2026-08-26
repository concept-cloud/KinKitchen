//
//  ContentView.swift
//  KinKitchen
//
//  Created by Greg Hudler on 8/26/26.
//

import SwiftUI
import PhotosUI

struct ContentView: View {

    @State private var textFieldText = ""
    @State private var secureText = ""
    @State private var editorText = "This is a KinTextEditor test."
    @State private var searchText = ""
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedTab = 0

    private let tabItems = [
        KinTabBarItem(title: "Home", icon: KinIcons.home),
        KinTabBarItem(title: "Gatherings", icon: KinIcons.gatherings),
        KinTabBarItem(title: "Recipes", icon: KinIcons.recipes),
        KinTabBarItem(title: "Cookbooks", icon: KinIcons.cookbooks),
        KinTabBarItem(title: "Profile", icon: KinIcons.profile)
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: KinSpacing.xLarge) {

                // MARK: - Buttons

                KinSectionHeader(title: "Buttons")

                KinPrimaryButton(title: "Primary Button") {
                    print("Primary tapped")
                }

                KinSecondaryButton(title: "Secondary Button") {
                    print("Secondary tapped")
                }

                KinDestructiveButton(title: "Delete") {
                    print("Destructive tapped")
                }

                HStack {
                    KinIconButton(icon: KinIcons.add) {
                        print("Add tapped")
                    }

                    KinIconButton(icon: KinIcons.edit) {
                        print("Edit tapped")
                    }

                    KinIconButton(icon: KinIcons.favorite) {
                        print("Favorite tapped")
                    }
                }

                Divider()

                // MARK: - Inputs

                KinSectionHeader(title: "Inputs")

                KinTextField(
                    title: "Enter text",
                    text: $textFieldText
                )

                KinSecureField(
                    title: "Password",
                    text: $secureText
                )

                KinTextEditor(
                    text: $editorText
                )

                KinSearchBar(
                    text: $searchText,
                    placeholder: "Search recipes"
                )

                KinPhotoPicker(
                    selectedItem: $selectedItem
                )

                Divider()

                // MARK: - Labels

                KinSectionHeader(title: "Labels")

                HStack {
                    KinChip(title: "Gluten-Free")
                    KinChip(title: "Selected", isSelected: true)
                }

                HStack {
                    KinBadge(
                        title: "Private",
                        color: KinColors.secondary
                    )

                    KinStatusBadge(
                        title: "Success",
                        status: .success
                    )

                    KinStatusBadge(
                        title: "Warning",
                        status: .warning
                    )

                    KinStatusBadge(
                        title: "Error",
                        status: .error
                    )
                }

                Divider()

                // MARK: - Cards

                KinSectionHeader(title: "Cards")

                KinCard {
                    VStack(alignment: .leading) {
                        Text("KinCard")
                            .font(KinTypography.title3)

                        Text("Reusable card content.")
                            .font(KinTypography.body)
                    }
                }

                KinImageCard(
                    image: Image(systemName: KinIcons.photo),
                    title: "KinImageCard",
                    subtitle: "Image, title, and subtitle"
                )

                Divider()

                // MARK: - Navigation

                KinSectionHeader(title: "Navigation")

                KinNavigationBar(
                    title: "Recipe Detail",
                    showBackButton: true,
                    actionIcon: KinIcons.share,
                    backAction: {
                        print("Back tapped")
                    },
                    action: {
                        print("Share tapped")
                    }
                )

                KinTabBar(
                    items: tabItems,
                    selectedIndex: $selectedTab
                )

                Text("Selected Tab: \(selectedTab)")
                    .font(KinTypography.body)

                Divider()

                // MARK: - Feedback

                KinSectionHeader(title: "Feedback")

                KinWarning(
                    title: "Allergen Warning",
                    message: "This recipe may contain peanuts."
                )

                KinEmptyState(
                    icon: KinIcons.recipes,
                    title: "No Recipes Yet",
                    message: "Create your first recipe to get started."
                )

                KinLoadingView(
                    message: "Loading recipes..."
                )

                KinErrorView(
                    message: "Unable to load data."
                ) {
                    print("Retry tapped")
                }
            }
            .padding(KinSpacing.large)
        }
        .background(KinColors.background)
    }
}

#Preview {
    ContentView()
}

//
//  DietaryProfileView.swift
//  KinKitchen
//
//  Created by Greg Hudler on 8/30/26.
//

import SwiftUI

struct DietaryProfileView: View {

    // MARK: - Dietary Data

    @State private var allergens: [Allergen] = []
    @State private var restrictions: [DietaryRestriction] = []
    @State private var preferences: [DietaryPreference] = []
    @State private var lastUpdated: Date?

    // MARK: - View State

    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var isEditingDietaryProfile = false

    var body: some View {

        ScrollView {

            VStack(
                alignment: .leading,
                spacing: KinSpacing.xLarge
            ) {

                if isLoading {

                    KinLoadingView()

                } else {
                    
                    
                    // MARK: - Last Updated

                    HStack(
                        alignment: .center,
                        spacing: KinSpacing.medium
                    ) {

                        if let lastUpdated {

                            Text("Last updated \(lastUpdated, format: .dateTime.month(.abbreviated).day().year())")
                                .font(KinTypography.subheadline)
                                .foregroundStyle(KinColors.primary)

                        } else {

                            Text("Last updated unavailable")
                                .font(KinTypography.subheadline)
                                .foregroundStyle(KinColors.primary)
                        }

                        Spacer()
                        
                        Button {

                            isEditingDietaryProfile = true

                        } label: {

                            HStack(
                                spacing: KinSpacing.small
                            ) {

                                Image(systemName: "pencil")

                                Text("Edit")
                            }
                            .font(KinTypography.subheadline)
                            .foregroundStyle(KinColors.primary)
                        }
                        .buttonStyle(.plain)

                    }

                    // MARK: - Allergens

                    dietarySection(
                        title: "Allergens",
                        items: allergens.map(\.name),
                        emptyMessage: "No allergens selected."
                    )

                    // MARK: - Dietary Restrictions

                    dietarySection(
                        title: "Dietary Restrictions",
                        items: restrictions.map(\.name),
                        emptyMessage: "No dietary restrictions selected."
                    )

                    // MARK: - Dietary Preferences

                    dietarySection(
                        title: "Dietary Preferences",
                        items: preferences.map(\.name),
                        emptyMessage: "No dietary preferences selected."
                    )

                    // MARK: - Error

                    if let errorMessage {

                        Text(errorMessage)
                            .font(KinTypography.body)
                            .foregroundStyle(KinColors.error)
                            .frame(
                                maxWidth: .infinity,
                                alignment: .leading
                            )
                    }
                }
            }
            .padding(KinSpacing.xLarge)
        }
        .background(KinColors.background)
        .navigationTitle("Dietary Profile")
        .navigationBarTitleDisplayMode(.inline)

        // MARK: - Load Dietary Information

        .task {

            await loadDietaryInformation()
        }

        // MARK: - Edit Dietary Profile

        .navigationDestination(
            isPresented: $isEditingDietaryProfile
        ) {

            EditDietaryProfileView()
        }

        // MARK: - Refresh After Editing

        .onChange(
            of: isEditingDietaryProfile
        ) { _, isEditing in

            if !isEditing {

                Task {

                    await loadDietaryInformation()
                }
            }
        }
    }

    // MARK: - Dietary Section

    @ViewBuilder
    private func dietarySection(
        title: String,
        items: [String],
        emptyMessage: String
    ) -> some View {

        VStack(
            alignment: .leading,
            spacing: KinSpacing.medium
        ) {

            Text(title)
                .font(KinTypography.title)
                .foregroundStyle(KinColors.primaryText)

            if items.isEmpty {

                Text(emptyMessage)
                    .font(KinTypography.body)
                    .foregroundStyle(KinColors.secondaryText)

            } else {

                KinFlowLayout(
                    spacing: KinSpacing.small
                ) {

                    ForEach(
                        items,
                        id: \.self
                    ) { item in

                        KinChip(
                            title: item,
                            isSelected: true
                        )
                    }
                }
            }
        }
        .frame(
            maxWidth: .infinity,
            alignment: .leading
        )
    }

    // MARK: - Load Dietary Information

    @MainActor
    private func loadDietaryInformation() async {

        isLoading = true
        errorMessage = nil

        defer {

            isLoading = false
        }

        do {

            async let loadedAllergens =
                DietaryService.fetchAllergens()

            async let loadedRestrictions =
                DietaryService.fetchDietaryRestrictions()

            async let loadedPreferences =
                DietaryService.fetchDietaryPreferences()

            async let selectedAllergenIds =
                DietaryService.fetchSelectedAllergens()

            async let selectedRestrictionIds =
                DietaryService.fetchSelectedDietaryRestrictions()

            async let selectedPreferenceIds =
                DietaryService.fetchSelectedDietaryPreferences()
            
            async let loadedLastUpdated =
                ProfileService.fetchDietaryLastUpdated()

            let allAllergens =
                try await loadedAllergens

            let allRestrictions =
                try await loadedRestrictions

            let allPreferences =
                try await loadedPreferences

            let allergenIds =
                Set(try await selectedAllergenIds)

            let restrictionIds =
                Set(try await selectedRestrictionIds)

            let preferenceIds =
                Set(try await selectedPreferenceIds)
            
            lastUpdated =
                try await loadedLastUpdated

            allergens =
                allAllergens.filter {
                    allergenIds.contains($0.id)
                }

            restrictions =
                allRestrictions.filter {
                    restrictionIds.contains($0.id)
                }

            preferences =
                allPreferences.filter {
                    preferenceIds.contains($0.id)
                }

        } catch {

            errorMessage =
                "Unable to load your dietary profile."

            print(
                "DIETARY PROFILE LOAD ERROR:",
                error.localizedDescription
            )
        }
    }
}

#Preview {

    NavigationStack {
        DietaryProfileView()
    }
}

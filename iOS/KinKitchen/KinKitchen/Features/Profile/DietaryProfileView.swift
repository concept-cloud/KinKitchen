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

        DietaryHeroPage(
            title: "Dietary Profile",
            eyebrow: "YOUR FOOD PROFILE",
            headline: "Made for you.",
            message: "Your preferences help Kin Kitchen highlight recipes that fit your needs."
        ) {

            if isLoading {

                KinLoadingView()
                    .padding(.top, KinSpacing.xLarge)

            } else {

                summaryCard(
                    .allergens,
                    subtitle: "These ingredients will be flagged in recipes.",
                    badge: DietaryProfileText.allergenCount(allergens.count),
                    items: allergens.map(\.name)
                )

                summaryCard(
                    .restrictions,
                    subtitle: "Foods you don't eat.",
                    items: restrictions.map(\.name)
                )

                summaryCard(
                    .preferences,
                    subtitle: "Your preferred eating style.",
                    items: preferences.map(\.name)
                )

                disclaimer

                if let errorMessage {

                    Text(errorMessage)
                        .font(KinTypography.body)
                        .foregroundStyle(KinColors.error)
                        .frame(
                            maxWidth: .infinity,
                            alignment: .leading
                        )
                }

                Text(DietaryProfileText.lastUpdated(lastUpdated))
                    .font(KinTypography.footnote)
                    .foregroundStyle(KinColors.secondaryText)
                    .padding(.top, KinSpacing.small)
            }

        } trailing: {

            Button {

                isEditingDietaryProfile = true

            } label: {

                Label(
                    "Edit",
                    systemImage: KinIcons.edit
                )
                .labelStyle(.titleAndIcon)
                .font(KinTypography.subheadline)
            }
            .tint(KinColors.primary)
            .disabled(isLoading)
        }

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


    // MARK: - Summary Card

    /// Read-only card: the chosen items, or a note when there are none.
    private func summaryCard(
        _ section: DietarySection,
        subtitle: String,
        badge: String? = nil,
        items: [String]
    ) -> some View {

        DietaryCard(
            section: section,
            subtitle: items.isEmpty ? section.emptyMessage : subtitle,
            badge: badge
        ) {

            if !items.isEmpty {

                KinFlowLayout(
                    spacing: KinSpacing.small
                ) {

                    ForEach(
                        items,
                        id: \.self
                    ) { item in

                        DietaryChip(
                            title: item,
                            tint: section.tint
                        )
                    }
                }
            }
        }
        .accessibilityElement(children: .combine)
    }


    // MARK: - Disclaimer

    private var disclaimer: some View {

        HStack(
            alignment: .top,
            spacing: KinSpacing.medium
        ) {

            Image(systemName: KinIcons.info)
                .font(.system(size: 20))
                .foregroundStyle(KinColors.secondaryText)
                .accessibilityHidden(true)

            Text("Kin Kitchen highlights potential ingredient conflicts based on your profile. Always verify ingredients and preparation when managing food allergies.")
                .font(KinTypography.footnote)
                .foregroundStyle(KinColors.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(KinSpacing.large)
        .frame(
            maxWidth: .infinity,
            alignment: .leading
        )
        .background(
            KinColors.surface.opacity(0.6),
            in: RoundedRectangle(
                cornerRadius: KinRadius.large
            )
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


// MARK: - Text

nonisolated enum DietaryProfileText {

    /// "1 allergen", "4 allergens"; nil when there are none.
    static func allergenCount(_ count: Int) -> String? {
        switch count {
        case 0: return nil
        case 1: return "1 allergen"
        default: return "\(count) allergens"
        }
    }

    /// "Last updated September 11, 2026"
    static func lastUpdated(
        _ date: Date?,
        locale: Locale = .current
    ) -> String {
        guard let date else {
            return "Last updated unavailable"
        }
        return "Last updated "
            + date.formatted(
                .dateTime.month(.wide).day().year().locale(locale)
            )
    }
}

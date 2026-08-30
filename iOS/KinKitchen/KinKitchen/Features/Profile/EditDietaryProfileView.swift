//
//  EditDietaryProfileView.swift
//  KinKitchen
//
//  Created by Greg Hudler on 8/30/26.
//

import SwiftUI

struct EditDietaryProfileView: View {

    @Environment(\.dismiss) private var dismiss

    @State private var allergens: [Allergen] = []
    @State private var restrictions: [DietaryRestriction] = []
    @State private var preferences: [DietaryPreference] = []

    @State private var selectedAllergenIds: Set<UUID> = []
    @State private var selectedRestrictionIds: Set<UUID> = []
    @State private var selectedPreferenceIds: Set<UUID> = []

    @State private var originalAllergenIds: Set<UUID> = []
    @State private var originalRestrictionIds: Set<UUID> = []
    @State private var originalPreferenceIds: Set<UUID> = []

    @State private var isLoading = true
    @State private var isSaving = false
    @State private var errorMessage: String?

    var body: some View {
            ScrollView {
                VStack(alignment: .leading, spacing: KinSpacing.xLarge) {

                    if isLoading {

                        KinLoadingView()

                    } else {

                        dietarySection(
                            title: "Allergens",
                            items: allergens,
                            selectedIds: $selectedAllergenIds
                        )

                        dietarySection(
                            title: "Dietary Restrictions",
                            items: restrictions,
                            selectedIds: $selectedRestrictionIds
                        )

                        dietarySection(
                            title: "Dietary Preferences",
                            items: preferences,
                            selectedIds: $selectedPreferenceIds
                        )

                        if let errorMessage {
                            Text(errorMessage)
                                .font(KinTypography.body)
                                .foregroundStyle(KinColors.error)
                        }

                        KinPrimaryButton(
                            title: isSaving ? "Saving..." : "Save Changes",
                            color: KinColors.success
                        ) {
                            Task {
                                await saveChanges()
                            }
                        }
                        .disabled(isSaving)
                    }
                }
                .padding(KinSpacing.xLarge)
            }
            .background(KinColors.background)
            .navigationTitle("Edit Dietary Profile")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                await loadDietaryInformation()
            }
    }

    private func dietarySection<Item: Identifiable>(
        title: String,
        items: [Item],
        selectedIds: Binding<Set<UUID>>
    ) -> some View where Item.ID == UUID {

        VStack(alignment: .leading, spacing: KinSpacing.medium) {

            Text(title)
                .font(KinTypography.title)
                .foregroundStyle(KinColors.primaryText)

            KinFlowLayout(spacing: KinSpacing.small) {
                ForEach(items) { item in
                    Button {
                        toggle(
                            id: item.id,
                            selectedIds: selectedIds
                        )
                    } label: {
                        KinChip(
                            title: itemName(item),
                            isSelected: selectedIds.wrappedValue.contains(item.id)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func itemName<Item>(_ item: Item) -> String {
        if let allergen = item as? Allergen {
            return allergen.name
        }

        if let restriction = item as? DietaryRestriction {
            return restriction.name
        }

        if let preference = item as? DietaryPreference {
            return preference.name
        }

        return ""
    }

    private func toggle(
        id: UUID,
        selectedIds: Binding<Set<UUID>>
    ) {
        if selectedIds.wrappedValue.contains(id) {
            selectedIds.wrappedValue.remove(id)
        } else {
            selectedIds.wrappedValue.insert(id)
        }
    }

    @MainActor
    private func loadDietaryInformation() async {
        isLoading = true
        errorMessage = nil

        defer {
            isLoading = false
        }

        do {
            async let loadedAllergens = DietaryService.fetchAllergens()
            async let loadedRestrictions = DietaryService.fetchDietaryRestrictions()
            async let loadedPreferences = DietaryService.fetchDietaryPreferences()

            async let savedAllergens = DietaryService.fetchSelectedAllergens()
            async let savedRestrictions = DietaryService.fetchSelectedDietaryRestrictions()
            async let savedPreferences = DietaryService.fetchSelectedDietaryPreferences()

            allergens = try await loadedAllergens
            restrictions = try await loadedRestrictions
            preferences = try await loadedPreferences

            selectedAllergenIds = Set(try await savedAllergens)
            selectedRestrictionIds = Set(try await savedRestrictions)
            selectedPreferenceIds = Set(try await savedPreferences)

            originalAllergenIds = selectedAllergenIds
            originalRestrictionIds = selectedRestrictionIds
            originalPreferenceIds = selectedPreferenceIds

        } catch {
            errorMessage = error.localizedDescription
        }
    }

    @MainActor
    private func saveChanges() async {
        isSaving = true
        errorMessage = nil

        defer {
            isSaving = false
        }

        do {
            let allergensToAdd =
                selectedAllergenIds.subtracting(originalAllergenIds)

            let allergensToRemove =
                originalAllergenIds.subtracting(selectedAllergenIds)

            let restrictionsToAdd =
                selectedRestrictionIds.subtracting(originalRestrictionIds)

            let restrictionsToRemove =
                originalRestrictionIds.subtracting(selectedRestrictionIds)

            let preferencesToAdd =
                selectedPreferenceIds.subtracting(originalPreferenceIds)

            let preferencesToRemove =
                originalPreferenceIds.subtracting(selectedPreferenceIds)

            for id in allergensToAdd {
                try await DietaryService.addAllergen(id)
            }

            for id in allergensToRemove {
                try await DietaryService.removeAllergen(id)
            }

            for id in restrictionsToAdd {
                try await DietaryService.addDietaryRestriction(id)
            }

            for id in restrictionsToRemove {
                try await DietaryService.removeDietaryRestriction(id)
            }

            for id in preferencesToAdd {
                try await DietaryService.addDietaryPreference(id)
            }

            for id in preferencesToRemove {
                try await DietaryService.removeDietaryPreference(id)
            }

            dismiss()

        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

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

    private var hasChanges: Bool {
        selectedAllergenIds != originalAllergenIds
            || selectedRestrictionIds != originalRestrictionIds
            || selectedPreferenceIds != originalPreferenceIds
    }

    var body: some View {

        DietaryHeroPage(
            title: "Edit Dietary Profile",
            eyebrow: "YOUR FOOD PROFILE",
            headline: "Tell us how you eat.",
            message: "Tap to choose. Kin Kitchen uses this to flag recipes for you."
        ) {

            if isLoading {

                KinLoadingView()
                    .padding(.top, KinSpacing.xLarge)

            } else {

                dietarySection(
                    .allergens,
                    subtitle: "Ingredients to flag in recipes.",
                    badge: DietaryProfileText.allergenCount(selectedAllergenIds.count),
                    items: allergens,
                    selectedIds: $selectedAllergenIds
                )

                dietarySection(
                    .restrictions,
                    subtitle: "Foods you don't eat.",
                    items: restrictions,
                    selectedIds: $selectedRestrictionIds
                )

                dietarySection(
                    .preferences,
                    subtitle: "Your preferred eating style.",
                    items: preferences,
                    selectedIds: $selectedPreferenceIds
                )

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

        } trailing: {
            EmptyView()
        }
        // Save stays in reach while scrolling the lists.
        .safeAreaInset(edge: .bottom) {

            if !isLoading {

                KinPrimaryButton(
                    title: isSaving ? "Saving..." : "Save Changes",
                    color: KinColors.success
                ) {
                    Task {
                        await saveChanges()
                    }
                }
                .disabled(isSaving || !hasChanges)
                .opacity(hasChanges ? 1 : 0.5)
                .padding(.horizontal, KinSpacing.large)
                .padding(.vertical, KinSpacing.small)
                .background(KinColors.background.opacity(0.9))
            }
        }
        .sensoryFeedback(
            .selection,
            trigger: selectedAllergenIds.count
                + selectedRestrictionIds.count
                + selectedPreferenceIds.count
        )
        .task {
            await loadDietaryInformation()
        }
    }

    private func dietarySection<Item: Identifiable>(
        _ section: DietarySection,
        subtitle: String,
        badge: String? = nil,
        items: [Item],
        selectedIds: Binding<Set<UUID>>
    ) -> some View where Item.ID == UUID {

        DietaryCard(
            section: section,
            subtitle: subtitle,
            badge: badge
        ) {

            KinFlowLayout(spacing: KinSpacing.small) {
                ForEach(items) { item in

                    let isSelected =
                        selectedIds.wrappedValue.contains(item.id)

                    Button {
                        toggle(
                            id: item.id,
                            selectedIds: selectedIds
                        )
                    } label: {
                        DietaryChip(
                            title: itemName(item),
                            tint: section.tint,
                            isSelected: isSelected,
                            showsCheck: true
                        )
                    }
                    .buttonStyle(.kinPressable)
                    .accessibilityAddTraits(isSelected ? .isSelected : [])
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

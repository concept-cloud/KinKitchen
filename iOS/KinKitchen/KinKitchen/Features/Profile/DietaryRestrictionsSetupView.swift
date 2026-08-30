//
//  DietaryRestrictionsSetupView.swift
//  KinKitchen
//
//  Created by Greg Hudler on 8/30/26.
//


import SwiftUI

struct DietaryRestrictionsSetupView: View {

    let onContinue: () -> Void

    @State private var allergens: [Allergen] = []
    @State private var restrictions: [DietaryRestriction] = []

    @State private var selectedAllergenIds: Set<UUID> = []
    @State private var selectedRestrictionIds: Set<UUID> = []

    @State private var originalAllergenIds: Set<UUID> = []
    @State private var originalRestrictionIds: Set<UUID> = []

    @State private var hasNoDietaryRestrictions = false

    @State private var isLoading = true
    @State private var isSaving = false

    @State private var errorMessage: String?
    @State private var isShowingErrorAlert = false

    var body: some View {

        ScrollView {

            VStack(
                alignment: .leading,
                spacing: KinSpacing.xLarge
            ) {

                // MARK: - Header

                VStack(
                    alignment: .leading,
                    spacing: KinSpacing.small
                ) {

                    Text("Any Dietary Restrictions?")
                        .font(KinTypography.largeTitle)
                        .foregroundStyle(KinColors.primaryText)
                        .frame(
                            maxWidth: .infinity,
                            alignment: .leading
                        )
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)

                    Text(
                        "Let us know about any foods you need to avoid."
                    )
                    .font(KinTypography.body)
                    .foregroundStyle(
                        KinColors.secondaryText
                    )
                    .frame(
                        maxWidth: .infinity,
                        alignment: .leading
                    )
                }

                if isLoading {

                    KinLoadingView()

                } else {

                    // MARK: - Allergens

                    dietarySection(
                        title: "Allergies",
                        items: allergens,
                        selectedIds: $selectedAllergenIds
                    )

                    // MARK: - Restrictions

                    dietarySection(
                        title: "Dietary Restrictions",
                        items: restrictions,
                        selectedIds: $selectedRestrictionIds
                    )

                    // MARK: - None

                    Button {

                        toggleNoRestrictions()

                    } label: {

                        HStack(
                            spacing: KinSpacing.medium
                        ) {

                            Image(
                                systemName:
                                    hasNoDietaryRestrictions
                                    ? "checkmark.circle.fill"
                                    : "circle"
                            )
                            .font(.title3)
                            .foregroundStyle(
                                hasNoDietaryRestrictions
                                    ? KinColors.success
                                    : KinColors.secondaryText
                            )

                            Text(
                                "I don't have any dietary restrictions"
                            )
                            .font(KinTypography.body)
                            .foregroundStyle(
                                KinColors.primaryText
                            )

                            Spacer()
                        }
                        .frame(
                            maxWidth: .infinity,
                            alignment: .leading
                        )
                        .padding(KinSpacing.medium)
                        .background(
                            KinColors.surface
                        )
                        .clipShape(
                            RoundedRectangle(
                                cornerRadius:
                                    KinRadius.medium
                            )
                        )
                    }
                    .buttonStyle(.plain)

                    // MARK: - Error

                    if let errorMessage {

                        Text(errorMessage)
                            .font(KinTypography.caption)
                            .foregroundStyle(
                                KinColors.error
                            )
                            .frame(
                                maxWidth: .infinity,
                                alignment: .leading
                            )
                    }

                    // MARK: - Continue

                    KinPrimaryButton(
                        title:
                            isSaving
                            ? "Saving..."
                            : "Continue",
                        color: KinColors.success
                    ) {

                        Task {
                            await saveAndContinue()
                        }
                    }
                    .disabled(isSaving)
                }
            }
            .padding(KinSpacing.xLarge)
        }
        .background(KinColors.background)

        .task {
            await loadDietaryInformation()
        }

        .alert(
            "Dietary Restrictions",
            isPresented: $isShowingErrorAlert
        ) {

            Button(
                "OK",
                role: .cancel
            ) { }

        } message: {

            Text(errorMessage ?? "")
        }
    }

    // MARK: - Dietary Section

    private func dietarySection<Item: Identifiable>(
        title: String,
        items: [Item],
        selectedIds: Binding<Set<UUID>>
    ) -> some View where Item.ID == UUID {

        VStack(
            alignment: .leading,
            spacing: KinSpacing.medium
        ) {

            Text(title)
                .font(KinTypography.title)
                .foregroundStyle(
                    KinColors.primaryText
                )

            KinFlowLayout(
                spacing: KinSpacing.small
            ) {

                ForEach(items) { item in

                    Button {

                        toggle(
                            id: item.id,
                            selectedIds:
                                selectedIds
                        )

                    } label: {

                        KinChip(
                            title:
                                itemName(item),
                            isSelected:
                                selectedIds
                                    .wrappedValue
                                    .contains(
                                        item.id
                                    )
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Item Name

    private func itemName<Item>(
        _ item: Item
    ) -> String {

        if let allergen =
            item as? Allergen {

            return allergen.name
        }

        if let restriction =
            item as? DietaryRestriction {

            return restriction.name
        }

        return ""
    }

    // MARK: - Toggle Selection

    private func toggle(
        id: UUID,
        selectedIds:
            Binding<Set<UUID>>
    ) {

        // Selecting a real restriction means
        // "None" can no longer be selected.

        hasNoDietaryRestrictions = false

        if selectedIds
            .wrappedValue
            .contains(id) {

            selectedIds
                .wrappedValue
                .remove(id)

        } else {

            selectedIds
                .wrappedValue
                .insert(id)
        }
    }

    // MARK: - Toggle None

    private func toggleNoRestrictions() {

        hasNoDietaryRestrictions.toggle()

        if hasNoDietaryRestrictions {

            selectedAllergenIds.removeAll()
            selectedRestrictionIds.removeAll()
        }
    }

    // MARK: - Load Data

    @MainActor
    private func loadDietaryInformation()
        async {

        isLoading = true
        errorMessage = nil

        defer {
            isLoading = false
        }

        do {

            async let loadedAllergens =
                DietaryService.fetchAllergens()

            async let loadedRestrictions =
                DietaryService
                    .fetchDietaryRestrictions()

            async let savedAllergens =
                DietaryService
                    .fetchSelectedAllergens()

            async let savedRestrictions =
                DietaryService
                    .fetchSelectedDietaryRestrictions()

            allergens =
                try await loadedAllergens

            restrictions =
                try await loadedRestrictions

            selectedAllergenIds =
                Set(
                    try await savedAllergens
                )

            selectedRestrictionIds =
                Set(
                    try await savedRestrictions
                )

            originalAllergenIds =
                selectedAllergenIds

            originalRestrictionIds =
                selectedRestrictionIds

            hasNoDietaryRestrictions =
                selectedAllergenIds.isEmpty &&
                selectedRestrictionIds.isEmpty

        } catch {

            errorMessage =
                "Unable to load dietary information."

            isShowingErrorAlert = true

            print(
                "DIETARY SETUP LOAD ERROR:",
                error.localizedDescription
            )
        }
    }

    // MARK: - Save

    @MainActor
    private func saveAndContinue()
        async {

        guard !isSaving else {
            return
        }

        errorMessage = nil

        let hasSelections =
            !selectedAllergenIds.isEmpty ||
            !selectedRestrictionIds.isEmpty

        guard
            hasSelections ||
            hasNoDietaryRestrictions
        else {

            errorMessage =
                "Please select any dietary restrictions that apply, or choose that you don't have any."

            isShowingErrorAlert = true

            return
        }

        isSaving = true

        defer {
            isSaving = false
        }

        do {

            let allergensToAdd =
                selectedAllergenIds
                    .subtracting(
                        originalAllergenIds
                    )

            let allergensToRemove =
                originalAllergenIds
                    .subtracting(
                        selectedAllergenIds
                    )

            let restrictionsToAdd =
                selectedRestrictionIds
                    .subtracting(
                        originalRestrictionIds
                    )

            let restrictionsToRemove =
                originalRestrictionIds
                    .subtracting(
                        selectedRestrictionIds
                    )

            for id in allergensToAdd {

                try await DietaryService
                    .addAllergen(id)
            }

            for id in allergensToRemove {

                try await DietaryService
                    .removeAllergen(id)
            }

            for id in restrictionsToAdd {

                try await DietaryService
                    .addDietaryRestriction(id)
            }

            for id in restrictionsToRemove {

                try await DietaryService
                    .removeDietaryRestriction(id)
            }

            originalAllergenIds =
                selectedAllergenIds

            originalRestrictionIds =
                selectedRestrictionIds

            onContinue()

        } catch {

            errorMessage =
                "Unable to save your dietary restrictions. Please try again."

            isShowingErrorAlert = true

            print(
                "DIETARY SETUP SAVE ERROR:",
                error.localizedDescription
            )
        }
    }
}

// MARK: - Preview

#Preview {

    DietaryRestrictionsSetupView {

        print(
            "Continue to dietary preferences"
        )
    }
}

//
//  EditDietaryProfileView.swift
//  KinKitchen
//
//  Created by Greg Hudler on 8/30/26.
//

import SwiftUI

struct EditDietaryProfileView: View {

    @Environment(\.dismiss) private var dismiss

    /// One chip on the edit screen: a built-in item, or one the user
    /// added themselves (`isCustom`).
    struct Choice: Identifiable, Hashable {
        let id: UUID
        let name: String
        var isCustom = false
    }

    /// Typed in but not saved yet.
    struct PendingItem: Identifiable, Hashable {
        let id = UUID()
        let kind: CustomDietaryItem.Kind
        let name: String
    }

    @State private var allergens: [Choice] = []
    @State private var restrictions: [Choice] = []
    @State private var preferences: [Choice] = []

    @State private var selectedAllergenIds: Set<UUID> = []
    @State private var selectedRestrictionIds: Set<UUID> = []
    @State private var selectedPreferenceIds: Set<UUID> = []

    @State private var originalAllergenIds: Set<UUID> = []
    @State private var originalRestrictionIds: Set<UUID> = []
    @State private var originalPreferenceIds: Set<UUID> = []

    @State private var pendingItems: [PendingItem] = []
    @State private var drafts: [CustomDietaryItem.Kind: String] = [:]

    @State private var isLoading = true
    @State private var isSaving = false
    @State private var errorMessage: String?

    private var hasChanges: Bool {
        selectedAllergenIds != originalAllergenIds
            || selectedRestrictionIds != originalRestrictionIds
            || selectedPreferenceIds != originalPreferenceIds
            || !pendingItems.isEmpty
    }

    var body: some View {

        DietaryHeroPage(
            title: "Edit Dietary Profile",
            eyebrow: "YOUR FOOD PROFILE",
            headline: "Tell us how you eat.",
            message: "Tap to choose, or add your own. Kin Kitchen uses this to flag recipes for you."
        ) {

            if isLoading {

                KinLoadingView()
                    .padding(.top, KinSpacing.xLarge)

            } else {

                dietarySection(
                    .allergens,
                    subtitle: "Ingredients to flag in recipes.",
                    badge: DietaryProfileText.allergenCount(
                        selectedAllergenIds.count
                            + pending(.allergen).count
                    ),
                    choices: allergens,
                    selectedIds: $selectedAllergenIds
                )

                dietarySection(
                    .restrictions,
                    subtitle: "Foods you don't eat.",
                    choices: restrictions,
                    selectedIds: $selectedRestrictionIds
                )

                dietarySection(
                    .preferences,
                    subtitle: "Ingredients you'd rather skip.",
                    choices: preferences,
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
                + pendingItems.count
        )
        .task {
            await loadDietaryInformation()
        }
    }


    // MARK: - Section

    private func dietarySection(
        _ section: DietarySection,
        subtitle: String,
        badge: String? = nil,
        choices: [Choice],
        selectedIds: Binding<Set<UUID>>
    ) -> some View {

        DietaryCard(
            section: section,
            subtitle: subtitle,
            badge: badge
        ) {

            KinFlowLayout(spacing: KinSpacing.small) {

                ForEach(choices) { choice in

                    let isSelected =
                        selectedIds.wrappedValue.contains(choice.id)

                    Button {
                        toggle(
                            id: choice.id,
                            selectedIds: selectedIds
                        )
                    } label: {
                        DietaryChip(
                            title: choice.name,
                            tint: section.tint,
                            isSelected: isSelected,
                            showsCheck: true
                        )
                    }
                    .buttonStyle(.kinPressable)
                    .accessibilityAddTraits(isSelected ? .isSelected : [])
                    .accessibilityHint(
                        choice.isCustom && isSelected
                            ? "Added by you. Deselect and save to remove it."
                            : ""
                    )
                }

                // Typed in, not saved yet. Tapping takes it back out.
                ForEach(pending(section.customKind)) { item in

                    Button {
                        pendingItems.removeAll { $0.id == item.id }
                    } label: {
                        DietaryChip(
                            title: item.name,
                            tint: section.tint,
                            isSelected: true,
                            showsCheck: true
                        )
                    }
                    .buttonStyle(.kinPressable)
                    .accessibilityAddTraits(.isSelected)
                    .accessibilityHint("Not saved yet. Tap to remove.")
                }
            }

            addOwnField(
                section,
                choices: choices,
                selectedIds: selectedIds
            )
        }
    }


    // MARK: - Add Your Own

    private func addOwnField(
        _ section: DietarySection,
        choices: [Choice],
        selectedIds: Binding<Set<UUID>>
    ) -> some View {

        let kind = section.customKind

        let draft = Binding(
            get: { drafts[kind] ?? "" },
            set: { drafts[kind] = String($0.prefix(CustomDietaryText.maxLength)) }
        )

        let canAdd =
            !draft.wrappedValue
                .trimmingCharacters(in: .whitespaces)
                .isEmpty

        return HStack(
            spacing: KinSpacing.small
        ) {

            Image(systemName: KinIcons.add)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(KinColors.secondaryText)
                .accessibilityHidden(true)

            TextField(
                section.addPlaceholder,
                text: draft
            )
            .font(KinTypography.subheadline)
            .foregroundStyle(KinColors.primaryText)
            .textInputAutocapitalization(.words)
            .submitLabel(.done)
            .onSubmit {
                addOwn(kind, choices: choices, selectedIds: selectedIds)
            }

            if canAdd {
                Button("Add") {
                    addOwn(kind, choices: choices, selectedIds: selectedIds)
                }
                .font(KinTypography.subheadline.weight(.semibold))
                .foregroundStyle(section.tint)
            }
        }
        .padding(.horizontal, KinSpacing.medium)
        .padding(.vertical, KinSpacing.small)
        .overlay {
            Capsule()
                .strokeBorder(
                    KinColors.secondaryText.opacity(0.35),
                    style: StrokeStyle(lineWidth: 1, dash: [4, 3])
                )
        }
        .animation(.easeOut(duration: 0.15), value: canAdd)
    }

    /// Adds what was typed. If it's already in the list (built-in or
    /// the user's own), that one is selected instead of adding a copy.
    private func addOwn(
        _ kind: CustomDietaryItem.Kind,
        choices: [Choice],
        selectedIds: Binding<Set<UUID>>
    ) {

        let name =
            CustomDietaryText.cleaned(drafts[kind] ?? "")

        drafts[kind] = ""

        guard !name.isEmpty else {
            return
        }

        if let existing =
            CustomDietaryText.existingMatch(
                for: name,
                in: choices.map(\.name)
            ),
           let choice = choices.first(where: { $0.name == existing }) {

            selectedIds.wrappedValue.insert(choice.id)
            return
        }

        guard
            CustomDietaryText.existingMatch(
                for: name,
                in: pending(kind).map(\.name)
            ) == nil
        else {
            return
        }

        pendingItems.append(
            PendingItem(kind: kind, name: name)
        )
    }

    private func pending(
        _ kind: CustomDietaryItem.Kind
    ) -> [PendingItem] {
        pendingItems.filter { $0.kind == kind }
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


    // MARK: - Load

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

            async let loadedCustom = CustomDietaryService.fetchItems()

            let custom = try await loadedCustom

            // The user's own items are listed after the built-in ones
            // and start selected, since having one means it's on.
            allergens =
                try await loadedAllergens.map { Choice(id: $0.id, name: $0.name) }
                + custom.allergens.map { Choice(id: $0.id, name: $0.name, isCustom: true) }

            restrictions =
                try await loadedRestrictions.map { Choice(id: $0.id, name: $0.name) }
                + custom.restrictions.map { Choice(id: $0.id, name: $0.name, isCustom: true) }

            preferences =
                try await loadedPreferences.map { Choice(id: $0.id, name: $0.name) }
                + custom.preferences.map { Choice(id: $0.id, name: $0.name, isCustom: true) }

            selectedAllergenIds =
                Set(try await savedAllergens)
                    .union(custom.allergens.map(\.id))

            selectedRestrictionIds =
                Set(try await savedRestrictions)
                    .union(custom.restrictions.map(\.id))

            selectedPreferenceIds =
                Set(try await savedPreferences)
                    .union(custom.preferences.map(\.id))

            originalAllergenIds = selectedAllergenIds
            originalRestrictionIds = selectedRestrictionIds
            originalPreferenceIds = selectedPreferenceIds

            pendingItems = []

        } catch {
            errorMessage = error.localizedDescription
        }
    }


    // MARK: - Save

    @MainActor
    private func saveChanges() async {
        isSaving = true
        errorMessage = nil

        defer {
            isSaving = false
        }

        let customIds =
            Set(
                (allergens + restrictions + preferences)
                    .filter(\.isCustom)
                    .map(\.id)
            )

        do {
            let allergenChanges =
                DietaryEditChanges(
                    original: originalAllergenIds,
                    selected: selectedAllergenIds,
                    customIds: customIds
                )

            let restrictionChanges =
                DietaryEditChanges(
                    original: originalRestrictionIds,
                    selected: selectedRestrictionIds,
                    customIds: customIds
                )

            let preferenceChanges =
                DietaryEditChanges(
                    original: originalPreferenceIds,
                    selected: selectedPreferenceIds,
                    customIds: customIds
                )

            for id in allergenChanges.toAdd {
                try await DietaryService.addAllergen(id)
            }

            for id in allergenChanges.toRemove {
                try await DietaryService.removeAllergen(id)
            }

            for id in restrictionChanges.toAdd {
                try await DietaryService.addDietaryRestriction(id)
            }

            for id in restrictionChanges.toRemove {
                try await DietaryService.removeDietaryRestriction(id)
            }

            for id in preferenceChanges.toAdd {
                try await DietaryService.addDietaryPreference(id)
            }

            for id in preferenceChanges.toRemove {
                try await DietaryService.removeDietaryPreference(id)
            }

            // The user's own items: deselected ones are deleted, new
            // ones are created.
            for id in allergenChanges.customToDelete
                + restrictionChanges.customToDelete
                + preferenceChanges.customToDelete {
                try await CustomDietaryService.remove(id)
            }

            for item in pendingItems {
                try await CustomDietaryService.add(
                    item.kind,
                    name: item.name
                )
            }

            dismiss()

        } catch {
            errorMessage =
                "Some changes couldn't be saved. Please try again."

            print(
                "DIETARY PROFILE SAVE ERROR:",
                error.localizedDescription
            )

            // Show what actually saved.
            await loadDietaryInformation()
        }
    }
}


// MARK: - Changes

/// What saving one list needs to do. Built-in items are added to or
/// removed from the user's selections; the user's own items can only
/// be deleted (they're always on while they exist).
nonisolated struct DietaryEditChanges: Equatable {

    let toAdd: [UUID]
    let toRemove: [UUID]
    let customToDelete: [UUID]

    init(
        original: Set<UUID>,
        selected: Set<UUID>,
        customIds: Set<UUID>
    ) {
        let added = selected.subtracting(original)
        let removed = original.subtracting(selected)

        toAdd = added.subtracting(customIds).sorted { $0.uuidString < $1.uuidString }
        toRemove = removed.subtracting(customIds).sorted { $0.uuidString < $1.uuidString }
        customToDelete = removed.intersection(customIds).sorted { $0.uuidString < $1.uuidString }
    }
}

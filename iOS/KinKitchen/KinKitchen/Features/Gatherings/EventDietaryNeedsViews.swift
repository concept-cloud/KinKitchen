//
//  EventDietaryNeedsViews.swift
//  KinKitchen
//
//  Created by Greg Hudler on 10/15/26.
//

import SwiftUI

// MARK: - Look

extension CustomDietaryItem.Kind {

    /// Matches the Dietary Profile's colors and icons.
    var section: DietarySection {
        switch self {
        case .allergen: return .allergens
        case .restriction: return .restrictions
        case .preference: return .preferences
        }
    }

    var eventTitle: String {
        switch self {
        case .allergen: return "Allergies"
        case .restriction: return "Dietary Restrictions"
        case .preference: return "Preferences"
        }
    }

    var eventSubtitle: String {
        switch self {
        case .allergen: return "Ingredients that make someone sick."
        case .restriction: return "Foods someone doesn't eat."
        case .preference: return "Ingredients they'd rather skip."
        }
    }
}


nonisolated enum EventDietaryText {

    static func hint(for type: KinEventType?) -> String {
        type == .mealTrain
            ? "Cooking for someone who isn't on Kin Kitchen? Add their allergies and diet so every meal is safe."
            : "Allergies and diets everyone should cook around. Dishes are checked against them."
    }

    static func count(_ count: Int) -> String {
        count == 1 ? "1 need" : "\(count) needs"
    }
}


// MARK: - Chips

/// An event's needs as colored chips, allergens first.
struct EventDietaryNeedsChips: View {

    let needs: [EventDietaryNeed]

    var body: some View {
        KinFlowLayout(spacing: KinSpacing.small) {
            ForEach(needs.sortedForDisplay) { need in
                DietaryChip(
                    title: need.name,
                    tint: need.kind.section.tint
                )
                .accessibilityLabel("\(need.name), \(need.kind.eventTitle)")
            }
        }
    }
}


// MARK: - Form Field

/// The Dietary Needs row on Add Event and Edit Event. Opens the editor.
struct EventDietaryNeedsField: View {

    @Binding var needs: [EventDietaryNeed]
    var eventType: KinEventType?
    /// Off inside a card that already says "Dietary Needs".
    var showsTitle = true

    @State private var isEditing = false

    var body: some View {

        VStack(
            alignment: .leading,
            spacing: KinSpacing.small
        ) {

            HStack(alignment: .firstTextBaseline) {

                if showsTitle {
                    Text("Dietary Needs")
                        .font(KinTypography.headline)
                        .foregroundStyle(KinColors.primaryText)
                } else {
                    Text(EventDietaryText.hint(for: eventType))
                        .font(KinTypography.caption)
                        .foregroundStyle(KinColors.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                Button(needs.isEmpty ? "Add" : "Edit") {
                    isEditing = true
                }
                .font(KinTypography.callout)
                .foregroundStyle(KinColors.primary)
            }

            if showsTitle {
                Text(EventDietaryText.hint(for: eventType))
                    .font(KinTypography.caption)
                    .foregroundStyle(KinColors.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Button {
                isEditing = true
            } label: {
                Group {
                    if needs.isEmpty {
                        Label("No dietary needs added", systemImage: KinIcons.add)
                            .font(KinTypography.body)
                            .foregroundStyle(KinColors.secondaryText)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    } else {
                        EventDietaryNeedsChips(needs: needs)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(KinSpacing.medium)
                .background(
                    KinColors.surface,
                    in: RoundedRectangle(cornerRadius: KinRadius.medium)
                )
            }
            .buttonStyle(.kinPressable)
            .accessibilityLabel(
                needs.isEmpty
                    ? "Add dietary needs"
                    : "Dietary needs: " + needs.sortedForDisplay.map(\.name).joined(separator: ", ")
            )
            .accessibilityHint("Opens the dietary needs editor")
        }
        .sheet(isPresented: $isEditing) {
            EventDietaryNeedsEditor(needs: $needs)
        }
    }
}


// MARK: - Editor

/// Pick built-in allergies, restrictions and preferences, or type your
/// own. Changes go back to the form; the event saves them.
struct EventDietaryNeedsEditor: View {

    @Environment(\.dismiss) private var dismiss

    @Binding var needs: [EventDietaryNeed]

    @State private var draft: [EventDietaryNeed] = []
    @State private var catalog: [CustomDietaryItem.Kind: [EventDietaryNeed]] = [:]
    @State private var typed: [CustomDietaryItem.Kind: String] = [:]
    @State private var isLoading = true
    @State private var errorMessage: String?

    private let kinds: [CustomDietaryItem.Kind] = [.allergen, .restriction, .preference]

    var body: some View {

        NavigationStack {

            ScrollView {

                VStack(
                    alignment: .leading,
                    spacing: KinSpacing.large
                ) {

                    if isLoading {
                        KinLoadingView(size: .compact)
                            .frame(maxWidth: .infinity)
                            .padding(.top, KinSpacing.xLarge)
                    } else {

                        if let errorMessage {
                            Text(errorMessage)
                                .font(KinTypography.footnote)
                                .foregroundStyle(KinColors.error)
                        }

                        ForEach(kinds, id: \.self) { kind in
                            card(kind)
                        }
                    }
                }
                .padding(KinSpacing.large)
            }
            .background(KinColors.background)
            .navigationTitle("Dietary Needs")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        needs = draft.sortedForDisplay
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .sensoryFeedback(.selection, trigger: draft.count)
        }
        .task {
            draft = needs
            await loadCatalog()
        }
    }


    // MARK: Card

    private func card(
        _ kind: CustomDietaryItem.Kind
    ) -> some View {

        let section = kind.section
        let chosen = draft.of(kind)
        let builtIn = catalog[kind] ?? []
        let typedIn = chosen.filter(\.isCustom)

        return VStack(
            alignment: .leading,
            spacing: KinSpacing.medium
        ) {

            HStack(
                alignment: .top,
                spacing: KinSpacing.medium
            ) {

                Image(systemName: section.icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(section.tint)
                    .frame(width: 40, height: 40)
                    .background(
                        section.tint.opacity(0.15),
                        in: RoundedRectangle(cornerRadius: KinRadius.medium)
                    )
                    .accessibilityHidden(true)

                VStack(
                    alignment: .leading,
                    spacing: KinSpacing.xxSmall
                ) {
                    Text(kind.eventTitle)
                        .font(KinTypography.headline)
                        .foregroundStyle(KinColors.primaryText)
                        .accessibilityAddTraits(.isHeader)

                    Text(kind.eventSubtitle)
                        .font(KinTypography.footnote)
                        .foregroundStyle(KinColors.secondaryText)
                }
            }

            KinFlowLayout(spacing: KinSpacing.small) {

                ForEach(builtIn + typedIn) { need in

                    let isSelected = draft.contains(need)

                    Button {
                        toggle(need)
                    } label: {
                        DietaryChip(
                            title: need.name,
                            tint: section.tint,
                            isSelected: isSelected,
                            showsCheck: true
                        )
                    }
                    .buttonStyle(.kinPressable)
                    .accessibilityAddTraits(isSelected ? .isSelected : [])
                }
            }

            addOwnField(kind, builtIn: builtIn)
        }
        .padding(KinSpacing.large)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            KinColors.surface,
            in: RoundedRectangle(cornerRadius: KinRadius.large)
        )
        .kinCardShadow()
    }


    // MARK: Add Your Own

    private func addOwnField(
        _ kind: CustomDietaryItem.Kind,
        builtIn: [EventDietaryNeed]
    ) -> some View {

        let text = Binding(
            get: { typed[kind] ?? "" },
            set: { typed[kind] = String($0.prefix(CustomDietaryText.maxLength)) }
        )

        let canAdd = !text.wrappedValue.trimmingCharacters(in: .whitespaces).isEmpty

        return HStack(spacing: KinSpacing.small) {

            Image(systemName: KinIcons.add)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(KinColors.secondaryText)
                .accessibilityHidden(true)

            TextField(kind.section.addPlaceholder, text: text)
                .font(KinTypography.subheadline)
                .foregroundStyle(KinColors.primaryText)
                .textInputAutocapitalization(.words)
                .submitLabel(.done)
                .onSubmit {
                    addOwn(kind, builtIn: builtIn)
                }

            if canAdd {
                Button("Add") {
                    addOwn(kind, builtIn: builtIn)
                }
                .font(KinTypography.subheadline.weight(.semibold))
                .foregroundStyle(kind.section.tint)
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

    private func addOwn(
        _ kind: CustomDietaryItem.Kind,
        builtIn: [EventDietaryNeed]
    ) {
        let name = typed[kind] ?? ""
        typed[kind] = ""
        draft = EventDietaryDraft.adding(name, kind: kind, to: draft, builtIn: builtIn)
    }

    private func toggle(_ need: EventDietaryNeed) {
        if let index = draft.firstIndex(of: need) {
            draft.remove(at: index)
        } else {
            draft.append(need)
        }
    }


    // MARK: Load

    @MainActor
    private func loadCatalog() async {

        isLoading = true
        defer { isLoading = false }

        do {
            async let allergens = DietaryService.fetchAllergens()
            async let restrictions = DietaryService.fetchDietaryRestrictions()
            async let preferences = DietaryService.fetchDietaryPreferences()

            catalog = [
                .allergen: try await allergens.map {
                    EventDietaryNeed(kind: .allergen, catalogId: $0.id, name: $0.name)
                },
                .restriction: try await restrictions.map {
                    EventDietaryNeed(kind: .restriction, catalogId: $0.id, name: $0.name)
                },
                .preference: try await preferences.map {
                    EventDietaryNeed(kind: .preference, catalogId: $0.id, name: $0.name)
                }
            ]

        } catch {
            errorMessage = "Couldn't load the list. You can still type your own."
            print("EVENT DIETARY CATALOG ERROR:", error.localizedDescription)
        }
    }
}


/// Adding a typed-in item: tidied, and matched to a built-in item or
/// one already chosen instead of adding a copy.
nonisolated enum EventDietaryDraft {

    static func adding(
        _ typed: String,
        kind: CustomDietaryItem.Kind,
        to draft: [EventDietaryNeed],
        builtIn: [EventDietaryNeed]
    ) -> [EventDietaryNeed] {

        let name = CustomDietaryText.cleaned(typed)

        guard !name.isEmpty else {
            return draft
        }

        // Already chosen under this kind.
        if CustomDietaryText.existingMatch(
            for: name,
            in: draft.filter { $0.kind == kind }.map(\.name)
        ) != nil {
            return draft
        }

        // A built-in item with that name: choose it instead.
        if let match = CustomDietaryText.existingMatch(
            for: name,
            in: builtIn.map(\.name)
        ),
           let need = builtIn.first(where: { $0.name == match }) {
            return draft + [need]
        }

        return draft + [EventDietaryNeed(kind: kind, catalogId: nil, name: name)]
    }
}


// MARK: - Event Detail Card

/// The event's needs on Event Detail, for everyone who can see it.
struct EventDietaryNeedsCard: View {

    let needs: [EventDietaryNeed]
    var isHighlighted = false

    var body: some View {

        VStack(
            alignment: .leading,
            spacing: KinSpacing.medium
        ) {

            Text("Dietary Needs")
                .font(KinTypography.sectionTitle)
                .foregroundStyle(KinColors.primaryText)
                .kinChangeHighlight(isHighlighted)

            VStack(
                alignment: .leading,
                spacing: KinSpacing.medium
            ) {

                Label(
                    "Please cook around these. Dishes with a recipe are checked for you.",
                    systemImage: "exclamationmark.shield.fill"
                )
                .font(KinTypography.footnote)
                .foregroundStyle(KinColors.secondaryText)

                EventDietaryNeedsChips(needs: needs)
            }
            .padding(KinSpacing.large)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                KinColors.surface,
                in: RoundedRectangle(cornerRadius: KinRadius.large)
            )
        }
    }
}


// MARK: - Recipe Warning

/// What a dish's recipe conflicts with, under the recipe on Add Dish
/// and the dish's own page.
struct EventDietaryWarning: View {

    let result: RecipientRecipeDietaryCheckResult

    private var lines: [(name: String, ingredients: [String], tint: Color)] {
        result.allergenConflicts.map {
            ($0.allergen.name, $0.ingredientNames, CustomDietaryItem.Kind.allergen.section.tint)
        }
        + result.restrictionConflicts.map {
            ($0.restriction.name, $0.ingredientNames, CustomDietaryItem.Kind.restriction.section.tint)
        }
        + result.preferenceConflicts.map {
            ($0.preference.name, $0.ingredientNames, CustomDietaryItem.Kind.preference.section.tint)
        }
    }

    var body: some View {

        VStack(
            alignment: .leading,
            spacing: KinSpacing.small
        ) {

            Label(
                title,
                systemImage: result.hasConflict
                    ? "exclamationmark.triangle.fill"
                    : "checkmark.shield.fill"
            )
            .font(KinTypography.headline)
            .foregroundStyle(
                result.hasConflict ? KinColors.warning : KinColors.success
            )

            ForEach(lines, id: \.name) { line in
                (
                    Text(line.name).bold().foregroundStyle(line.tint)
                    + Text(": " + line.ingredients.joined(separator: ", "))
                        .foregroundStyle(KinColors.primaryText)
                )
                .font(KinTypography.subheadline)
                .fixedSize(horizontal: false, vertical: true)
            }

            if result.hasIncompleteInformation {
                Text("Couldn't check: \(result.unknownIngredients.joined(separator: ", ")). Please double-check these by hand.")
                    .font(KinTypography.footnote)
                    .foregroundStyle(KinColors.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(KinSpacing.medium)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            (result.hasConflict ? KinColors.warning : KinColors.success).opacity(0.1),
            in: RoundedRectangle(cornerRadius: KinRadius.medium)
        )
        .accessibilityElement(children: .combine)
    }

    private var title: String {
        if result.hasConflict {
            return "Conflicts with this event's dietary needs"
        }
        return result.hasIncompleteInformation
            ? "No known conflicts, but some ingredients couldn't be checked"
            : "No known conflicts with this event's dietary needs"
    }
}

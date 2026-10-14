//
//  OrganizeCookbookView.swift
//  KinKitchen
//
//  Created by Greg Hudler on 10/14/26.
//

import SwiftUI

// MARK: - Organize Cookbook View

/// One place to organize a cookbook.
///
/// - Recipes: drag a recipe within or between sections, or select
///   several and move them together.
/// - Sections: add, rename (tap), reorder (drag) and delete.
///
/// Every change saves right away. Deleting a section moves its
/// recipes to Unsorted; no recipes are ever deleted here.
struct OrganizeCookbookView: View {

    enum Mode: String, CaseIterable, Identifiable {
        case recipes = "Recipes"
        case sections = "Sections"
        var id: String { rawValue }
    }

    @Environment(\.dismiss) private var dismiss

    let cookbookId: UUID
    let recipesById: [UUID: Recipe]

    @State private var mode: Mode = .recipes
    @State private var sections: [CookbookSection]
    @State private var layout: CookbookLayout
    @State private var selection = Set<UUID>()
    @State private var filter = OrganizeFilter()
    private let featuredRecipeIds: Set<UUID>

    @State private var isSaving = false
    @State private var errorMessage: String?

    @State private var isShowingNewSection = false
    @State private var sectionToRename: CookbookSection?
    @State private var sectionToDelete: CookbookSection?
    @State private var nameDraft = ""

    init(
        cookbookId: UUID,
        sections: [CookbookSection],
        relationships: [CookbookRecipe],
        recipesById: [UUID: Recipe]
    ) {
        self.cookbookId = cookbookId
        self.recipesById = recipesById
        self.featuredRecipeIds =
            Set(relationships.filter(\.isFeatured).map(\.recipeId))
        _sections = State(initialValue: sections)
        _layout = State(
            initialValue: CookbookLayout(
                sectionIds: sections.map(\.id),
                relationships: relationships.filter {
                    recipesById[$0.recipeId] != nil
                }
            )
        )
    }


    var body: some View {

        NavigationStack {

            VStack(spacing: 0) {

                Picker("Organize", selection: $mode) {
                    ForEach(Mode.allCases) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, KinSpacing.large)
                .padding(.vertical, KinSpacing.small)

                if let errorMessage {
                    Text(errorMessage)
                        .font(KinTypography.caption)
                        .foregroundStyle(KinColors.error)
                        .padding(.horizontal, KinSpacing.large)
                }

                switch mode {
                case .recipes:
                    filterBar
                    recipesList
                case .sections:
                    sectionsList
                }
            }
            .background(KinColors.background)
            .environment(\.editMode, .constant(.active))
            .navigationTitle("Organize Cookbook")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {

                ToolbarItem(placement: .confirmationAction) {
                    if isSaving {
                        ProgressView()
                    } else {
                        Button("Done") {
                            dismiss()
                        }
                        .fontWeight(.semibold)
                        .foregroundStyle(KinColors.primary)
                    }
                }

                if mode == .recipes {
                    ToolbarItemGroup(placement: .bottomBar) {
                        batchBar
                    }
                }
            }
            .onChange(of: mode) {
                selection.removeAll()
            }
            .alert(
                "New Section",
                isPresented: $isShowingNewSection
            ) {
                TextField("e.g. Desserts", text: $nameDraft)
                    .textInputAutocapitalization(.words)

                Button("Add") {
                    Task { await addSection() }
                }

                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Group recipes in this cookbook, like Appetizers or Family Favorites.")
            }
            .alert(
                "Rename Section",
                isPresented: Binding(
                    get: { sectionToRename != nil },
                    set: { if !$0 { sectionToRename = nil } }
                ),
                presenting: sectionToRename
            ) { section in
                TextField("Section name", text: $nameDraft)
                    .textInputAutocapitalization(.words)

                Button("Save") {
                    Task { await rename(section) }
                }

                Button("Cancel", role: .cancel) {}
            }
            .alert(
                "Delete \"\(sectionToDelete?.name ?? "Section")\"?",
                isPresented: Binding(
                    get: { sectionToDelete != nil },
                    set: { if !$0 { sectionToDelete = nil } }
                ),
                presenting: sectionToDelete
            ) { section in
                Button("Cancel", role: .cancel) {}

                Button("Delete", role: .destructive) {
                    Task { await delete(section) }
                }
            } message: { _ in
                Text("Its recipes move to Unsorted. No recipes are deleted.")
            }
        }
    }


    // MARK: - Recipes Mode

    private var recipesList: some View {

        List(selection: $selection) {

            if visibleRows.isEmpty {
                Text("No recipes match these filters.")
                    .font(KinTypography.body)
                    .foregroundStyle(KinColors.secondaryText)
                    .listRowBackground(Color.clear)
                    .selectionDisabled()
            }

            ForEach(visibleRows) { row in

                switch row {

                case .heading(let sectionId):
                    Text(name(of: sectionId).uppercased())
                        .font(KinTypography.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(KinColors.secondaryText)
                        .padding(.top, KinSpacing.small)
                        .listRowBackground(Color.clear)
                        .selectionDisabled()
                        .moveDisabled(true)
                        .accessibilityAddTraits(.isHeader)

                case .recipe(let recipeId):
                    recipeRow(recipeId)
                        .tag(recipeId)
                        // Drag positions only make sense in the full list.
                        .moveDisabled(isFiltering)
                }
            }
            .onMove { offsets, destination in
                guard !isFiltering else {
                    return
                }

                let updated =
                    layout.moving(
                        rowsAt: offsets,
                        to: destination
                    )
                Task { await apply(updated) }
            }
        }
        .scrollContentBackground(.hidden)
        .disabled(isSaving)
        // Never move recipes you can't see.
        .onChange(of: filter) {
            selection.formIntersection(visibleRecipeIds)
        }
    }

    private var isFiltering: Bool {
        filter.isActive
    }

    /// All rows, or only matching recipes under their section headings
    /// (sections with no matches are hidden).
    private var visibleRows: [CookbookLayout.Row] {
        guard isFiltering else {
            return layout.rows
        }

        return layout.groups.flatMap { group -> [CookbookLayout.Row] in
            let matches =
                group.recipeIds.filter { id in
                    filter.matches(
                        category: recipesById[id]?.category,
                        sectionId: group.sectionId,
                        isFeatured: featuredRecipeIds.contains(id)
                    )
                }

            return matches.isEmpty
                ? []
                : [.heading(group.sectionId)] + matches.map(CookbookLayout.Row.recipe)
        }
    }


    // MARK: - Filter Bar

    private var filterBar: some View {

        ScrollView(.horizontal, showsIndicators: false) {

            HStack(spacing: KinSpacing.small) {

                // Section: one at a time.
                Menu {
                    Button {
                        filter.section = nil
                    } label: {
                        checkLabel("All Sections", isOn: filter.section == nil)
                    }

                    Divider()

                    ForEach(layout.groups, id: \.sectionId) { group in
                        Button {
                            filter.section = .some(group.sectionId)
                        } label: {
                            checkLabel(
                                name(of: group.sectionId),
                                isOn: filter.section == .some(group.sectionId)
                            )
                        }
                    }
                } label: {
                    filterChip(
                        filter.section.map { name(of: $0) } ?? "Section",
                        isOn: filter.section != nil,
                        showsMenu: true
                    )
                }

                // Categories: any of the chosen ones.
                Menu {
                    ForEach(RecipeCategory.allCases) { category in
                        Button {
                            filter.toggle(category)
                        } label: {
                            checkLabel(
                                category.rawValue,
                                isOn: filter.categories.contains(category)
                            )
                        }
                    }
                } label: {
                    filterChip(
                        filter.categoryTitle,
                        isOn: !filter.categories.isEmpty,
                        showsMenu: true
                    )
                }

                Button {
                    filter.featuredOnly.toggle()
                } label: {
                    filterChip(
                        "Featured",
                        isOn: filter.featuredOnly,
                        showsMenu: false
                    )
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(filter.featuredOnly ? .isSelected : [])

                if filter.isActive {
                    Button("Clear") {
                        filter = OrganizeFilter()
                    }
                    .font(KinTypography.subheadline)
                    .foregroundStyle(KinColors.primary)
                }
            }
            .padding(.horizontal, KinSpacing.large)
            .padding(.vertical, KinSpacing.xSmall)
        }
    }

    private func filterChip(
        _ title: String,
        isOn: Bool,
        showsMenu: Bool
    ) -> some View {

        HStack(spacing: KinSpacing.xxSmall) {
            Text(title)
                .lineLimit(1)

            if showsMenu {
                Image(systemName: KinIcons.dropdown)
                    .font(.system(size: 10, weight: .bold))
            }
        }
        .font(KinTypography.subheadline)
        .foregroundStyle(isOn ? .white : KinColors.primaryText)
        .padding(.horizontal, KinSpacing.medium)
        .padding(.vertical, KinSpacing.small)
        .background(isOn ? KinColors.primary : KinColors.surface)
        .clipShape(Capsule())
    }

    @ViewBuilder
    private func checkLabel(
        _ title: String,
        isOn: Bool
    ) -> some View {
        if isOn {
            Label(title, systemImage: KinIcons.check)
        } else {
            Text(title)
        }
    }

    private var visibleRecipeIds: [UUID] {
        visibleRows.compactMap { row in
            if case .recipe(let id) = row {
                return id
            }
            return nil
        }
    }

    private func recipeRow(
        _ recipeId: UUID
    ) -> some View {

        let recipe = recipesById[recipeId]

        return HStack(spacing: KinSpacing.medium) {

            KinStorageImage(
                bucket: "recipe-photos",
                path: recipe?.photoPath
            )
            .frame(width: 40, height: 40)
            .clipShape(
                RoundedRectangle(cornerRadius: KinRadius.small)
            )

            Text(recipe?.name ?? "Recipe")
                .font(KinTypography.body)
                .foregroundStyle(KinColors.primaryText)
                .lineLimit(2)
        }
        .listRowBackground(KinColors.surface)
    }

    /// "Move 3 to…" for the selected recipes.
    @ViewBuilder
    private var batchBar: some View {

        Button(
            selection.isEmpty ? "Select All" : "Clear"
        ) {
            if selection.isEmpty {
                // Only what's showing, so "filter, select all, move"
                // works in one go.
                selection = Set(visibleRecipeIds)
            } else {
                selection.removeAll()
            }
        }
        .disabled(isSaving)

        Spacer()

        Menu {
            ForEach(layout.groups, id: \.sectionId) { group in
                Button(name(of: group.sectionId)) {
                    let updated =
                        layout.moving(
                            selection,
                            to: group.sectionId
                        )
                    Task {
                        await apply(updated)
                        selection.removeAll()
                    }
                }
            }
        } label: {
            Label(
                selection.isEmpty
                    ? "Select recipes to move"
                    : "Move \(selection.count) to…",
                systemImage: "folder"
            )
            .labelStyle(.titleAndIcon)
            .fontWeight(.semibold)
        }
        .disabled(selection.isEmpty || isSaving)
    }


    // MARK: - Sections Mode

    private var sectionsList: some View {

        List {

            Section {

                ForEach(sections) { section in

                    Button {
                        nameDraft = section.name
                        sectionToRename = section
                    } label: {
                        HStack {
                            Text(section.name)
                                .font(KinTypography.body)
                                .foregroundStyle(KinColors.primaryText)
                                .lineLimit(2)

                            Spacer()

                            Text("\(recipeCount(in: section.id))")
                                .font(KinTypography.footnote)
                                .foregroundStyle(KinColors.secondaryText)

                            Image(systemName: KinIcons.edit)
                                .font(.footnote)
                                .foregroundStyle(KinColors.secondaryText)
                                .accessibilityHidden(true)
                        }
                    }
                    .accessibilityHint("Renames the section")
                }
                .onMove { offsets, destination in
                    moveSections(from: offsets, to: destination)
                }
                .onDelete { offsets in
                    sectionToDelete = offsets.first.map { sections[$0] }
                }

                Button {
                    nameDraft = ""
                    isShowingNewSection = true
                } label: {
                    Label("Add Section", systemImage: "plus.circle.fill")
                        .font(KinTypography.headline)
                        .foregroundStyle(KinColors.primary)
                }

            } footer: {
                Text("Tap a section to rename it. Drag ≡ to reorder. Deleting a section moves its recipes to Unsorted; no recipes are deleted.")
                    .font(KinTypography.caption)
            }
        }
        .scrollContentBackground(.hidden)
        .disabled(isSaving)
    }


    // MARK: - Helpers

    private func name(of sectionId: UUID?) -> String {
        guard let sectionId else {
            return "Unsorted"
        }
        return sections.first { $0.id == sectionId }?.name ?? "Section"
    }

    private func recipeCount(in sectionId: UUID) -> Int {
        layout.groups.first { $0.sectionId == sectionId }?.recipeIds.count ?? 0
    }


    // MARK: - Saving

    /// Shows the new layout at once, then saves only the sections that
    /// changed. On failure, goes back to what's stored.
    @MainActor
    private func apply(_ updated: CookbookLayout) async {
        let previous = layout

        guard updated != previous else {
            return
        }

        withAnimation {
            layout = updated
        }

        await save("The recipes couldn't be moved.") {
            do {
                for group in updated.changedGroups(since: previous) {
                    try await CookbookService.reorderRecipes(
                        group.recipeIds,
                        in: group.sectionId,
                        cookbookId: cookbookId
                    )
                }
            } catch {
                withAnimation {
                    layout = previous
                }
                throw error
            }
        }
    }

    @MainActor
    private func addSection() async {
        await save("The section couldn't be added.") {
            let section =
                try await CookbookService.createSection(
                    name: nameDraft,
                    in: cookbookId,
                    after: sections
                )
            sections.append(section)
            layout = layout.addingSection(section.id)
        }
    }

    @MainActor
    private func rename(_ section: CookbookSection) async {
        await save("The section couldn't be renamed.") {
            let updated =
                try await CookbookService.renameSection(
                    section,
                    to: nameDraft
                )
            if let index = sections.firstIndex(where: { $0.id == section.id }) {
                sections[index] = updated
            }
        }
    }

    @MainActor
    private func delete(_ section: CookbookSection) async {
        await save("The section couldn't be deleted.") {
            try await CookbookService.deleteSection(section)
            sections.removeAll { $0.id == section.id }
            layout = layout.removingSection(section.id)
        }
    }

    @MainActor
    private func moveSections(
        from offsets: IndexSet,
        to destination: Int
    ) {
        let previous = sections

        sections.move(fromOffsets: offsets, toOffset: destination)
        layout = layout.orderingSections(sections.map(\.id))

        Task {
            await save("The new order couldn't be saved.") {
                do {
                    try await CookbookService.reorderSections(
                        sections.map(\.id),
                        cookbookId: cookbookId
                    )
                } catch {
                    sections = previous
                    layout = layout.orderingSections(previous.map(\.id))
                    throw error
                }
            }
        }
    }

    /// Runs one change, showing a friendly message if it fails.
    @MainActor
    private func save(
        _ fallback: String,
        _ change: () async throws -> Void
    ) async {
        isSaving = true
        errorMessage = nil

        defer {
            isSaving = false
        }

        do {
            try await change()
        } catch let error as CookbookServiceError {
            errorMessage =
                error.errorDescription ?? "\(fallback) Please try again."
        } catch {
            errorMessage = "\(fallback) Please try again."

            print(
                "ORGANIZE COOKBOOK ERROR:",
                error.localizedDescription
            )
        }
    }
}


// MARK: - Organize Filter

/// What the Organize recipes list shows: one section (or all), any of
/// the chosen categories, and optionally only featured recipes.
nonisolated struct OrganizeFilter: Equatable {

    /// nil = all sections; .some(nil) = Unsorted.
    var section: UUID?? = nil
    var categories: Set<RecipeCategory> = []
    var featuredOnly = false

    var isActive: Bool {
        section != nil || !categories.isEmpty || featuredOnly
    }

    var categoryTitle: String {
        switch categories.count {
        case 0:
            return "Category"
        case 1:
            return categories.first!.rawValue
        default:
            return "\(categories.count) Categories"
        }
    }

    mutating func toggle(_ category: RecipeCategory) {
        if categories.contains(category) {
            categories.remove(category)
        } else {
            categories.insert(category)
        }
    }

    func matches(
        category: String?,
        sectionId: UUID?,
        isFeatured: Bool
    ) -> Bool {

        if let section, section != sectionId {
            return false
        }

        if !categories.isEmpty {
            guard
                let recipeCategory = RecipeCategory(matching: category),
                categories.contains(recipeCategory)
            else {
                return false
            }
        }

        return !featuredOnly || isFeatured
    }
}

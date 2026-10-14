//
//  EditCookbookSectionsView.swift
//  KinKitchen
//
//  Created by Greg Hudler on 10/14/26.
//

import SwiftUI

// MARK: - Edit Cookbook Sections View

/// One place to manage a cookbook's sections: add, rename (tap),
/// reorder (drag) and delete (swipe or ⊖). Each change saves right
/// away. Deleting a section moves its recipes to Unsorted.
struct EditCookbookSectionsView: View {

    @Environment(\.dismiss) private var dismiss

    let cookbookId: UUID

    @State private var sections: [CookbookSection]
    @State private var isSaving = false
    @State private var errorMessage: String?

    @State private var isShowingNewSection = false
    @State private var sectionToRename: CookbookSection?
    @State private var sectionToDelete: CookbookSection?
    @State private var nameDraft = ""

    init(
        cookbookId: UUID,
        sections: [CookbookSection]
    ) {
        self.cookbookId = cookbookId
        _sections = State(initialValue: sections)
    }


    var body: some View {

        NavigationStack {

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

                                Image(systemName: KinIcons.edit)
                                    .font(.footnote)
                                    .foregroundStyle(KinColors.secondaryText)
                                    .accessibilityHidden(true)
                            }
                        }
                        .accessibilityHint("Renames the section")
                    }
                    .onMove { offsets, destination in
                        move(
                            from: offsets,
                            to: destination
                        )
                    }
                    .onDelete { offsets in
                        sectionToDelete =
                            offsets.first.map { sections[$0] }
                    }

                    Button {
                        nameDraft = ""
                        isShowingNewSection = true
                    } label: {
                        Label(
                            "Add Section",
                            systemImage: "plus.circle.fill"
                        )
                        .font(KinTypography.headline)
                        .foregroundStyle(KinColors.primary)
                    }

                } footer: {

                    VStack(
                        alignment: .leading,
                        spacing: KinSpacing.small
                    ) {
                        Text("Tap a section to rename it. Drag ≡ to reorder. Deleting a section moves its recipes to Unsorted; no recipes are deleted.")

                        if let errorMessage {
                            Text(errorMessage)
                                .foregroundStyle(KinColors.error)
                        }
                    }
                    .font(KinTypography.caption)
                }
            }
            .environment(\.editMode, .constant(.active))
            .disabled(isSaving)
            .navigationTitle("Edit Sections")
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
            }
            // MARK: Add
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
            // MARK: Rename
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
            // MARK: Delete
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


    // MARK: - Saving

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
        }
    }

    @MainActor
    private func rename(
        _ section: CookbookSection
    ) async {

        await save("The section couldn't be renamed.") {
            let updated =
                try await CookbookService.renameSection(
                    section,
                    to: nameDraft
                )

            if let index =
                sections.firstIndex(where: { $0.id == section.id }) {
                sections[index] = updated
            }
        }
    }

    @MainActor
    private func delete(
        _ section: CookbookSection
    ) async {

        await save("The section couldn't be deleted.") {
            try await CookbookService.deleteSection(section)
            sections.removeAll { $0.id == section.id }
        }
    }

    @MainActor
    private func move(
        from offsets: IndexSet,
        to destination: Int
    ) {
        let previous = sections

        sections.move(
            fromOffsets: offsets,
            toOffset: destination
        )

        Task {
            await save("The new order couldn't be saved.") {
                do {
                    try await CookbookService.reorderSections(
                        sections.map(\.id),
                        cookbookId: cookbookId
                    )
                } catch {
                    // Show the order that's actually stored.
                    sections = previous
                    throw error
                }
            }
        }
    }

    /// Runs one change, showing a friendly message if it fails.
    /// Validation errors (e.g. a blank name) explain themselves.
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
        } catch let error as LocalizedError {
            errorMessage =
                error.errorDescription ?? "\(fallback) Please try again."
        } catch {
            errorMessage = "\(fallback) Please try again."

            print(
                "COOKBOOK SECTIONS ERROR:",
                error.localizedDescription
            )
        }
    }
}

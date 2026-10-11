//
//  ReorderCookbookSectionsView.swift
//  KinKitchen
//
//  Created by Greg Hudler on 10/11/26.
//

import SwiftUI

// MARK: - Reorder Cookbook Sections View

/// Drag sections into the order they should appear in the cookbook
/// tabs and preview. Recipes stay in their sections.
struct ReorderCookbookSectionsView: View {

    @Environment(\.dismiss) private var dismiss

    let cookbookId: UUID
    let onSaved: ([CookbookSection]) -> Void

    @State private var sections: [CookbookSection]
    @State private var isSaving = false
    @State private var errorMessage: String?

    init(
        cookbookId: UUID,
        sections: [CookbookSection],
        onSaved: @escaping ([CookbookSection]) -> Void
    ) {
        self.cookbookId = cookbookId
        self.onSaved = onSaved
        _sections = State(initialValue: sections)
    }


    var body: some View {

        NavigationStack {

            List {

                Section {
                    ForEach(sections) { section in
                        Text(section.name)
                            .font(KinTypography.body)
                            .foregroundStyle(KinColors.primaryText)
                            .lineLimit(2)
                    }
                    .onMove { offsets, destination in
                        sections.move(
                            fromOffsets: offsets,
                            toOffset: destination
                        )
                    }
                } footer: {
                    VStack(alignment: .leading, spacing: KinSpacing.small) {
                        Text("Drag sections into the order you want. Recipes stay in their sections.")

                        if let errorMessage {
                            Text(errorMessage)
                                .foregroundStyle(KinColors.error)
                        }
                    }
                    .font(KinTypography.caption)
                }
            }
            .environment(\.editMode, .constant(.active))
            .navigationTitle("Reorder Sections")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {

                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .disabled(isSaving)
                }

                ToolbarItem(placement: .confirmationAction) {
                    if isSaving {
                        ProgressView()
                    } else {
                        Button("Save") {
                            Task {
                                await save()
                            }
                        }
                        .foregroundStyle(KinColors.primary)
                    }
                }
            }
        }
    }


    @MainActor
    private func save() async {

        isSaving = true
        errorMessage = nil

        defer {
            isSaving = false
        }

        do {
            try await CookbookService.reorderSections(
                sections.map(\.id),
                cookbookId: cookbookId
            )

            onSaved(
                sections.enumerated().map { position, section in
                    var updated = section
                    updated.sortOrder = position
                    return updated
                }
            )

            dismiss()

        } catch {
            errorMessage =
                "The new order couldn't be saved. Please try again."

            print(
                "COOKBOOK SECTION REORDER ERROR:",
                error.localizedDescription
            )
        }
    }
}

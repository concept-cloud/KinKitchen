//
//  CreateCookbookView.swift
//  KinKitchen
//
//  Created by Greg Hudler on 9/23/26.
//

import SwiftUI

struct CreateCookbookView: View {

    @Environment(\.dismiss) private var dismiss

    let onCreated: (Cookbook) -> Void

    @State private var name = ""
    @State private var description = ""
    @State private var isSaving = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ZStack {
                KinColors.background
                    .ignoresSafeArea()

                ScrollView {
                    VStack(
                        alignment: .leading,
                        spacing: KinSpacing.xLarge
                    ) {
                        cookbookPreview
                        cookbookInformation

                        if let errorMessage {
                            errorCard(errorMessage)
                        }
                    }
                    .padding(KinSpacing.large)
                }
            }
            .navigationTitle("Create Cookbook")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(
                    placement: .cancellationAction
                ) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .disabled(isSaving)
                }

                ToolbarItem(
                    placement: .confirmationAction
                ) {
                    Button("Save") {
                        Task {
                            await saveCookbook()
                        }
                    }
                    .fontWeight(.semibold)
                    .disabled(
                        !canSave || isSaving
                    )
                }
            }
            .interactiveDismissDisabled(isSaving)
        }
    }
}

// MARK: - Preview

private extension CreateCookbookView {

    var cookbookPreview: some View {
        VStack(
            spacing: KinSpacing.medium
        ) {
            ZStack {
                RoundedRectangle(
                    cornerRadius: KinRadius.medium
                )
                .fill(
                    KinColors.primary.opacity(0.12)
                )

                Image(
                    systemName: KinIcons.cookbooks
                )
                .font(
                    .system(
                        size: 42,
                        weight: .semibold
                    )
                )
                .foregroundStyle(
                    KinColors.primary
                )
            }
            .frame(
                width: 120,
                height: 120
            )

            Text(
                cleanName.isEmpty
                    ? "New Cookbook"
                    : cleanName
            )
            .font(KinTypography.title)
            .foregroundStyle(
                KinColors.primaryText
            )
            .multilineTextAlignment(.center)

            Text("Private Cookbook")
                .font(KinTypography.body)
                .foregroundStyle(
                    KinColors.secondaryText
                )
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, KinSpacing.medium)
    }
}

// MARK: - Cookbook Information

private extension CreateCookbookView {

    var cookbookInformation: some View {
        VStack(
            alignment: .leading,
            spacing: KinSpacing.medium
        ) {
            Text("Cookbook Information")
                .font(KinTypography.headline)
                .foregroundStyle(
                    KinColors.primaryText
                )

            VStack(
                alignment: .leading,
                spacing: KinSpacing.small
            ) {
                Text("Name")
                    .font(KinTypography.body)
                    .foregroundStyle(
                        KinColors.primaryText
                    )

                TextField(
                    "Family Favorites",
                    text: $name
                )
                .textInputAutocapitalization(
                    .words
                )
                .submitLabel(.done)
                .padding(KinSpacing.medium)
                .background(KinColors.surface)
                .clipShape(
                    RoundedRectangle(
                        cornerRadius:
                            KinRadius.medium
                    )
                )
            }

            VStack(
                alignment: .leading,
                spacing: KinSpacing.small
            ) {
                Text("Description")
                    .font(KinTypography.body)
                    .foregroundStyle(
                        KinColors.primaryText
                    )

                TextField(
                    "Add a description...",
                    text: $description,
                    axis: .vertical
                )
                .lineLimit(4...8)
                .padding(KinSpacing.medium)
                .background(KinColors.surface)
                .clipShape(
                    RoundedRectangle(
                        cornerRadius:
                            KinRadius.medium
                    )
                )

                Text("Optional")
                    .font(KinTypography.caption)
                    .foregroundStyle(
                        KinColors.secondaryText
                    )
            }
        }
    }
}

// MARK: - Error

private extension CreateCookbookView {

    func errorCard(
        _ message: String
    ) -> some View {
        HStack(
            alignment: .top,
            spacing: KinSpacing.medium
        ) {
            Image(
                systemName:
                    "exclamationmark.triangle.fill"
            )
            .foregroundStyle(
                KinColors.error
            )

            VStack(
                alignment: .leading,
                spacing: KinSpacing.xSmall
            ) {
                Text("Unable to Create Cookbook")
                    .font(KinTypography.headline)
                    .foregroundStyle(
                        KinColors.primaryText
                    )

                Text(message)
                    .font(KinTypography.body)
                    .foregroundStyle(
                        KinColors.secondaryText
                    )
            }

            Spacer()
        }
        .padding(KinSpacing.medium)
        .background(KinColors.surface)
        .clipShape(
            RoundedRectangle(
                cornerRadius: KinRadius.medium
            )
        )
    }
}

// MARK: - Validation

private extension CreateCookbookView {

    var cleanName: String {
        name.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
    }

    var canSave: Bool {
        !cleanName.isEmpty
    }
}

// MARK: - Save

private extension CreateCookbookView {

    @MainActor
    func saveCookbook() async {
        guard canSave else {
            return
        }

        isSaving = true
        errorMessage = nil

        do {
            let cookbook =
                try await CookbookService
                    .createCookbook(
                        name: cleanName,
                        description: description,
                        coverPath: nil
                    )

            onCreated(cookbook)

            isSaving = false
            dismiss()
        } catch is CancellationError {
            isSaving = false
        } catch {
            errorMessage =
                error.localizedDescription

            isSaving = false
        }
    }
}

#Preview {
    CreateCookbookView { _ in }
}

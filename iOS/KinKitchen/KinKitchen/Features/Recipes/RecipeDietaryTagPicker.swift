//
//  RecipeDietaryTagPicker.swift
//  KinKitchen
//
//  Created by Greg Hudler on 10/4/26.
//

import SwiftUI

// MARK: - Recipe Dietary Tag Picker

/// Lets a recipe owner mark the recipe with existing dietary
/// restrictions (Vegan, Halal, ...). Used by Add and Edit Recipe.
struct RecipeDietaryTagPicker: View {

    @Binding var selection: Set<UUID>

    @State private var restrictions: [DietaryRestriction] = []
    @State private var failedToLoad = false


    var body: some View {

        VStack(
            alignment: .leading,
            spacing: KinSpacing.small
        ) {

            if failedToLoad {

                Text(
                    "Dietary options couldn't be loaded."
                )
                .font(
                    KinTypography.caption
                )
                .foregroundStyle(
                    KinColors.secondaryText
                )

            } else {

                LazyVGrid(
                    columns: [
                        GridItem(
                            .adaptive(
                                minimum: 100
                            ),
                            spacing: KinSpacing.small
                        )
                    ],
                    alignment: .leading,
                    spacing: KinSpacing.small
                ) {

                    ForEach(restrictions) { restriction in

                        tagChip(
                            restriction
                        )
                    }
                }

                Text(
                    "Ingredients are still checked. A tag never hides a known conflict."
                )
                .font(
                    KinTypography.caption
                )
                .foregroundStyle(
                    KinColors.secondaryText
                )
            }
        }
        .task {
            await loadRestrictions()
        }
    }


    private func tagChip(
        _ restriction: DietaryRestriction
    ) -> some View {

        let isSelected =
            selection.contains(
                restriction.id
            )

        return Button {

            if isSelected {
                selection.remove(
                    restriction.id
                )
            } else {
                selection.insert(
                    restriction.id
                )
            }

        } label: {

            Text(
                restriction.name
            )
            .font(
                KinTypography.caption
            )
            .foregroundStyle(
                isSelected
                    ? .white
                    : KinColors.primaryText
            )
            .frame(
                maxWidth: .infinity
            )
            .padding(
                .vertical,
                KinSpacing.small
            )
            .background(
                isSelected
                    ? KinColors.primary
                    : KinColors.background
            )
            .clipShape(
                Capsule()
            )
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(
            isSelected
                ? .isSelected
                : []
        )
    }


    @MainActor
    private func loadRestrictions() async {

        do {
            restrictions =
                try await DietaryService
                    .fetchDietaryRestrictions()
        } catch {
            if !(error is CancellationError) {
                failedToLoad = true

                print(
                    "RECIPE DIETARY TAG LOAD ERROR:",
                    error.localizedDescription
                )
            }
        }
    }
}

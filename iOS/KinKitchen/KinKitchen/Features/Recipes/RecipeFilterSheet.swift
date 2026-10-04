//
//  RecipeFilterSheet.swift
//  KinKitchen
//
//  Created by Greg Hudler on 10/4/26.
//

import SwiftUI

// MARK: - Recipe Filter Sheet

struct RecipeFilterSheet: View {

    @Environment(\.dismiss) private var dismiss

    @Binding var criteria: RecipeDiscoveryCriteria

    let restrictions: [DietaryRestriction]

    let allergens: [Allergen]


    var body: some View {

        NavigationStack {

            ScrollView {

                VStack(
                    alignment: .leading,
                    spacing: KinSpacing.xLarge
                ) {

                    categorySection

                    restrictionSection

                    allergenSection
                }
                .padding(
                    KinSpacing.large
                )
            }
            .background(
                KinColors.background
                    .ignoresSafeArea()
            )
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {

                // Clears filters only; search is left alone here
                // since the search bar isn't in this sheet.
                ToolbarItem(
                    placement: .cancellationAction
                ) {

                    Button("Clear") {
                        criteria.categories = []
                        criteria.restrictionIds = []
                        criteria.allergenIds = []
                    }
                    .foregroundStyle(
                        KinColors.primary
                    )
                    .disabled(
                        !criteria.hasActiveFilters
                    )
                }

                ToolbarItem(
                    placement: .confirmationAction
                ) {

                    Button("Done") {
                        dismiss()
                    }
                    .foregroundStyle(
                        KinColors.primary
                    )
                }
            }
        }
        .presentationDetents(
            [.medium, .large]
        )
    }
}

// MARK: - Category

private extension RecipeFilterSheet {

    var categorySection: some View {

        VStack(
            alignment: .leading,
            spacing: KinSpacing.medium
        ) {

            Text("Category")
                .font(
                    KinTypography.headline
                )
                .foregroundStyle(
                    KinColors.primaryText
                )

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

                ForEach(
                    RecipeCategory.allCases
                ) { category in

                    filterChip(
                        title: category.rawValue,
                        isSelected:
                            criteria.categories.contains(
                                category
                            )
                    ) {

                        if criteria.categories.contains(
                            category
                        ) {
                            criteria.categories.remove(
                                category
                            )
                        } else {
                            criteria.categories.insert(
                                category
                            )
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Dietary Restrictions

private extension RecipeFilterSheet {

    var restrictionSection: some View {

        VStack(
            alignment: .leading,
            spacing: KinSpacing.medium
        ) {

            Text("Dietary Restrictions")
                .font(
                    KinTypography.headline
                )
                .foregroundStyle(
                    KinColors.primaryText
                )

            if restrictions.isEmpty {

                Text(
                    "Dietary restrictions couldn't be loaded."
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

                    ForEach(
                        restrictions
                    ) { restriction in

                        filterChip(
                            title: restriction.name,
                            isSelected:
                                criteria.restrictionIds
                                    .contains(
                                        restriction.id
                                    )
                        ) {

                            if criteria.restrictionIds
                                .contains(
                                    restriction.id
                                ) {
                                criteria.restrictionIds
                                    .remove(
                                        restriction.id
                                    )
                            } else {
                                criteria.restrictionIds
                                    .insert(
                                        restriction.id
                                    )
                            }
                        }
                    }
                }

                Text(
                    "Recipes with a known conflict are hidden. Others are labeled as marked by the owner or not verified."
                )
                .font(
                    KinTypography.caption
                )
                .foregroundStyle(
                    KinColors.secondaryText
                )
            }
        }
    }
}

// MARK: - Allergens

private extension RecipeFilterSheet {

    var allergenSection: some View {

        VStack(
            alignment: .leading,
            spacing: KinSpacing.medium
        ) {

            Text("Avoid Allergens")
                .font(
                    KinTypography.headline
                )
                .foregroundStyle(
                    KinColors.primaryText
                )

            if allergens.isEmpty {

                Text(
                    "Allergens couldn't be loaded."
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

                    ForEach(
                        allergens
                    ) { allergen in

                        filterChip(
                            title: allergen.name,
                            isSelected:
                                criteria.allergenIds
                                    .contains(
                                        allergen.id
                                    )
                        ) {

                            if criteria.allergenIds
                                .contains(
                                    allergen.id
                                ) {
                                criteria.allergenIds
                                    .remove(
                                        allergen.id
                                    )
                            } else {
                                criteria.allergenIds
                                    .insert(
                                        allergen.id
                                    )
                            }
                        }
                    }
                }

                Text(
                    "Recipes known to contain a selected allergen are hidden. Recipes with ingredients that couldn't be checked stay visible and are labeled."
                )
                .font(
                    KinTypography.caption
                )
                .foregroundStyle(
                    KinColors.secondaryText
                )
            }
        }
    }
}

// MARK: - Chip

private extension RecipeFilterSheet {

    func filterChip(
        title: String,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {

        Button(action: action) {

            Text(title)
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
                        : KinColors.surface
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
}

#Preview {

    RecipeFilterSheet(
        criteria: .constant(
            RecipeDiscoveryCriteria()
        ),
        restrictions: [],
        allergens: []
    )
}

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


    var body: some View {

        NavigationStack {

            ScrollView {

                VStack(
                    alignment: .leading,
                    spacing: KinSpacing.xLarge
                ) {

                    categorySection
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
        )
    )
}

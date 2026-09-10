//
//  AllergenWarningDetailView.swift
//  KinKitchen
//
//  Created by Greg Hudler on 9/9/26.
//

import SwiftUI

struct AllergenWarningDetailView: View {

    let result: RecipeDietaryCheckResult

    @Environment(\.dismiss)
    private var dismiss

    var body: some View {

        ZStack {

            KinColors.background
                .ignoresSafeArea()

            VStack(
                spacing: 0
            ) {

                header

                ScrollView {

                    VStack(
                        alignment: .leading,
                        spacing: KinSpacing.xLarge
                    ) {

                        warningSummary

                        if !result.conflicts.isEmpty {
                            conflictSection
                        }

                        if !result.unknownIngredients.isEmpty {
                            incompleteInformationSection
                        }

                        safetySection
                    }
                    .padding(
                        .horizontal,
                        KinSpacing.large
                    )
                    .padding(
                        .top,
                        KinSpacing.large
                    )
                    .padding(
                        .bottom,
                        KinSpacing.xxxLarge
                    )
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
    }
}


// MARK: - Header

private extension AllergenWarningDetailView {

    var header: some View {

        HStack(
            spacing: KinSpacing.medium
        ) {

            Button {
                dismiss()
            } label: {

                Image(
                    systemName: "chevron.left"
                )
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(
                    KinColors.primaryText
                )
                .frame(
                    width: 52,
                    height: 52
                )
                .background(
                    KinColors.surface
                )
                .clipShape(Circle())
            }

            Text(
                "Allergen Information"
            )
            .font(
                KinTypography.title2
            )
            .foregroundStyle(
                KinColors.primaryText
            )
            .lineLimit(1)

            Spacer()
        }
        .padding(
            .horizontal,
            KinSpacing.large
        )
        .padding(
            .vertical,
            KinSpacing.medium
        )
        .background(
            KinColors.background
        )
    }
}


// MARK: - Warning Summary

private extension AllergenWarningDetailView {

    @ViewBuilder
    var warningSummary: some View {

        switch result.state {

        case .conflict:

            HStack(
                alignment: .top,
                spacing: KinSpacing.medium
            ) {

                Image(
                    systemName:
                        "exclamationmark.triangle.fill"
                )
                .font(.title2)
                .foregroundStyle(
                    KinColors.error
                )
                .frame(
                    width: 48,
                    height: 48
                )
                .background(
                    KinColors.error.opacity(0.12)
                )
                .clipShape(Circle())

                VStack(
                    alignment: .leading,
                    spacing: KinSpacing.small
                ) {

                    Text(
                        "Potential Allergen Conflict"
                    )
                    .font(
                        KinTypography.title3
                    )
                    .foregroundStyle(
                        KinColors.primaryText
                    )

                    Text(
                        "This recipe contains ingredients that match allergens listed in your Dietary Profile."
                    )
                    .font(
                        KinTypography.body
                    )
                    .foregroundStyle(
                        KinColors.secondaryText
                    )
                }

                Spacer()
            }
            .padding(
                KinSpacing.large
            )
            .background(
                KinColors.surface
            )
            .clipShape(
                RoundedRectangle(
                    cornerRadius: 20
                )
            )

        case .incomplete:

            HStack(
                alignment: .top,
                spacing: KinSpacing.medium
            ) {

                Image(
                    systemName:
                        "questionmark.circle.fill"
                )
                .font(.title2)
                .foregroundStyle(
                    KinColors.warning
                )
                .frame(
                    width: 48,
                    height: 48
                )
                .background(
                    KinColors.warning.opacity(0.12)
                )
                .clipShape(Circle())

                VStack(
                    alignment: .leading,
                    spacing: KinSpacing.small
                ) {

                    Text(
                        "Allergen Information Incomplete"
                    )
                    .font(
                        KinTypography.title3
                    )
                    .foregroundStyle(
                        KinColors.primaryText
                    )

                    Text(
                        "Some ingredients could not be fully evaluated. This does not mean the recipe is safe."
                    )
                    .font(
                        KinTypography.body
                    )
                    .foregroundStyle(
                        KinColors.secondaryText
                    )
                }

                Spacer()
            }
            .padding(
                KinSpacing.large
            )
            .background(
                KinColors.surface
            )
            .clipShape(
                RoundedRectangle(
                    cornerRadius: 20
                )
            )

        case .noKnownConflict:

            EmptyView()
        }
    }
}


// MARK: - Conflict Section

private extension AllergenWarningDetailView {

    var conflictSection: some View {

        VStack(
            alignment: .leading,
            spacing: KinSpacing.medium
        ) {

            Text(
                "YOUR PROFILE MATCHES"
            )
            .font(
                KinTypography.caption
            )
            .foregroundStyle(
                KinColors.secondaryText
            )

            ForEach(
                result.conflicts
            ) { conflict in

                conflictCard(
                    conflict
                )
            }
        }
    }

    func conflictCard(
        _ conflict: RecipeAllergenConflict
    ) -> some View {

        VStack(
            alignment: .leading,
            spacing: KinSpacing.large
        ) {

            HStack(
                spacing: KinSpacing.medium
            ) {

                Image(
                    systemName:
                        "exclamationmark.triangle.fill"
                )
                .font(.headline)
                .foregroundStyle(
                    KinColors.error
                )

                Text(
                    conflict.allergen.name
                )
                .font(
                    KinTypography.title3
                )
                .foregroundStyle(
                    KinColors.primaryText
                )

                Spacer()
            }

            VStack(
                alignment: .leading,
                spacing: KinSpacing.xSmall
            ) {

                Text(
                    "Dietary Profile"
                )
                .font(
                    KinTypography.caption
                )
                .foregroundStyle(
                    KinColors.secondaryText
                )

                Text(
                    conflict.allergen.name
                )
                .font(
                    KinTypography.body
                )
                .foregroundStyle(
                    KinColors.primaryText
                )
            }

            VStack(
                alignment: .leading,
                spacing: KinSpacing.small
            ) {

                Text(
                    conflict.ingredientNames.count == 1
                        ? "Recipe Ingredient"
                        : "Recipe Ingredients"
                )
                .font(
                    KinTypography.caption
                )
                .foregroundStyle(
                    KinColors.secondaryText
                )

                ForEach(
                    conflict.ingredientNames,
                    id: \.self
                ) { ingredientName in

                    HStack(
                        spacing: KinSpacing.small
                    ) {

                        Circle()
                            .fill(
                                KinColors.error
                            )
                            .frame(
                                width: 6,
                                height: 6
                            )

                        Text(
                            ingredientName
                        )
                        .font(
                            KinTypography.body
                        )
                        .foregroundStyle(
                            KinColors.primaryText
                        )
                    }
                }
            }
        }
        .padding(
            KinSpacing.large
        )
        .frame(
            maxWidth: .infinity,
            alignment: .leading
        )
        .background(
            KinColors.surface
        )
        .clipShape(
            RoundedRectangle(
                cornerRadius: 20
            )
        )
    }
}


// MARK: - Incomplete Information

private extension AllergenWarningDetailView {

    var incompleteInformationSection: some View {

        VStack(
            alignment: .leading,
            spacing: KinSpacing.medium
        ) {

            Text(
                "INCOMPLETE INFORMATION"
            )
            .font(
                KinTypography.caption
            )
            .foregroundStyle(
                KinColors.secondaryText
            )

            VStack(
                alignment: .leading,
                spacing: KinSpacing.large
            ) {

                HStack(
                    alignment: .top,
                    spacing: KinSpacing.medium
                ) {

                    Image(
                        systemName:
                            "questionmark.circle.fill"
                    )
                    .font(.title3)
                    .foregroundStyle(
                        KinColors.warning
                    )

                    VStack(
                        alignment: .leading,
                        spacing: KinSpacing.small
                    ) {

                        Text(
                            "Some ingredients could not be fully evaluated"
                        )
                        .font(
                            KinTypography.headline
                        )
                        .foregroundStyle(
                            KinColors.primaryText
                        )

                        Text(
                            "Kin Kitchen does not have enough information to determine the allergen status of these ingredients."
                        )
                        .font(
                            KinTypography.callout
                        )
                        .foregroundStyle(
                            KinColors.secondaryText
                        )
                    }
                }

                ForEach(
                    result.unknownIngredients,
                    id: \.self
                ) { ingredientName in

                    HStack(
                        spacing: KinSpacing.small
                    ) {

                        Image(
                            systemName:
                                "questionmark"
                        )
                        .font(
                            KinTypography.caption
                        )
                        .foregroundStyle(
                            KinColors.warning
                        )

                        Text(
                            ingredientName
                        )
                        .font(
                            KinTypography.body
                        )
                        .foregroundStyle(
                            KinColors.primaryText
                        )
                    }
                }
            }
            .padding(
                KinSpacing.large
            )
            .frame(
                maxWidth: .infinity,
                alignment: .leading
            )
            .background(
                KinColors.surface
            )
            .clipShape(
                RoundedRectangle(
                    cornerRadius: 20
                )
            )
        }
    }
}


// MARK: - Safety Information

private extension AllergenWarningDetailView {

    var safetySection: some View {

        VStack(
            alignment: .leading,
            spacing: KinSpacing.medium
        ) {

            Text(
                "ABOUT THIS INFORMATION"
            )
            .font(
                KinTypography.caption
            )
            .foregroundStyle(
                KinColors.secondaryText
            )

            VStack(
                alignment: .leading,
                spacing: KinSpacing.medium
            ) {

                HStack(
                    alignment: .top,
                    spacing: KinSpacing.medium
                ) {

                    Image(
                        systemName: "info.circle"
                    )
                    .font(.title3)
                    .foregroundStyle(
                        KinColors.secondaryText
                    )

                    Text(
                        "Kin Kitchen identifies potential conflicts using your Dietary Profile and available ingredient information."
                    )
                    .font(
                        KinTypography.callout
                    )
                    .foregroundStyle(
                        KinColors.primaryText
                    )
                }

                Text(
                    "Ingredient and allergen information may be incomplete or inaccurate. Always verify ingredients, packaging, and product labels when making dietary decisions. Kin Kitchen does not provide medical advice."
                )
                .font(
                    KinTypography.footnote
                )
                .foregroundStyle(
                    KinColors.secondaryText
                )
            }
            .padding(
                KinSpacing.large
            )
            .frame(
                maxWidth: .infinity,
                alignment: .leading
            )
            .background(
                KinColors.surface
            )
            .clipShape(
                RoundedRectangle(
                    cornerRadius: 20
                )
            )
        }
    }
}

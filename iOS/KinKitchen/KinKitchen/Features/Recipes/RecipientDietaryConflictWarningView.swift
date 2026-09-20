//
//  RecipientDietaryConflictWarningView.swift
//  KinKitchen
//
//  Created by Greg Hudler on 9/20/26.
//

import SwiftUI

// MARK: - Recipient Dietary Conflict Warning View

struct RecipientDietaryConflictWarningView: View {
    let recipient: ProfileSearchResult
    let result: RecipientRecipeDietaryCheckResult

    var body: some View {
        VStack(
            alignment: .leading,
            spacing: KinSpacing.large
        ) {
            warningHeader

            if result.hasConflict {
                conflictContent
            }

            if result.hasIncompleteInformation {
                incompleteInformation
            }

            if !result.hasConflict &&
                !result.hasIncompleteInformation {
                noKnownConflict
            }

            safetyNotice
        }
    }
}

// MARK: - Warning Header

private extension RecipientDietaryConflictWarningView {
    var warningHeader: some View {
        KinCard {
            HStack(
                alignment: .top,
                spacing: KinSpacing.medium
            ) {
                Image(
                    systemName:
                        result.hasConflict
                        ? "exclamationmark.triangle.fill"
                        : "info.circle.fill"
                )
                .font(KinTypography.title)
                .foregroundStyle(
                    result.hasConflict
                    ? KinColors.warning
                    : KinColors.primary
                )

                VStack(
                    alignment: .leading,
                    spacing: KinSpacing.xSmall
                ) {
                    Text(
                        result.hasConflict
                        ? "Dietary Conflict Warning"
                        : "Dietary Review"
                    )
                    .font(KinTypography.headline)
                    .foregroundStyle(
                        KinColors.primaryText
                    )

                    Text(recipientMessage)
                        .font(KinTypography.body)
                        .foregroundStyle(
                            KinColors.secondaryText
                        )
                }

                Spacer()
            }
        }
    }

    var recipientMessage: String {
        if result.hasConflict {
            return "\(recipientName) may have dietary conflicts with this recipe."
        }

        if result.hasIncompleteInformation {
            return "Some dietary safety information for \(recipientName) could not be confirmed."
        }

        return "No known dietary conflicts were identified for \(recipientName)."
    }

    var recipientName: String {
        let displayName =
            recipient.displayName?
                .trimmingCharacters(
                    in: .whitespacesAndNewlines
                )

        if let displayName,
           !displayName.isEmpty {
            return displayName
        }

        let firstName =
            recipient.firstName?
                .trimmingCharacters(
                    in: .whitespacesAndNewlines
                ) ?? ""

        let lastName =
            recipient.lastName?
                .trimmingCharacters(
                    in: .whitespacesAndNewlines
                ) ?? ""

        let fullName =
            "\(firstName) \(lastName)"
                .trimmingCharacters(
                    in: .whitespacesAndNewlines
                )

        if !fullName.isEmpty {
            return fullName
        }

        if let username =
            recipient.username?
                .trimmingCharacters(
                    in: .whitespacesAndNewlines
                ),
           !username.isEmpty {
            return "@\(username)"
        }

        return "this recipient"
    }
}

// MARK: - Conflict Content

private extension RecipientDietaryConflictWarningView {
    @ViewBuilder
    var conflictContent: some View {
        if !result.allergenConflicts.isEmpty {
            conflictSection(
                title: "Allergens",
                systemImage:
                    "exclamationmark.triangle.fill",
                color: KinColors.error
            ) {
                ForEach(
                    result.allergenConflicts
                ) {
                    conflict in

                    conflictRow(
                        title:
                            conflict.allergen.name,
                        ingredients:
                            conflict.ingredientNames
                    )
                }
            }
        }

        if !result.restrictionConflicts.isEmpty {
            conflictSection(
                title: "Dietary Restrictions",
                systemImage:
                    "hand.raised.fill",
                color: KinColors.warning
            ) {
                ForEach(
                    result.restrictionConflicts
                ) {
                    conflict in

                    conflictRow(
                        title:
                            conflict.restriction.name,
                        ingredients:
                            conflict.ingredientNames
                    )
                }
            }
        }

        if !result.preferenceConflicts.isEmpty {
            conflictSection(
                title: "Dietary Preferences",
                systemImage:
                    "leaf.fill",
                color: KinColors.primary
            ) {
                ForEach(
                    result.preferenceConflicts
                ) {
                    conflict in

                    conflictRow(
                        title:
                            conflict.preference.name,
                        ingredients:
                            conflict.ingredientNames
                    )
                }
            }
        }
    }

    func conflictSection<Content: View>(
        title: String,
        systemImage: String,
        color: Color,
        @ViewBuilder content: () -> Content
    ) -> some View {
        KinCard {
            VStack(
                alignment: .leading,
                spacing: KinSpacing.medium
            ) {
                HStack(
                    spacing: KinSpacing.small
                ) {
                    Image(
                        systemName: systemImage
                    )
                    .foregroundStyle(color)

                    Text(title)
                        .font(
                            KinTypography.headline
                        )
                        .foregroundStyle(
                            KinColors.primaryText
                        )
                }

                content()
            }
        }
    }

    func conflictRow(
        title: String,
        ingredients: [String]
    ) -> some View {
        VStack(
            alignment: .leading,
            spacing: KinSpacing.xSmall
        ) {
            Text(title)
                .font(KinTypography.body)
                .foregroundStyle(
                    KinColors.primaryText
                )

            if !ingredients.isEmpty {
                Text(
                    ingredientDescription(
                        ingredients
                    )
                )
                .font(KinTypography.caption)
                .foregroundStyle(
                    KinColors.secondaryText
                )
            }
        }
    }

    func ingredientDescription(
        _ ingredients: [String]
    ) -> String {
        let names =
            ingredients.joined(
                separator: ", "
            )

        return "Found in: \(names)"
    }
}

// MARK: - Incomplete Information

private extension RecipientDietaryConflictWarningView {
    var incompleteInformation: some View {
        KinCard {
            VStack(
                alignment: .leading,
                spacing: KinSpacing.medium
            ) {
                HStack(
                    spacing: KinSpacing.small
                ) {
                    Image(
                        systemName:
                            "questionmark.circle.fill"
                    )
                    .foregroundStyle(
                        KinColors.warning
                    )

                    Text(
                        "Incomplete Information"
                    )
                    .font(
                        KinTypography.headline
                    )
                    .foregroundStyle(
                        KinColors.primaryText
                    )
                }

                Text(
                    "Some ingredients could not be fully evaluated. This does not confirm that the recipe is safe for \(recipientName)."
                )
                .font(KinTypography.body)
                .foregroundStyle(
                    KinColors.secondaryText
                )

                if !result.unknownIngredients.isEmpty {
                    VStack(
                        alignment: .leading,
                        spacing: KinSpacing.xSmall
                    ) {
                        Text(
                            "Unknown ingredients"
                        )
                        .font(
                            KinTypography.body
                        )
                        .foregroundStyle(
                            KinColors.primaryText
                        )

                        Text(
                            result
                                .unknownIngredients
                                .joined(
                                    separator: ", "
                                )
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
    }
}

// MARK: - No Known Conflict

private extension RecipientDietaryConflictWarningView {
    var noKnownConflict: some View {
        KinCard {
            HStack(
                alignment: .top,
                spacing: KinSpacing.medium
            ) {
                Image(
                    systemName:
                        "checkmark.circle.fill"
                )
                .foregroundStyle(
                    KinColors.success
                )

                VStack(
                    alignment: .leading,
                    spacing: KinSpacing.xSmall
                ) {
                    Text(
                        "No Known Conflict"
                    )
                    .font(
                        KinTypography.headline
                    )
                    .foregroundStyle(
                        KinColors.primaryText
                    )

                    Text(
                        "No conflicts were identified from the dietary information currently available for \(recipientName)."
                    )
                    .font(KinTypography.body)
                    .foregroundStyle(
                        KinColors.secondaryText
                    )
                }
            }
        }
    }
}

// MARK: - Safety Notice

private extension RecipientDietaryConflictWarningView {
    var safetyNotice: some View {
        Text(
            "Kin Kitchen provides dietary information to help with planning. Ingredient and allergen information may be incomplete or change over time. Always verify ingredients when dietary safety is important."
        )
        .font(KinTypography.caption)
        .foregroundStyle(
            KinColors.secondaryText
        )
    }
}

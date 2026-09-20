//
//  RecipeShareReviewView.swift
//  KinKitchen
//
//  Created by Greg Hudler on 9/20/26.
//

import SwiftUI

// MARK: - Recipe Share Review View

struct RecipeShareReviewView: View {
    @Environment(\.dismiss) private var dismiss

    let recipeId: UUID
    let recipient: ProfileSearchResult
    let dietaryResult: RecipientRecipeDietaryCheckResult
    let onShared: () -> Void

    @State private var isSharing = false
    @State private var errorMessage: String?
    @State private var shareCompleted = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(
                    alignment: .leading,
                    spacing: KinSpacing.large
                ) {
                    RecipientDietaryConflictWarningView(
                        recipient: recipient,
                        result: dietaryResult
                    )

                    actionSection
                }
                .padding(KinSpacing.large)
            }
            .background(KinColors.background)
            .navigationTitle("Review Share")
            .navigationBarTitleDisplayMode(.inline)
            .interactiveDismissDisabled(isSharing)
        }
    }
}

// MARK: - Actions

private extension RecipeShareReviewView {
    var actionSection: some View {
        VStack(
            spacing: KinSpacing.medium
        ) {
            if let errorMessage {
                Text(errorMessage)
                    .font(KinTypography.caption)
                    .foregroundStyle(
                        KinColors.error
                    )
                    .frame(
                        maxWidth: .infinity,
                        alignment: .leading
                    )
            }

            Button {
                Task {
                    await completeShare()
                }
            } label: {
                HStack(
                    spacing: KinSpacing.small
                ) {
                    if isSharing {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Image(
                            systemName:
                                "square.and.arrow.up"
                        )
                    }

                    Text(
                        isSharing
                        ? "Sharing..."
                        : continueButtonTitle
                    )
                    .font(KinTypography.headline)
                }
                .frame(
                    maxWidth: .infinity
                )
                .padding(.vertical, KinSpacing.medium)
                .foregroundStyle(.white)
                .background(
                    KinColors.primary
                )
                .clipShape(
                    RoundedRectangle(
                        cornerRadius: KinRadius.medium
                    )
                )
            }
            .buttonStyle(.plain)
            .disabled(
                isSharing ||
                shareCompleted
            )

            Button {
                dismiss()
            } label: {
                Text("Cancel")
                    .font(KinTypography.headline)
                    .foregroundStyle(
                        KinColors.primaryText
                    )
                    .frame(
                        maxWidth: .infinity
                    )
                    .padding(
                        .vertical,
                        KinSpacing.medium
                    )
                    .background(
                        KinColors.surface
                    )
                    .clipShape(
                        RoundedRectangle(
                            cornerRadius:
                                KinRadius.medium
                        )
                    )
            }
            .buttonStyle(.plain)
            .disabled(isSharing)
        }
    }

    var continueButtonTitle: String {
        if dietaryResult.hasConflict {
            return "Continue and Share"
        }

        return "Share Recipe"
    }
}

// MARK: - Complete Share

private extension RecipeShareReviewView {
    @MainActor
    func completeShare() async {
        guard !isSharing else {
            return
        }

        isSharing = true
        errorMessage = nil

        do {
            _ =
                try await RecipeSharingService
                    .createShare(
                        recipeId: recipeId,
                        recipientId: recipient.id
                    )

            shareCompleted = true
            isSharing = false

            onShared()
            dismiss()
        } catch {
            isSharing = false
            errorMessage =
                "The recipe could not be shared. Please try again."
        }
    }
}

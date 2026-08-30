//
//  DietaryPreferencesSetupView.swift
//  KinKitchen
//
//  Created by Greg Hudler on 8/30/26.
//

import SwiftUI

struct DietaryPreferencesSetupView: View {

    let onFinish: () -> Void

    @State private var preferences: [DietaryPreference] = []

    @State private var selectedPreferenceIds: Set<UUID> = []
    @State private var originalPreferenceIds: Set<UUID> = []

    @State private var hasNoDietaryPreferences = false

    @State private var isLoading = true
    @State private var isSaving = false

    @State private var errorMessage: String?
    @State private var isShowingErrorAlert = false

    var body: some View {

        ScrollView {

            VStack(
                alignment: .leading,
                spacing: KinSpacing.xLarge
            ) {

                VStack(
                    alignment: .leading,
                    spacing: KinSpacing.small
                ) {

                    Text("Any Dietary Preferences?")
                        .font(KinTypography.largeTitle)
                        .foregroundStyle(KinColors.primaryText)
                        .frame(
                            maxWidth: .infinity,
                            alignment: .leading
                        )
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)

                    Text(
                        "Tell us about the foods and eating styles you prefer."
                    )
                    .font(KinTypography.body)
                    .foregroundStyle(KinColors.secondaryText)
                    .frame(
                        maxWidth: .infinity,
                        alignment: .leading
                    )
                }

                if isLoading {

                    KinLoadingView()

                } else {

                    VStack(
                        alignment: .leading,
                        spacing: KinSpacing.medium
                    ) {

                        Text("Dietary Preferences")
                            .font(KinTypography.title)
                            .foregroundStyle(KinColors.primaryText)

                        KinFlowLayout(
                            spacing: KinSpacing.small
                        ) {

                            ForEach(preferences) { preference in

                                Button {

                                    togglePreference(
                                        preference.id
                                    )

                                } label: {

                                    KinChip(
                                        title: preference.name,
                                        isSelected:
                                            selectedPreferenceIds
                                                .contains(
                                                    preference.id
                                                )
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    Button {

                        toggleNoPreferences()

                    } label: {

                        HStack(
                            spacing: KinSpacing.medium
                        ) {

                            Image(
                                systemName:
                                    hasNoDietaryPreferences
                                    ? "checkmark.circle.fill"
                                    : "circle"
                            )
                            .font(.title3)
                            .foregroundStyle(
                                hasNoDietaryPreferences
                                    ? KinColors.success
                                    : KinColors.secondaryText
                            )

                            Text(
                                "I don't have any dietary preferences"
                            )
                            .font(KinTypography.body)
                            .foregroundStyle(KinColors.primaryText)

                            Spacer()
                        }
                        .frame(
                            maxWidth: .infinity,
                            alignment: .leading
                        )
                        .padding(KinSpacing.medium)
                        .background(KinColors.surface)
                        .clipShape(
                            RoundedRectangle(
                                cornerRadius: KinRadius.medium
                            )
                        )
                    }
                    .buttonStyle(.plain)

                    if let errorMessage {

                        Text(errorMessage)
                            .font(KinTypography.caption)
                            .foregroundStyle(KinColors.error)
                            .frame(
                                maxWidth: .infinity,
                                alignment: .leading
                            )
                    }

                    KinPrimaryButton(
                        title:
                            isSaving
                            ? "Saving..."
                            : "Finish",
                        color: KinColors.success
                    ) {

                        Task {
                            await saveAndFinish()
                        }
                    }
                    .disabled(isSaving)
                }
            }
            .padding(KinSpacing.xLarge)
        }
        .background(KinColors.background)
        .task {
            await loadDietaryPreferences()
        }
        .alert(
            "Dietary Preferences",
            isPresented: $isShowingErrorAlert
        ) {

            Button(
                "OK",
                role: .cancel
            ) { }

        } message: {

            Text(errorMessage ?? "")
        }
    }

    private func togglePreference(
        _ preferenceId: UUID
    ) {

        hasNoDietaryPreferences = false

        if selectedPreferenceIds.contains(
            preferenceId
        ) {

            selectedPreferenceIds.remove(
                preferenceId
            )

        } else {

            selectedPreferenceIds.insert(
                preferenceId
            )
        }
    }

    private func toggleNoPreferences() {

        hasNoDietaryPreferences.toggle()

        if hasNoDietaryPreferences {
            selectedPreferenceIds.removeAll()
        }
    }

    @MainActor
    private func loadDietaryPreferences() async {

        isLoading = true
        errorMessage = nil

        defer {
            isLoading = false
        }

        do {

            async let loadedPreferences =
                DietaryService.fetchDietaryPreferences()

            async let savedPreferences =
                DietaryService
                    .fetchSelectedDietaryPreferences()

            preferences =
                try await loadedPreferences

            selectedPreferenceIds =
                Set(
                    try await savedPreferences
                )

            originalPreferenceIds =
                selectedPreferenceIds

            hasNoDietaryPreferences =
                selectedPreferenceIds.isEmpty

        } catch {

            errorMessage =
                "Unable to load dietary preferences."

            isShowingErrorAlert = true

            print(
                "DIETARY PREFERENCES LOAD ERROR:",
                error.localizedDescription
            )
        }
    }

    @MainActor
    private func saveAndFinish() async {

        guard !isSaving else {
            return
        }

        errorMessage = nil

        guard
            !selectedPreferenceIds.isEmpty ||
            hasNoDietaryPreferences
        else {

            errorMessage =
                "Please select any dietary preferences that apply, or choose that you don't have any."

            isShowingErrorAlert = true
            return
        }

        isSaving = true

        defer {
            isSaving = false
        }

        do {

            let preferencesToAdd =
                selectedPreferenceIds
                    .subtracting(
                        originalPreferenceIds
                    )

            let preferencesToRemove =
                originalPreferenceIds
                    .subtracting(
                        selectedPreferenceIds
                    )

            for id in preferencesToAdd {

                try await DietaryService
                    .addDietaryPreference(id)
            }

            for id in preferencesToRemove {

                try await DietaryService
                    .removeDietaryPreference(id)
            }

            originalPreferenceIds =
                selectedPreferenceIds

            onFinish()

        } catch {

            errorMessage =
                "Unable to save your dietary preferences. Please try again."

            isShowingErrorAlert = true

            print(
                "DIETARY PREFERENCES SAVE ERROR:",
                error.localizedDescription
            )
        }
    }
}

#Preview {

    DietaryPreferencesSetupView {

        print("Dietary onboarding finished")
    }
}

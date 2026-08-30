//
//  EditProfileView.swift
//  KinKitchen
//
//  Created by Greg Hudler on 8/27/26.
//

import SwiftUI

struct EditProfileView: View {

    @Environment(\.dismiss) private var dismiss

    @State private var firstName = ""
    @State private var lastName = ""
    @State private var displayName = ""
    @State private var username = ""
    @State private var location = ""
    @State private var birthDate = Date()
    @State private var bio = ""

    @State private var errorMessage: String?
    @State private var isLoading = true
    @State private var isSaving = false

    var body: some View {
        ScrollView {
            VStack(spacing: KinSpacing.xLarge) {

                Text("Edit Profile")
                    .font(KinTypography.largeTitle)
                    .foregroundStyle(KinColors.primaryText)

                if isLoading {
                    ProgressView()

                } else {
                    profileForm
                }
            }
            .padding(KinSpacing.xLarge)
        }
        .background(KinColors.background)
        .task {
            await loadProfile()
        }
    }

    private var profileForm: some View {
        VStack(spacing: KinSpacing.xLarge) {

            VStack(
                alignment: .leading,
                spacing: KinSpacing.large
            ) {
                KinTextField(
                    title: "First Name",
                    text: $firstName
                )

                KinTextField(
                    title: "Last Name",
                    text: $lastName
                )

                KinTextField(
                    title: "Display Name",
                    text: $displayName
                )

                KinTextField(
                    title: "Username",
                    text: $username
                )

                KinTextField(
                    title: "Location",
                    text: $location
                )

                VStack(
                    alignment: .leading,
                    spacing: KinSpacing.small
                ) {
                    Text("Birthday")
                        .font(KinTypography.body)
                        .foregroundStyle(KinColors.primaryText)

                    DatePicker(
                        "Birthday",
                        selection: $birthDate,
                        in: allowedBirthDateRange,
                        displayedComponents: .date
                    )
                    .labelsHidden()
                    .datePickerStyle(.compact)
                }

                VStack(
                    alignment: .leading,
                    spacing: KinSpacing.small
                ) {
                    Text("Bio")
                        .font(KinTypography.body)
                        .foregroundStyle(KinColors.primaryText)

                    KinTextEditor(
                        text: $bio
                    )
                }
            }

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
                title: isSaving ? "Saving..." : "Save",
                color: KinColors.success
            ) {
                Task {
                    await saveProfile()
                }
            }
            .disabled(isSaving)

            KinSecondaryButton(
                title: "Cancel"
            ) {
                dismiss()
            }
        }
    }

    private var allowedBirthDateRange: ClosedRange<Date> {
        let calendar = Calendar.current

        let oldest =
            calendar.date(
                byAdding: .year,
                value: -120,
                to: Date()
            ) ?? Date()

        let youngest =
            calendar.date(
                byAdding: .year,
                value: -13,
                to: Date()
            ) ?? Date()

        return oldest...youngest
    }

    @MainActor
    private func loadProfile() async {
        isLoading = true
        errorMessage = nil

        defer {
            isLoading = false
        }

        do {
            let profile =
                try await ProfileService.fetchCurrentProfile()

            firstName = profile.firstName ?? ""
            lastName = profile.lastName ?? ""
            displayName = profile.displayName ?? ""
            username = profile.username ?? ""
            location = profile.location ?? ""
            bio = profile.bio ?? ""

            if let savedBirthDate =
                ProfileService.date(from: profile.birthDate)
            {
                birthDate = savedBirthDate
            }

        } catch {
            errorMessage = "Unable to load your profile."
        }
    }

    @MainActor
    private func saveProfile() async {
        guard !isSaving else {
            return
        }

        let cleanFirstName =
            firstName.trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        let cleanLastName =
            lastName.trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        let cleanDisplayName =
            displayName.trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        let cleanUsername =
            username.trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        guard !cleanFirstName.isEmpty else {
            errorMessage = "First name is required."
            return
        }

        guard !cleanLastName.isEmpty else {
            errorMessage = "Last name is required."
            return
        }

        guard !cleanDisplayName.isEmpty else {
            errorMessage = "Display name is required."
            return
        }

        guard !cleanUsername.isEmpty else {
            errorMessage = "Username is required."
            return
        }

        isSaving = true
        errorMessage = nil

        defer {
            isSaving = false
        }

        do {
            try await ProfileService.updateProfile(
                firstName: cleanFirstName,
                lastName: cleanLastName,
                displayName: cleanDisplayName,
                username: cleanUsername,
                location: location,
                birthDate: birthDate,
                bio: bio
            )

            dismiss()

        } catch {
            errorMessage =
                "Unable to save your profile."
        }
    }
}

#Preview {
    EditProfileView()
}

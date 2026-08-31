//
//  ProfileSetupView.swift
//  KinKitchen
//
//  Created by Greg Hudler on 8/30/26.
//

import SwiftUI
import PhotosUI
import UIKit

struct ProfileSetupView: View {

    enum ProfileFormField: Hashable {
        case firstName
        case lastName
        case username
        case location
        case bio
    }

    enum ProfileSetupMode {
        case create
        case update
    }


    // MARK: - Focus

    @FocusState private var focusedField: ProfileFormField?
    @State private var fieldToFocus: ProfileFormField?


    // MARK: - Setup Mode

    @State private var mode: ProfileSetupMode = .create


    // MARK: - Completion

    let onProfileCompleted: () -> Void


    // MARK: - Profile Fields

    @State private var firstName = ""
    @State private var lastName = ""
    @State private var username = ""
    @State private var location = ""
    @State private var bio = ""

    @State private var birthDate =
        Calendar.current.date(
            byAdding: .year,
            value: -18,
            to: Date()
        ) ?? Date()


    // Tracks which required fields already existed in Supabase.
    // Existing values are displayed read-only during profile completion.

    @State private var hadExistingFirstName = false
    @State private var hadExistingLastName = false
    @State private var hadExistingUsername = false
    @State private var hasExistingBirthDate = false


    // MARK: - Photo

    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var profilePhotoData: Data?


    // MARK: - Username Availability

    @State private var usernameAvailability:
        UsernameAvailability = .unknown


    // MARK: - Alerts / Errors

    @State private var errorMessage: String?
    @State private var isShowingErrorAlert = false
    @State private var isShowingParentPermissionAlert = false


    // MARK: - Saving

    @State private var isSaving = false


    // MARK: - Body

    var body: some View {

        ScrollView {

            VStack(spacing: KinSpacing.xLarge) {

                // MARK: - Header

                VStack(
                    alignment: .leading,
                    spacing: KinSpacing.small
                ) {

                    Text(
                        mode == .create
                            ? "Create Your Profile"
                            : "Update Your Profile"
                    )
                    .font(KinTypography.largeTitle)
                    .foregroundStyle(KinColors.primaryText)
                    .frame(
                        maxWidth: .infinity,
                        alignment: .leading
                    )
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)

                    Text(
                        mode == .create
                            ? "Tell us a little about yourself."
                            : "We need a little more information to complete your profile."
                    )
                    .font(KinTypography.body)
                    .foregroundStyle(KinColors.secondaryText)
                    .frame(
                        maxWidth: .infinity,
                        alignment: .leading
                    )
                }


                // MARK: - Profile Photo

                if mode == .create {

                    profilePhotoSection
                }


                // MARK: - Profile Information

                VStack(
                    alignment: .leading,
                    spacing: KinSpacing.large
                ) {

                    // MARK: First Name

                    if mode == .update &&
                        hadExistingFirstName {

                        profileValueRow(
                            title: "First Name",
                            value: firstName
                        )

                    } else {

                        VStack(
                            alignment: .leading,
                            spacing: KinSpacing.small
                        ) {

                            Text("First Name")
                                .font(KinTypography.caption)
                                .foregroundStyle(
                                    KinColors.secondaryText
                                )

                            KinTextField(
                                title: "Enter First Name",
                                text: $firstName
                            )
                            .focused(
                                $focusedField,
                                equals: .firstName
                            )
                        }
                    }


                    // MARK: Last Name

                    if mode == .update &&
                        hadExistingLastName {

                        profileValueRow(
                            title: "Last Name",
                            value: lastName
                        )

                    } else {

                        VStack(
                            alignment: .leading,
                            spacing: KinSpacing.small
                        ) {

                            Text("Last Name")
                                .font(KinTypography.caption)
                                .foregroundStyle(
                                    KinColors.secondaryText
                                )

                            KinTextField(
                                title: "Enter Last Name",
                                text: $lastName
                            )
                            .focused(
                                $focusedField,
                                equals: .lastName
                            )
                        }
                    }


                    // MARK: Username

                    if mode == .update &&
                        hadExistingUsername {

                        profileValueRow(
                            title: "Username",
                            value: "@\(username)"
                        )

                    } else {

                        VStack(
                            alignment: .leading,
                            spacing: KinSpacing.small
                        ) {

                            Text("Username")
                                .font(KinTypography.caption)
                                .foregroundStyle(
                                    KinColors.secondaryText
                                )

                            KinTextField(
                                title: "Choose Username",
                                text: $username
                            )
                            .focused(
                                $focusedField,
                                equals: .username
                            )

                            usernameAvailabilityView
                        }
                    }


                    // MARK: Birthday

                    if mode == .update &&
                        hasExistingBirthDate {

                        profileValueRow(
                            title: "Birthday",
                            value: birthDate.formatted(
                                date: .long,
                                time: .omitted
                            )
                        )

                    } else {

                        birthdaySection
                    }


                    // MARK: - Optional Information

                    if mode == .create {

                        KinTextField(
                            title: "City, State",
                            text: $location
                        )
                        .focused(
                            $focusedField,
                            equals: .location
                        )

                        bioSection

                    } else {

                        // Existing Location

                        if !location.trimmingCharacters(
                            in: .whitespacesAndNewlines
                        ).isEmpty {

                            profileValueRow(
                                title: "City, State",
                                value: location
                            )
                        }


                        // Existing Bio

                        if !bio.trimmingCharacters(
                            in: .whitespacesAndNewlines
                        ).isEmpty {

                            profileValueRow(
                                title: "Quick Bio",
                                value: bio
                            )
                        }


                        // Edit Profile Note

                        Text(
                            "You can change your profile photo, location, bio, and other profile information later from Edit Profile."
                        )
                        .font(KinTypography.caption)
                        .foregroundStyle(
                            KinColors.secondaryText
                        )
                        .frame(
                            maxWidth: .infinity,
                            alignment: .leading
                        )
                    }
                }


                // MARK: - Inline Error

                if let errorMessage {

                    Text(errorMessage)
                        .font(KinTypography.caption)
                        .foregroundStyle(KinColors.error)
                        .frame(
                            maxWidth: .infinity,
                            alignment: .leading
                        )
                }


                // MARK: - Continue Button

                KinPrimaryButton(
                    title: buttonTitle,
                    color: KinColors.success
                ) {

                    Task {

                        await completeProfile()
                    }
                }
                .disabled(isSaving)
            }
            .padding(KinSpacing.xLarge)
        }
        .background(KinColors.background)


        // MARK: - Load Existing Profile

        .task {

            await loadExistingProfile()
        }


        // MARK: - Username Availability

        .task(id: username) {

            await checkUsernameAvailability()
        }


        // MARK: - Photo Selection

        .onChange(
            of: selectedPhotoItem
        ) { _, newItem in

            guard let newItem else {

                return
            }

            Task {

                await loadSelectedPhoto(newItem)
            }
        }


        // MARK: - Parent Permission Alert

        .alert(
            "Parent Permission Required",
            isPresented: $isShowingParentPermissionAlert
        ) {

            Button(
                "OK",
                role: .cancel
            ) { }

        } message: {

            Text(
                "Kin Kitchen requires a parent or guardian to create and manage accounts for children under 13."
            )
        }


        // MARK: - General Error Alert

        .alert(
            "Profile Setup",
            isPresented: $isShowingErrorAlert
        ) {

            Button("OK") {

                let target = fieldToFocus
                fieldToFocus = nil

                Task { @MainActor in

                    try? await Task.sleep(
                        for: .milliseconds(100)
                    )

                    focusedField = target
                }
            }

        } message: {

            Text(errorMessage ?? "")
        }
    }


    // MARK: - Button Title

    private var buttonTitle: String {

        if isSaving {

            return mode == .create
                ? "Creating Profile..."
                : "Updating Profile..."
        }

        return "Continue"
    }


    // MARK: - Completed Required Field

    private func shouldDisplayAsCompleted(
        _ value: String
    ) -> Bool {

        guard mode == .update else {

            return false
        }

        let cleanValue =
            value.trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        return !cleanValue.isEmpty
    }


    // MARK: - Read-Only Profile Row

    private func profileValueRow(
        title: String,
        value: String
    ) -> some View {

        VStack(
            alignment: .leading,
            spacing: KinSpacing.small
        ) {

            Text(title)
                .font(KinTypography.caption)
                .foregroundStyle(
                    KinColors.secondaryText
                )

            Text(value)
                .font(KinTypography.body)
                .foregroundStyle(
                    KinColors.primaryText
                )
                .frame(
                    maxWidth: .infinity,
                    alignment: .leading
                )
        }
    }


    // MARK: - Profile Photo

    private var profilePhotoSection: some View {

        HStack(spacing: KinSpacing.large) {

            if
                let profilePhotoData,
                let image = UIImage(
                    data: profilePhotoData
                )
            {

                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(
                        width: 88,
                        height: 88
                    )
                    .clipShape(Circle())

            } else {

                Image(
                    systemName: KinIcons.profile
                )
                .font(
                    .system(size: 38)
                )
                .foregroundStyle(
                    KinColors.secondaryText
                )
                .frame(
                    width: 88,
                    height: 88
                )
                .background(
                    KinColors.surface
                )
                .clipShape(Circle())
            }

            VStack(
                alignment: .leading,
                spacing: KinSpacing.small
            ) {

                Text("Profile Photo")
                    .font(KinTypography.body)
                    .foregroundStyle(
                        KinColors.primaryText
                    )

                KinPhotoPicker(
                    selectedItem:
                        $selectedPhotoItem
                )

                Text("Optional")
                    .font(KinTypography.caption)
                    .foregroundStyle(
                        KinColors.secondaryText
                    )
            }

            Spacer()
        }
        .frame(
            maxWidth: .infinity
        )
    }


    // MARK: - Birthday

    private var birthdaySection: some View {

        VStack(
            alignment: .leading,
            spacing: KinSpacing.small
        ) {

            HStack {

                Text("Birthday")
                    .font(KinTypography.body)
                    .foregroundStyle(
                        KinColors.primaryText
                    )

                Spacer()

                DatePicker(
                    "",
                    selection: $birthDate,
                    in: allowedBirthDateRange,
                    displayedComponents: .date
                )
                .labelsHidden()
                .datePickerStyle(.compact)
            }

            Text(
                "You must be at least 13 years old."
            )
            .font(KinTypography.caption)
            .foregroundStyle(
                KinColors.secondaryText
            )
        }
    }


    // MARK: - Birth Date Range

    private var allowedBirthDateRange:
        ClosedRange<Date> {

        let calendar = Calendar.current

        let oldest =
            calendar.date(
                byAdding: .year,
                value: -120,
                to: Date()
            ) ?? Date()

        return oldest...Date()
    }


    // MARK: - Bio

    private var bioSection: some View {

        VStack(
            alignment: .leading,
            spacing: KinSpacing.small
        ) {

            Text("Quick Bio")
                .font(KinTypography.body)
                .foregroundStyle(
                    KinColors.primaryText
                )

            KinTextEditor(
                text: $bio
            )
            .focused(
                $focusedField,
                equals: .bio
            )

            Text("Optional")
                .font(KinTypography.caption)
                .foregroundStyle(
                    KinColors.secondaryText
                )
        }
    }


    // MARK: - Complete Profile

    @MainActor
    private func completeProfile() async {

        guard !isSaving else {

            return
        }

        errorMessage = nil

        let cleanFirstName =
            firstName.trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        let cleanLastName =
            lastName.trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        let cleanUsername =
            username.trimmingCharacters(
                in: .whitespacesAndNewlines
            )


        // MARK: First Name Validation

        guard !cleanFirstName.isEmpty else {

            errorMessage =
                "First name is required."

            fieldToFocus = .firstName
            isShowingErrorAlert = true

            return
        }


        // MARK: Last Name Validation

        guard !cleanLastName.isEmpty else {

            errorMessage =
                "Last name is required."

            fieldToFocus = .lastName
            isShowingErrorAlert = true

            return
        }


        // MARK: Username Validation

        guard !cleanUsername.isEmpty else {

            errorMessage =
                "Username is required."

            fieldToFocus = .username
            isShowingErrorAlert = true

            return
        }


        // Existing users keep their current username.
        // Only new / missing usernames need availability validation.

        if mode == .create ||
            !hadExistingUsername {

            guard cleanUsername.count >= 3 else {

                errorMessage =
                    "Username must be at least 3 characters."

                fieldToFocus = .username
                isShowingErrorAlert = true

                return
            }

            guard
                usernameAvailability == .available
            else {

                if usernameAvailability == .taken {

                    errorMessage =
                        "That username is already taken. Please choose another."

                } else {

                    errorMessage =
                        "Please wait for the username availability check to complete."
                }

                fieldToFocus = .username
                isShowingErrorAlert = true

                return
            }
        }


        // MARK: Age Validation

        guard isAtLeast13(birthDate) else {

            isShowingParentPermissionAlert = true

            return
        }


        // MARK: Save

        isSaving = true

        defer {

            isSaving = false
        }

        do {

            try await ProfileService.completeInitialProfile(
                firstName: cleanFirstName,
                lastName: cleanLastName,
                username: cleanUsername,
                location: location,
                birthDate: birthDate,
                bio: bio
            )

            if let profilePhotoData {

                _ =
                    try await ProfileService
                        .uploadProfilePhoto(
                            profilePhotoData
                        )
            }

            onProfileCompleted()

        } catch {

            errorMessage =
                "Unable to complete your profile. Please try again."

            isShowingErrorAlert = true

            print(
                "PROFILE SETUP ERROR:",
                error.localizedDescription
            )
        }
    }


    // MARK: - Load Existing Profile

    @MainActor
    private func loadExistingProfile() async {

        do {

            let profile =
                try await ProfileService
                    .fetchCurrentProfile()

            let cleanFirstName =
                profile.firstName?
                    .trimmingCharacters(
                        in: .whitespacesAndNewlines
                    ) ?? ""

            let cleanLastName =
                profile.lastName?
                    .trimmingCharacters(
                        in: .whitespacesAndNewlines
                    ) ?? ""

            let cleanUsername =
                profile.username?
                    .trimmingCharacters(
                        in: .whitespacesAndNewlines
                    ) ?? ""

            let cleanDisplayName =
                profile.displayName?
                    .trimmingCharacters(
                        in: .whitespacesAndNewlines
                    ) ?? ""

            let cleanLocation =
                profile.location?
                    .trimmingCharacters(
                        in: .whitespacesAndNewlines
                    ) ?? ""

            let cleanBio =
                profile.bio?
                    .trimmingCharacters(
                        in: .whitespacesAndNewlines
                    ) ?? ""

            let hasBirthDate =
                ProfileService.date(
                    from: profile.birthDate
                ) != nil

            let hasExistingProfileData =
                !cleanFirstName.isEmpty ||
                !cleanLastName.isEmpty ||
                !cleanUsername.isEmpty ||
                !cleanDisplayName.isEmpty ||
                !cleanLocation.isEmpty ||
                !cleanBio.isEmpty ||
                hasBirthDate ||
                profile.profilePhotoPath != nil

            mode =
                hasExistingProfileData
                    ? .update
                    : .create

            firstName = cleanFirstName
            lastName = cleanLastName
            username = cleanUsername
            location = cleanLocation
            bio = cleanBio

            hadExistingFirstName =
                !cleanFirstName.isEmpty

            hadExistingLastName =
                !cleanLastName.isEmpty

            hadExistingUsername =
                !cleanUsername.isEmpty

            if let existingBirthDate =
                ProfileService.date(
                    from: profile.birthDate
                ) {

                birthDate = existingBirthDate
                hasExistingBirthDate = true

            } else {

                hasExistingBirthDate = false
            }

        } catch {

            mode = .create

            print(
                "PROFILE SETUP LOAD ERROR:",
                error.localizedDescription
            )
        }
    }


    // MARK: - Username Availability

    @MainActor
    private func checkUsernameAvailability()
        async {

        usernameAvailability = .unknown

        let cleanUsername =
            username.trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        // If this username already belongs to
        // this existing profile, do not check it
        // against itself.

        if mode == .update &&
            hadExistingUsername {

            return
        }

        guard cleanUsername.count >= 3 else {

            return
        }

        do {

            try await Task.sleep(
                for: .milliseconds(500)
            )

            usernameAvailability = .checking

            let isAvailable =
                try await ProfileService
                    .isUsernameAvailable(
                        cleanUsername
                    )

            usernameAvailability =
                isAvailable
                    ? .available
                    : .taken

        } catch is CancellationError {

            // User is still typing.

        } catch {

            usernameAvailability = .unknown

            print(
                "USERNAME AVAILABILITY ERROR:",
                error.localizedDescription
            )
        }
    }


    // MARK: - Age Check

    private func isAtLeast13(
        _ birthDate: Date
    ) -> Bool {

        guard
            let cutoff =
                Calendar.current.date(
                    byAdding: .year,
                    value: -13,
                    to: Date()
                )
        else {

            return false
        }

        return birthDate <= cutoff
    }


    // MARK: - Load Photo

    @MainActor
    private func loadSelectedPhoto(
        _ item: PhotosPickerItem
    ) async {

        do {

            profilePhotoData =
                try await item.loadTransferable(
                    type: Data.self
                )

        } catch {

            errorMessage =
                "Unable to load the selected photo."

            isShowingErrorAlert = true
        }
    }


    // MARK: - Username Availability View

    private var usernameAvailabilityView:
        some View {

        Group {

            switch usernameAvailability {

            case .unknown:

                EmptyView()

            case .checking:

                Text(
                    "Checking availability..."
                )
                .font(KinTypography.caption)
                .foregroundStyle(
                    KinColors.secondaryText
                )

            case .available:

                Label(
                    "Username is available",
                    systemImage:
                        "checkmark.circle.fill"
                )
                .font(KinTypography.caption)
                .foregroundStyle(
                    KinColors.success
                )

            case .taken:

                Label(
                    "Username is already taken",
                    systemImage:
                        "xmark.circle.fill"
                )
                .font(KinTypography.caption)
                .foregroundStyle(
                    KinColors.error
                )
            }
        }
        .frame(
            maxWidth: .infinity,
            alignment: .leading
        )
    }
}


// MARK: - Preview

#Preview {

    ProfileSetupView {

        print("Profile completed")
    }
}

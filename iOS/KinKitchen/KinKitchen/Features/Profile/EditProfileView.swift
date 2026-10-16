//
//  EditProfileView.swift
//  KinKitchen
//
//  Created by Greg Hudler on 8/27/26.
//

import SwiftUI
import PhotosUI

/// Edit Profile, styled like the Profile page: the photo fading into
/// navy across the top (with Change Photo), then the details in cards
/// on a cream sheet.
struct EditProfileView: View {

    @Environment(\.dismiss) private var dismiss

    /// The photo already showing on Profile, so it appears right away.
    var currentPhotoData: Data? = nil

    @State private var firstName = ""
    @State private var lastName = ""
    @State private var displayName = ""
    @State private var username = ""
    @State private var location = ""
    @State private var birthDate = Date()
    @State private var bio = ""

    // MARK: Photo

    @State private var selectedPhotoItem: PhotosPickerItem?
    /// Picked but not saved yet; uploaded with Save, dropped on Cancel.
    @State private var newPhotoData: Data?

    @State private var errorMessage: String?
    @State private var isLoading = true
    @State private var isSaving = false

    private static let heroNavy =
        Color(red: 0.07, green: 0.10, blue: 0.17)

    private var shownPhotoData: Data? {
        newPhotoData ?? currentPhotoData
    }

    var body: some View {

        ScrollView {

            VStack(spacing: 0) {

                hero

                VStack(spacing: KinSpacing.medium) {

                    if isLoading {
                        KinLoadingView(message: "Loading profile...")
                            .frame(minHeight: 280)
                    } else {
                        profileForm
                    }
                }
                .padding(KinSpacing.large)
                .padding(.top, KinSpacing.small)
                .padding(.bottom, KinSpacing.xxLarge)
                .frame(maxWidth: .infinity)
                .background(
                    UnevenRoundedRectangle(
                        topLeadingRadius: KinRadius.xLarge,
                        topTrailingRadius: KinRadius.xLarge
                    )
                    .fill(KinColors.paper)
                    .shadow(color: .black.opacity(0.12), radius: 10, y: -2)
                )
                .padding(.top, -KinSpacing.xLarge)
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .background(KinColors.paper.ignoresSafeArea())
        .task {
            await loadProfile()
        }
        .onChange(of: selectedPhotoItem) { _, item in
            guard let item else {
                return
            }
            Task {
                await loadPickedPhoto(item)
            }
        }
    }


    // MARK: - Hero

    private var hero: some View {

        VStack(alignment: .leading, spacing: KinSpacing.medium) {

            // Cancel and Save, like the Edit pill on Profile.
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .font(KinTypography.subheadline)
                .foregroundStyle(.white)
                .padding(.horizontal, KinSpacing.medium)
                .padding(.vertical, KinSpacing.small)
                .background(.black.opacity(0.35), in: Capsule())

                Spacer()

                Button {
                    Task {
                        await saveProfile()
                    }
                } label: {
                    Group {
                        if isSaving {
                            ProgressView()
                                .tint(KinColors.primary)
                        } else {
                            Label("Save", systemImage: KinIcons.check)
                        }
                    }
                    .font(KinTypography.subheadline)
                    .foregroundStyle(KinColors.primary)
                    .padding(.horizontal, KinSpacing.medium)
                    .padding(.vertical, KinSpacing.small)
                    .background(.white, in: Capsule())
                    .kinFloatingShadow()
                }
                .buttonStyle(.kinPressable)
                .disabled(isSaving || isLoading)
            }

            Spacer(minLength: KinSpacing.large)

            HStack(alignment: .bottom) {

                PhotosPicker(
                    selection: $selectedPhotoItem,
                    matching: .images
                ) {
                    Label(
                        shownPhotoData == nil ? "Add Photo" : "Change Photo",
                        systemImage: KinIcons.camera
                    )
                    .font(KinTypography.footnote.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, KinSpacing.medium)
                    .padding(.vertical, KinSpacing.small)
                    .background(.black.opacity(0.45), in: Capsule())
                }
                .buttonStyle(.kinPressable)

                Spacer()

                VStack(alignment: .trailing, spacing: KinSpacing.xxSmall) {
                    Text("Edit Profile")
                        .font(KinTypography.title)
                        .foregroundStyle(.white)
                        .accessibilityAddTraits(.isHeader)

                    if newPhotoData != nil {
                        Text("New photo saves with your changes")
                            .font(KinTypography.caption)
                            .foregroundStyle(.white.opacity(0.75))
                    }
                }
            }
        }
        .padding(.horizontal, KinSpacing.large)
        .padding(.top, KinSpacing.large)
        .padding(.bottom, KinSpacing.xLarge + KinSpacing.large)
        .frame(height: 280)
        .background {
            Self.heroNavy
                .overlay(alignment: .leading) {
                    GeometryReader { proxy in
                        Group {
                            if let shownPhotoData,
                               let image = UIImage(data: shownPhotoData) {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill()
                            } else {
                                KinPhotoPlaceholder(
                                    icon: KinIcons.profile,
                                    iconSize: 56
                                )
                                .background(KinColors.paper)
                            }
                        }
                        .frame(
                            width: proxy.size.width * 0.62,
                            height: proxy.size.height,
                            alignment: .top
                        )
                        .clipped()
                    }
                }
                .overlay {
                    LinearGradient(
                        stops: [
                            .init(color: Self.heroNavy.opacity(0), location: 0.18),
                            .init(color: Self.heroNavy.opacity(0.75), location: 0.42),
                            .init(color: Self.heroNavy, location: 0.58),
                            .init(color: Self.heroNavy, location: 1)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                }
                .accessibilityHidden(true)
        }
    }


    // MARK: - Form

    private var profileForm: some View {

        VStack(spacing: KinSpacing.medium) {

            formCard(
                title: "Name",
                systemImage: "person.fill",
                tint: KinColors.primary
            ) {
                field("First Name", text: $firstName)
                divider
                field("Last Name", text: $lastName)
                divider
                field("Display Name", text: $displayName)
            }

            formCard(
                title: "Account",
                systemImage: "at",
                tint: KinColors.warning
            ) {
                field("Username", text: $username, prefix: "@")
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                divider
                field("Location", text: $location, systemImage: "mappin.and.ellipse")
                divider
                HStack {
                    Label("Birthday", systemImage: "gift")
                        .font(KinTypography.body)
                        .foregroundStyle(KinColors.secondaryText)

                    Spacer()

                    DatePicker(
                        "Birthday",
                        selection: $birthDate,
                        in: allowedBirthDateRange,
                        displayedComponents: .date
                    )
                    .labelsHidden()
                    .datePickerStyle(.compact)
                    .tint(KinColors.primary)
                }
                .padding(.vertical, KinSpacing.xSmall)
            }

            // Like the Bio on Profile: leaf, heading, text.
            formCard(
                title: "Bio",
                systemImage: "leaf.fill",
                tint: KinColors.success
            ) {
                ZStack(alignment: .topLeading) {
                    if bio.isEmpty {
                        Text("Tell your family a little about you.")
                            .font(KinTypography.callout)
                            .foregroundStyle(KinColors.secondaryText.opacity(0.7))
                            .padding(.top, 8)
                            .padding(.leading, 5)
                            .allowsHitTesting(false)
                    }

                    TextEditor(text: $bio)
                        .font(KinTypography.callout)
                        .foregroundStyle(KinColors.primaryText)
                        .scrollContentBackground(.hidden)
                        .frame(minHeight: 110)
                }
            }

            if let errorMessage {
                Text(errorMessage)
                    .font(KinTypography.caption)
                    .foregroundStyle(KinColors.error)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            KinPrimaryButton(
                title: isSaving ? "Saving..." : "Save Changes"
            ) {
                Task {
                    await saveProfile()
                }
            }
            .disabled(isSaving)
            .padding(.top, KinSpacing.small)
        }
    }

    /// A white card with a tinted icon and heading, like the rows on
    /// Profile.
    private func formCard<Content: View>(
        title: String,
        systemImage: String,
        tint: Color,
        @ViewBuilder content: () -> Content
    ) -> some View {

        VStack(alignment: .leading, spacing: KinSpacing.small) {

            Label {
                Text(title)
                    .font(KinTypography.headline)
                    .foregroundStyle(KinColors.primaryText)
            } icon: {
                Image(systemName: systemImage)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(tint)
                    .frame(width: 30, height: 30)
                    .background(
                        tint.opacity(0.14),
                        in: RoundedRectangle(cornerRadius: KinRadius.small)
                    )
            }
            .accessibilityAddTraits(.isHeader)

            VStack(alignment: .leading, spacing: 0) {
                content()
            }
        }
        .padding(KinSpacing.medium)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            KinColors.surface,
            in: RoundedRectangle(cornerRadius: KinRadius.large)
        )
        .kinCardShadow()
    }

    /// Label on the left, value on the right, like Settings.
    private func field(
        _ title: String,
        text: Binding<String>,
        prefix: String? = nil,
        systemImage: String? = nil
    ) -> some View {

        HStack(spacing: KinSpacing.small) {

            Group {
                if let systemImage {
                    Label(title, systemImage: systemImage)
                } else {
                    Text(title)
                }
            }
            .font(KinTypography.body)
            .foregroundStyle(KinColors.secondaryText)
            .layoutPriority(1)

            Spacer(minLength: KinSpacing.small)

            // The "@" sits right against the username.
            HStack(spacing: 1) {
                if let prefix {
                    Text(prefix)
                        .font(KinTypography.body)
                        .foregroundStyle(KinColors.secondaryText)
                }

                TextField(title, text: text)
                    .font(KinTypography.body)
                    .foregroundStyle(KinColors.primaryText)
                    .multilineTextAlignment(.trailing)
                    .fixedSize(horizontal: prefix != nil, vertical: false)
            }
        }
        .padding(.vertical, KinSpacing.small)
    }

    private var divider: some View {
        Divider()
            .overlay(KinColors.secondaryText.opacity(0.15))
    }


    // MARK: - Photo

    @MainActor
    private func loadPickedPhoto(
        _ item: PhotosPickerItem
    ) async {

        defer {
            selectedPhotoItem = nil
        }

        do {
            guard let picked = try await item.loadTransferable(type: Data.self),
                  let data = await KinPhotoResizer.prepared(picked) else {
                errorMessage = "Unable to load the selected photo."
                return
            }
            withAnimation(.easeInOut(duration: 0.25)) {
                newPhotoData = data
            }
        } catch {
            errorMessage = "Unable to load the selected photo."
            print("PROFILE PHOTO PICK ERROR:", error.localizedDescription)
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
            if let newPhotoData {
                _ = try await ProfileService.uploadProfilePhoto(newPhotoData)
            }

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

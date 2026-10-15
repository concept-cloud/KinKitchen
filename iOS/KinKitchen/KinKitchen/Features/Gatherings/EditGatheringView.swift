//
//  EditGatheringView.swift
//  KinKitchen
//
//  Created by Greg Hudler on 9/10/26.
//

import SwiftUI
import PhotosUI
import UIKit
import Supabase


struct EditGatheringView: View {

    @Environment(\.dismiss) private var dismiss

    let gathering: Gathering

    // MARK: - Gathering Fields

    @State private var name: String
    @State private var theme: String
    @State private var date: Date
    @State private var time: Date
    @State private var location: String
    @State private var description: String
    @State private var guestLimit: Int?
    @State private var coverImagePath: String?

    // MARK: - Photo

    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var selectedImageData: Data?
    @State private var isPhotoPickerPresented = false

    // MARK: - UI State

    @State private var isSaving = false
    @State private var isCancelling = false
    @State private var errorMessage: String?

    @State private var isDatePickerExpanded = false
    @State private var isTimePickerExpanded = false

    @State private var showCancelConfirmation = false
    @State private var showDeleteConfirmation = false
    @State private var isDeleting = false
    @State private var deleteErrorMessage: String?

    /// Called after the gathering is permanently deleted, so the
    /// screen underneath can close instead of showing it.
    let onDeleted: () -> Void


    // MARK: - Init

    init(
        gathering: Gathering,
        onDeleted: @escaping () -> Void = {}
    ) {
        self.onDeleted = onDeleted

        self.gathering = gathering

        _name = State(
            initialValue:
                gathering.name
        )

        _theme = State(
            initialValue:
                gathering.theme ?? ""
        )

        _date = State(
            initialValue:
                gathering.startsAt
        )

        _time = State(
            initialValue:
                gathering.startsAt
        )

        _location = State(
            initialValue:
                gathering.location ?? ""
        )

        _description = State(
            initialValue:
                gathering.description ?? ""
        )

        _guestLimit = State(
            initialValue:
                gathering.guestLimit
        )

        _coverImagePath = State(
            initialValue:
                gathering.coverImagePath
        )
    }


    // MARK: - Body

    var body: some View {

        ZStack {

            KinColors.background
                .ignoresSafeArea()

            ScrollView(
                showsIndicators: false
            ) {

                VStack(
                    alignment: .leading,
                    spacing: KinSpacing.xLarge
                ) {

                    header

                    gatheringPhoto

                    gatheringForm

                    if let errorMessage {

                        Text(
                            errorMessage
                        )
                        .font(
                            KinTypography.body
                        )
                        .foregroundStyle(
                            KinColors.error
                        )
                    }

                    saveButton

                    // Once it has started it's on its way to Gathering
                    // History; the database refuses cancel and delete.
                    if gathering.canBeCancelled() {
                        cancelSection
                    } else {
                        startedNotice
                    }
                }
                .padding(
                    KinSpacing.large
                )
            }
        }
        .navigationBarHidden(true)

        .onChange(
            of: selectedPhotoItem
        ) { _, newItem in

            guard let newItem else {
                return
            }

            Task {

                await loadSelectedPhoto(
                    newItem
                )
            }
        }

        // Centered alerts so the safe choice is always visible.
        .alert(
            "Cancel \"\(gathering.name)\"?",
            isPresented:
                $showCancelConfirmation
        ) {

            Button(
                "Keep Event",
                role: .cancel
            ) {}

            Button(
                "Cancel Event",
                role: .destructive
            ) {

                Task {

                    await cancelGathering()
                }
            }

        } message: {

            Text(
                "Everyone invited will be told it's cancelled. Guests, dishes and claims are kept, and you can delete it later."
            )
        }
        .deleteConfirmation(
            "Delete \"\(gathering.name)\"?",
            isPresented:
                $showDeleteConfirmation,
            message: "This permanently deletes the event, its guest list, dishes and claims. Guests will be told it was removed. Recipes are not deleted. This can't be undone."
        ) {

            Task {

                await deleteGathering()
            }
        }
        .deleteFailedAlert(
            $deleteErrorMessage
        )
        .deletingOverlay(
            isDeleting
        )
    }
}


// MARK: - Header

private extension EditGatheringView {

    var header: some View {

        ZStack {

            Text(
                "Edit Event"
            )
            .font(
                KinTypography.title
            )
            .foregroundStyle(
                KinColors.primaryText
            )

            HStack {

                Button {

                    dismiss()

                } label: {

                    Image(
                        systemName:
                            "chevron.left"
                    )
                    .font(
                        .system(
                            size: 20,
                            weight: .semibold
                        )
                    )
                    .foregroundStyle(
                        KinColors.primaryText
                    )
                    .frame(
                        width: 48,
                        height: 48
                    )
                    .background(
                        KinColors.surface
                    )
                    .clipShape(
                        Circle()
                    )
                }
                .buttonStyle(
                    .plain
                )

                Spacer()
            }
        }
    }
}


// MARK: - Gathering Photo

private extension EditGatheringView {

    var gatheringPhoto: some View {

        Button {

            isPhotoPickerPresented = true

        } label: {

            ZStack {

                RoundedRectangle(
                    cornerRadius:
                        KinRadius.medium
                )
                .fill(
                    KinColors.surface
                )

                if
                    let selectedImageData,
                    let image =
                        UIImage(
                            data:
                                selectedImageData
                        )
                {

                    Image(
                        uiImage: image
                    )
                    .resizable()
                    .scaledToFill()
                    .frame(
                        maxWidth: .infinity
                    )
                    .frame(
                        height: 210
                    )
                    .clipped()

                } else if
                    let coverImagePath,
                    !coverImagePath.isEmpty
                {

                    ExistingGatheringPhoto(
                        path:
                            coverImagePath
                    )

                } else {

                    emptyPhotoState
                }


                VStack {

                    Spacer()

                    HStack {

                        Spacer()

                        Image(
                            systemName:
                                "camera.fill"
                        )
                        .font(
                            .system(
                                size: 16,
                                weight:
                                    .semibold
                            )
                        )
                        .foregroundStyle(
                            .white
                        )
                        .padding(
                            KinSpacing.medium
                        )
                        .background(
                            .black.opacity(
                                0.55
                            )
                        )
                        .clipShape(
                            Circle()
                        )
                        .padding(
                            KinSpacing.medium
                        )
                    }
                }
            }
            .frame(
                maxWidth: .infinity
            )
            .frame(
                height: 210
            )
            .clipShape(
                RoundedRectangle(
                    cornerRadius:
                        KinRadius.medium
                )
            )
            .contentShape(
                RoundedRectangle(
                    cornerRadius:
                        KinRadius.medium
                )
            )
        }
        .buttonStyle(.plain)
        .photosPicker(
            isPresented:
                $isPhotoPickerPresented,
            selection:
                $selectedPhotoItem,
            matching:
                .images
        )
    }


    var emptyPhotoState: some View {

        VStack(
            spacing:
                KinSpacing.medium
        ) {

            Image(
                systemName:
                    "photo.badge.plus"
            )
            .font(
                .system(
                    size: 38
                )
            )
            .foregroundStyle(
                KinColors.primary
            )

            Text(
                "Add Event Photo"
            )
            .font(
                KinTypography.headline
            )
            .foregroundStyle(
                KinColors.primaryText
            )

            Text(
                "Choose a photo for your event"
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

    var emptyPhotoState: some View {

        VStack(
            spacing:
                KinSpacing.medium
        ) {

            Image(
                systemName:
                    "photo.badge.plus"
            )
            .font(
                .system(
                    size: 38
                )
            )
            .foregroundStyle(
                KinColors.primary
            )

            Text(
                "Add Event Photo"
            )
            .font(
                KinTypography.headline
            )
            .foregroundStyle(
                KinColors.primaryText
            )

            Text(
                "Choose a photo for your event"
            )
            .font(
                KinTypography.caption
            )
            .foregroundStyle(
                KinColors.secondaryText
            )
        }
    }



// MARK: - Form

private extension EditGatheringView {

    var gatheringForm: some View {

        VStack(
            alignment: .leading,
            spacing: KinSpacing.large
        ) {

            // MARK: Name

            fieldLabel(
                "Event Name"
            )

            KinTextField(
                title:
                    "Event Name",
                text:
                    $name
            )


            // MARK: Theme

            fieldLabel(
                "Theme"
            )

            KinTextField(
                title:
                    "Theme (Optional)",
                text:
                    $theme
            )


            // MARK: Date

            dateSection


            // MARK: Time

            timeSection


            // MARK: Location

            fieldLabel(
                "Location"
            )

            KinTextField(
                title:
                    "Location",
                text:
                    $location
            )


            // MARK: Description

            fieldLabel(
                "Description"
            )

            KinTextEditor(
                text:
                    $description
            )


            // MARK: Guest Limit

            guestLimitSection
        }
    }


    func fieldLabel(
        _ title: String
    ) -> some View {

        Text(
            title
        )
        .font(
            KinTypography.headline
        )
        .foregroundStyle(
            KinColors.primaryText
        )
    }
}


// MARK: - Date

private extension EditGatheringView {

    var dateSection: some View {

        VStack(
            alignment: .leading,
            spacing: KinSpacing.small
        ) {

            fieldLabel(
                "Date"
            )


            Button {

                withAnimation {

                    isDatePickerExpanded
                        .toggle()

                    isTimePickerExpanded =
                        false
                }

            } label: {

                HStack {

                    Text(
                        date.formatted(
                            date: .long,
                            time: .omitted
                        )
                    )
                    .font(
                        KinTypography.body
                    )
                    .foregroundStyle(
                        KinColors.primaryText
                    )

                    Spacer()

                    Image(
                        systemName:
                            isDatePickerExpanded
                            ? "chevron.up"
                            : "calendar"
                    )
                    .foregroundStyle(
                        KinColors.primary
                    )
                }
                .padding(
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
            .buttonStyle(
                .plain
            )


            if isDatePickerExpanded {

                VStack(
                    spacing:
                        KinSpacing.medium
                ) {

                    DatePicker(
                        "",
                        selection:
                            $date,
                        displayedComponents:
                            .date
                    )
                    .datePickerStyle(
                        .graphical
                    )
                    .labelsHidden()
                    .tint(
                        KinColors.primary
                    )


                    HStack {

                        Spacer()

                        Button {

                            withAnimation {

                                isDatePickerExpanded =
                                    false
                            }

                        } label: {

                            Image(
                                systemName:
                                    "checkmark.circle.fill"
                            )
                            .font(
                                .system(
                                    size: 30
                                )
                            )
                            .foregroundStyle(
                                KinColors.primary
                            )
                        }
                        .buttonStyle(
                            .plain
                        )
                        .accessibilityLabel(
                            "Set Date"
                        )
                    }
                }
                .padding(
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
        }
    }
}


// MARK: - Time

private extension EditGatheringView {

    var timeSection: some View {

        VStack(
            alignment: .leading,
            spacing: KinSpacing.small
        ) {

            fieldLabel(
                "Time"
            )


            Button {

                withAnimation {

                    isTimePickerExpanded
                        .toggle()

                    isDatePickerExpanded =
                        false
                }

            } label: {

                HStack {

                    Text(
                        time.formatted(
                            date: .omitted,
                            time: .shortened
                        )
                    )
                    .font(
                        KinTypography.body
                    )
                    .foregroundStyle(
                        KinColors.primaryText
                    )

                    Spacer()

                    Image(
                        systemName:
                            isTimePickerExpanded
                            ? "chevron.up"
                            : "clock"
                    )
                    .foregroundStyle(
                        KinColors.primary
                    )
                }
                .padding(
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
            .buttonStyle(
                .plain
            )


            if isTimePickerExpanded {

                VStack(
                    spacing:
                        KinSpacing.medium
                ) {

                    DatePicker(
                        "",
                        selection:
                            $time,
                        displayedComponents:
                            .hourAndMinute
                    )
                    .datePickerStyle(
                        .wheel
                    )
                    .labelsHidden()
                    .tint(
                        KinColors.primary
                    )


                    HStack {

                        Spacer()

                        Button {

                            withAnimation {

                                isTimePickerExpanded =
                                    false
                            }

                        } label: {

                            Image(
                                systemName:
                                    "checkmark.circle.fill"
                            )
                            .font(
                                .system(
                                    size: 30
                                )
                            )
                            .foregroundStyle(
                                KinColors.primary
                            )
                        }
                        .buttonStyle(
                            .plain
                        )
                        .accessibilityLabel(
                            "Set Time"
                        )
                    }
                }
                .padding(
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
        }
    }
}


// MARK: - Guest Limit

private extension EditGatheringView {

    var guestLimitSection: some View {

        VStack(
            alignment: .leading,
            spacing: KinSpacing.small
        ) {

            HStack {

                VStack(
                    alignment: .leading,
                    spacing: 2
                ) {

                    Text(
                        "Guest Limit"
                    )
                    .font(
                        KinTypography.headline
                    )
                    .foregroundStyle(
                        KinColors.primaryText
                    )

                    Text(
                        "Optional"
                    )
                    .font(
                        KinTypography.caption
                    )
                    .foregroundStyle(
                        KinColors.secondaryText
                    )
                }


                Spacer()


                HStack(
                    spacing:
                        KinSpacing.large
                ) {

                    // MARK: Minus

                    Button {

                        decreaseGuestLimit()

                    } label: {

                        Image(
                            systemName:
                                "minus"
                        )
                        .frame(
                            width: 30,
                            height: 30
                        )
                    }
                    .buttonStyle(
                        .plain
                    )


                    Text(
                        guestLimit.map {
                            String($0)
                        } ?? "—"
                    )
                    .font(
                        KinTypography.body
                    )
                    .foregroundStyle(
                        KinColors.primaryText
                    )
                    .frame(
                        minWidth: 28
                    )


                    // MARK: Plus

                    Button {

                        increaseGuestLimit()

                    } label: {

                        Image(
                            systemName:
                                "plus"
                        )
                        .frame(
                            width: 30,
                            height: 30
                        )
                    }
                    .buttonStyle(
                        .plain
                    )
                }
                .foregroundStyle(
                    KinColors.primaryText
                )
                .padding(
                    KinSpacing.small
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
        }
    }


    func increaseGuestLimit() {

        if let guestLimit {

            self.guestLimit =
                guestLimit + 1

        } else {

            guestLimit = 1
        }
    }


    func decreaseGuestLimit() {

        guard let guestLimit else {

            return
        }

        if guestLimit <= 1 {

            self.guestLimit =
                nil

        } else {

            self.guestLimit =
                guestLimit - 1
        }
    }
}


// MARK: - Save Button

private extension EditGatheringView {

    var saveButton: some View {

        KinPrimaryButton(
            title:
                isSaving
                ? "Saving..."
                : "Save Changes"
        ) {

            Task {

                await saveChanges()
            }
        }
        .disabled(
            isSaving ||
            isCancelling
        )
        .opacity(
            isSaving ||
            isCancelling
            ? 0.6
            : 1
        )
    }
}


// MARK: - Cancel Gathering

private extension EditGatheringView {

    var startedNotice: some View {

        Label(
            "This event has started, so it can't be cancelled or deleted. It will be kept in Event History.",
            systemImage: "clock.arrow.circlepath"
        )
        .font(
            KinTypography.caption
        )
        .foregroundStyle(
            KinColors.secondaryText
        )
        .padding(
            .top,
            KinSpacing.medium
        )
    }

    var cancelSection: some View {

        VStack(
            alignment: .leading,
            spacing: KinSpacing.medium
        ) {

            Divider()
                .padding(
                    .vertical,
                    KinSpacing.medium
                )


            Text(
                "Danger Zone"
            )
            .font(
                KinTypography.headline
            )
            .foregroundStyle(
                KinColors.error
            )


            Text(
                "Cancelling an event removes it from active events but preserves its record."
            )
            .font(
                KinTypography.caption
            )
            .foregroundStyle(
                KinColors.secondaryText
            )


            Button {

                showCancelConfirmation =
                    true

            } label: {

                HStack {

                    Spacer()


                    if isCancelling {

                        ProgressView()
                            .tint(
                                KinColors.error
                            )

                        Text(
                            "Cancelling..."
                        )

                    } else {

                        Image(
                            systemName:
                                "xmark.circle"
                        )

                        Text(
                            "Cancel Event"
                        )
                    }


                    Spacer()
                }
                .font(
                    KinTypography.button
                )
                .foregroundStyle(
                    KinColors.error
                )
                .padding(
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
                .overlay {

                    RoundedRectangle(
                        cornerRadius:
                            KinRadius.medium
                    )
                    .stroke(
                        KinColors.error,
                        lineWidth: 1
                    )
                }
            }
            .buttonStyle(
                .plain
            )
            .disabled(
                isSaving ||
                isCancelling ||
                isDeleting
            )


            Text(
                "Deleting removes the event and its guest list, dishes and claims for good. Your recipes are not affected."
            )
            .font(
                KinTypography.caption
            )
            .foregroundStyle(
                KinColors.secondaryText
            )
            .padding(
                .top,
                KinSpacing.small
            )


            Button {

                showDeleteConfirmation =
                    true

            } label: {

                HStack {

                    Spacer()

                    if isDeleting {

                        ProgressView()
                            .tint(.white)

                        Text(
                            "Deleting..."
                        )

                    } else {

                        Image(
                            systemName: "trash"
                        )

                        Text(
                            "Delete Event"
                        )
                    }

                    Spacer()
                }
                .font(
                    KinTypography.button
                )
                .foregroundStyle(
                    .white
                )
                .padding(
                    KinSpacing.medium
                )
                .background(
                    KinColors.error
                )
                .clipShape(
                    RoundedRectangle(
                        cornerRadius:
                            KinRadius.medium
                    )
                )
            }
            .buttonStyle(
                .plain
            )
            .disabled(
                isSaving ||
                isCancelling ||
                isDeleting
            )
        }
        .padding(
            .bottom,
            KinSpacing.xLarge
        )
    }
}


// MARK: - Save Gathering

private extension EditGatheringView {

    @MainActor
    func saveChanges() async {

        errorMessage = nil


        let cleanName =
            name.trimmingCharacters(
                in:
                    .whitespacesAndNewlines
            )


        guard !cleanName.isEmpty else {

            errorMessage =
                "Please enter an event name."

            return
        }


        let startsAt =
            combinedDateAndTime()


        guard startsAt > Date() else {

            errorMessage =
                "Please select a future date and time."

            return
        }


        isSaving = true


        defer {

            isSaving = false
        }


        do {

            var finalCoverImagePath =
                coverImagePath


            // Upload a replacement photo only
            // if the user actually selected one.

            if let selectedImageData {

                finalCoverImagePath =
                    try await uploadGatheringPhoto(
                        selectedImageData
                    )
            }


            let updatedGathering =
                try await GatheringService
                    .updateGathering(
                        id:
                            gathering.id,
                        name:
                            cleanName,
                        theme:
                            cleaned(
                                theme
                            ),
                        coverImagePath:
                            finalCoverImagePath,
                        description:
                            cleaned(
                                description
                            ),
                        location:
                            cleaned(
                                location
                            ),
                        startsAt:
                            startsAt,
                        guestLimit:
                            guestLimit
                    )


            coverImagePath =
                updatedGathering
                    .coverImagePath


            dismiss()

        } catch {

            errorMessage =
                "Unable to save event changes. Please try again."


            print(
                "EDIT GATHERING ERROR:",
                error.localizedDescription
            )
        }
    }
}


// MARK: - Cancel Gathering Action

private extension EditGatheringView {

    @MainActor
    func cancelGathering() async {

        isCancelling = true

        errorMessage = nil


        defer {

            isCancelling = false
        }


        do {

            _ =
                try await GatheringService
                    .cancelGathering(
                        id:
                            gathering.id
                    )


            dismiss()

        } catch {

            // Nothing changed; the gathering is still upcoming.
            errorMessage =
                GatheringService.friendlyMessage(
                    for: error,
                    fallback: "Unable to cancel this event. Please try again."
                )


            print(
                "CANCEL GATHERING ERROR:",
                error.localizedDescription
            )
        }
    }


    @MainActor
    func deleteGathering() async {

        guard !isDeleting else {
            return
        }

        isDeleting = true

        deleteErrorMessage = nil


        defer {

            isDeleting = false
        }


        do {

            try await GatheringService
                .deleteGathering(
                    id: gathering.id
                )

            onDeleted()
            dismiss()

        } catch is CancellationError {

            return

        } catch {

            // Nothing changed; the gathering and any unsaved edits
            // stay on screen.
            deleteErrorMessage =
                KinDeletion.failureMessage(
                    for: error,
                    deleting: .gathering
                )

            print(
                "DELETE GATHERING ERROR:",
                error.localizedDescription
            )
        }
    }

}


// MARK: - Photo Selection

private extension EditGatheringView {

    @MainActor
    func loadSelectedPhoto(
        _ item: PhotosPickerItem
    ) async {

        do {

            guard
                let imageData =
                    try await
                    item.loadTransferable(
                        type:
                            Data.self
                    )
            else {

                errorMessage =
                    "Unable to load the selected photo."

                return
            }


            selectedImageData =
                imageData


        } catch {

            errorMessage =
                "Unable to load the selected photo."


            print(
                "EDIT GATHERING PHOTO LOAD ERROR:",
                error.localizedDescription
            )
        }
    }
}


// MARK: - Upload Gathering Photo

private extension EditGatheringView {

    func uploadGatheringPhoto(
        _ imageData: Data
    ) async throws -> String {

        let user =
            try await
            SupabaseManager.client
                .auth
                .session
                .user


        guard
            let image =
                UIImage(
                    data:
                        imageData
                ),
            let jpegData =
                image.jpegData(
                    compressionQuality:
                        0.85
                )
        else {

            throw EditGatheringPhotoError
                .invalidImage
        }


        let fileName =
            "\(UUID().uuidString.lowercased()).jpg"


        let path =
            "\(user.id.uuidString.lowercased())/\(fileName)"


        try await
            SupabaseManager.client
                .storage
                .from(
                    "gathering-photos"
                )
                .upload(
                    path,
                    data:
                        jpegData,
                    options:
                        FileOptions(
                            contentType:
                                "image/jpeg",
                            upsert:
                                false
                        )
                )


        return path
    }
}


// MARK: - Date / Time Helper

private extension EditGatheringView {

    func combinedDateAndTime()
        -> Date {

        let calendar =
            Calendar.current


        let dateComponents =
            calendar.dateComponents(
                [
                    .year,
                    .month,
                    .day
                ],
                from:
                    date
            )


        let timeComponents =
            calendar.dateComponents(
                [
                    .hour,
                    .minute
                ],
                from:
                    time
            )


        var components =
            DateComponents()


        components.year =
            dateComponents.year

        components.month =
            dateComponents.month

        components.day =
            dateComponents.day

        components.hour =
            timeComponents.hour

        components.minute =
            timeComponents.minute


        return calendar.date(
            from:
                components
        ) ?? Date()
    }


    func cleaned(
        _ value: String
    ) -> String? {

        let cleanedValue =
            value.trimmingCharacters(
                in:
                    .whitespacesAndNewlines
            )


        return cleanedValue.isEmpty
            ? nil
            : cleanedValue
    }
}


// MARK: - Existing Gathering Photo

private struct ExistingGatheringPhoto: View {

    let path: String

    @State private var imageData: Data?
    @State private var failedToLoad = false


    var body: some View {

        ZStack {

            KinColors.surface


            if
                let imageData,
                let image =
                    UIImage(
                        data:
                            imageData
                    )
            {

                Image(
                    uiImage:
                        image
                )
                .resizable()
                .scaledToFill()


            } else if failedToLoad {

                Image(
                    systemName:
                        "photo"
                )
                .font(
                    .system(
                        size: 36
                    )
                )
                .foregroundStyle(
                    KinColors.secondaryText
                )


            } else {

                ProgressView()
                    .tint(
                        KinColors.primary
                    )
            }
        }
        .frame(
            maxWidth:
                .infinity
        )
        .frame(
            height: 210
        )
        .clipped()
        .task(
            id: path
        ) {

            await loadImage()
        }
    }


    @MainActor
    private func loadImage() async {

        failedToLoad =
            false


        do {

            imageData =
                try await
                SupabaseManager.client
                    .storage
                    .from(
                        "gathering-photos"
                    )
                    .download(
                        path:
                            path
                    )


        } catch {

            failedToLoad =
                true


            print(
                "EXISTING GATHERING PHOTO ERROR:",
                error.localizedDescription
            )
        }
    }
}


// MARK: - Photo Error

private enum EditGatheringPhotoError:
    LocalizedError {

    case invalidImage


    var errorDescription: String? {

        switch self {

        case .invalidImage:

            return
                "The selected event photo could not be processed."
        }
    }
}


// MARK: - Preview

#Preview {

    NavigationStack {

        EditGatheringView(
            gathering:
                Gathering(
                    id:
                        UUID(),
                    hostId:
                        UUID(),
                    name:
                        "Sunday Family Dinner",
                    theme:
                        "Family Night",
                    coverImagePath:
                        nil,
                    description:
                        "A relaxed family dinner.",
                    location:
                        "Hudler Home",
                    startsAt:
                        Date().addingTimeInterval(
                            86_400
                        ),
                    guestLimit:
                        8,
                    status:
                        .upcoming,
                    createdAt:
                        Date(),
                    updatedAt:
                        Date()
                )
        )
    }
}

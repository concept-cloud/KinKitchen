//
//  AddGatheringView.swift
//  KinKitchen
//
//  Created by Greg Hudler on 9/10/26.
//

import SwiftUI
import PhotosUI
import UIKit
import Supabase


/// Add Event, laid out like an invitation: the cover photo across the
/// top with the name typed right on it, then cards for the type, when,
/// where, dietary needs, details and guests on a cream sheet. Create
/// stays pinned at the bottom.
struct AddGatheringView: View {

    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var theme = ""
    @State private var eventType: KinEventType?
    @State private var dietaryNeeds: [EventDietaryNeed] = []

    /// Set once the event is made, so a retry after the dietary needs
    /// fail to save doesn't create it twice.
    @State private var createdGatheringId: UUID?
    @State private var date = EventDateChoices.defaultStart()
    @State private var time = EventDateChoices.defaultStart()
    @State private var location = ""
    @State private var description = ""
    @State private var guestLimit: Int?

    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var selectedImageData: Data?

    @State private var isSaving = false
    @State private var errorMessage: String?

    @State private var isCalendarShown = false

    /// Meal Train length in days, counting the first and last.
    @State private var rangeDays = 14
    @State private var isEndCalendarShown = false
    @State private var scrolledPastHero = false

    @FocusState private var focusedField: Field?

    enum Field {
        case name
        case location
        case theme
        case description
    }

    private static let heroHeight: CGFloat = 300

    private var isDateRange: Bool {
        eventType == .mealTrain
    }

    /// Last day, at the drop-off time; nil for one-day events.
    private var endsAt: Date? {
        isDateRange
            ? EventDateRange.lastDay(from: combinedDateAndTime(), days: rangeDays)
            : nil
    }

    private var cleanName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// What's still needed before Create, or nil when ready.
    private var missingText: String? {
        switch (cleanName.isEmpty, eventType == nil) {
        case (true, true): return "Add a name and pick an event type"
        case (true, false): return "Add a name for your event"
        case (false, true): return "Pick an event type"
        case (false, false): return nil
        }
    }


    var body: some View {

        GeometryReader { geometry in

            ScrollView {

                VStack(spacing: 0) {

                    hero(topInset: geometry.safeAreaInsets.top)

                    VStack(spacing: KinSpacing.medium) {

                        typeCard

                        whenCard

                        whereCard

                        EventFormCard(
                            title: "Dietary Needs",
                            systemImage: "heart.fill",
                            tint: DietarySection.allergens.tint
                        ) {
                            EventDietaryNeedsField(
                                needs: $dietaryNeeds,
                                eventType: eventType,
                                showsTitle: false
                            )
                        }

                        detailsCard

                        guestsCard
                    }
                    .padding(KinSpacing.large)
                    .padding(.top, KinSpacing.small)
                    .padding(.bottom, KinSpacing.large)
                    .frame(maxWidth: .infinity)
                    .background(
                        UnevenRoundedRectangle(
                            topLeadingRadius: KinRadius.xLarge,
                            topTrailingRadius: KinRadius.xLarge
                        )
                        .fill(KinColors.paper)
                        .shadow(color: .black.opacity(0.12), radius: 10, y: -2)
                    )
                    // Tucks up over the bottom of the photo.
                    .padding(.top, -KinSpacing.xLarge)
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .scrollEdgeEffectHidden(true, for: .top)
            .onScrollGeometryChange(for: Bool.self) { scroll in
                scroll.contentOffset.y > Self.heroHeight - 40
            } action: { _, isPast in
                withAnimation(.easeOut(duration: 0.2)) {
                    scrolledPastHero = isPast
                }
            }
            .ignoresSafeArea(edges: .top)
            // Cream behind the status bar once the photo scrolls away,
            // so the cards don't run under the clock.
            .overlay(alignment: .top) {
                KinColors.paper
                    .frame(height: geometry.safeAreaInsets.top)
                    .ignoresSafeArea(edges: .top)
                    .opacity(scrolledPastHero ? 1 : 0)
                    .allowsHitTesting(false)
            }
            .background(KinColors.paper.ignoresSafeArea())
            .safeAreaInset(edge: .bottom) {
                createBar
            }
        }
        .navigationBarHidden(true)
        .sensoryFeedback(.selection, trigger: eventType)
        .sensoryFeedback(.selection, trigger: combinedDateAndTime())
        .sensoryFeedback(.selection, trigger: rangeDays)
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
    }
}


// MARK: - Hero

private extension AddGatheringView {

    func hero(topInset: CGFloat) -> some View {

        VStack(alignment: .leading, spacing: KinSpacing.small) {

            HStack {

                Button("Cancel") {
                    dismiss()
                }
                .font(KinTypography.subheadline)
                .foregroundStyle(.white)
                .padding(.horizontal, KinSpacing.medium)
                .padding(.vertical, KinSpacing.small)
                .background(.black.opacity(0.35), in: Capsule())
                .buttonStyle(.kinPressable)

                Spacer()

                PhotosPicker(
                    selection: $selectedPhotoItem,
                    matching: .images
                ) {
                    Label(
                        selectedImageData == nil ? "Add Cover" : "Change Cover",
                        systemImage: KinIcons.camera
                    )
                    .font(KinTypography.footnote.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, KinSpacing.medium)
                    .padding(.vertical, KinSpacing.small)
                    .background(.black.opacity(0.35), in: Capsule())
                }
                .buttonStyle(.kinPressable)
            }

            Spacer(minLength: KinSpacing.medium)

            Group {
                if let eventType {
                    Label(eventType.title, systemImage: eventType.symbol)
                } else {
                    Label("New Event", systemImage: "sparkles")
                }
            }
            .font(.system(size: 12, weight: .bold))
            .textCase(.uppercase)
            .foregroundStyle(.white.opacity(0.9))
            .contentTransition(.opacity)
            .animation(.snappy, value: eventType)

            // The name is typed right on the cover, like an invitation.
            TextField(
                "Event Name",
                text: $name,
                prompt: Text("Name your event")
                    .foregroundStyle(.white.opacity(0.6)),
                axis: .vertical
            )
            .font(KinTypography.title)
            .foregroundStyle(.white)
            .tint(.white)
            .lineLimit(1...2)
            .submitLabel(.done)
            .focused($focusedField, equals: .name)
            .onChange(of: name) { _, newValue in
                // Return closes the keyboard instead of a new line.
                if newValue.contains("\n") {
                    name = newValue.replacingOccurrences(of: "\n", with: "")
                    focusedField = nil
                }
            }
            .accessibilityLabel("Event Name")

            Rectangle()
                .fill(.white.opacity(focusedField == .name ? 0.9 : 0.4))
                .frame(height: 1.5)
                .animation(.easeOut(duration: 0.2), value: focusedField)

            Label(heroSummary, systemImage: KinIcons.calendar)
                .font(KinTypography.footnote.weight(.semibold))
                .foregroundStyle(.white.opacity(0.9))
                .lineLimit(1)
                .padding(.top, KinSpacing.xxSmall)
        }
        .kinTextOnPhoto()
        .padding(.horizontal, KinSpacing.large)
        .padding(.top, topInset + KinSpacing.small)
        .padding(.bottom, KinSpacing.xLarge + KinSpacing.large)
        .frame(height: Self.heroHeight + topInset)
        .background {
            heroBackground
                .accessibilityHidden(true)
        }
        .clipped()
    }

    var heroSummary: String {
        let start = combinedDateAndTime()
        let when = endsAt.map {
            EventDateRange.rangeText(from: start, to: $0)
                + " · " + EventDateRange.lengthText(rangeDays)
        } ?? start.formatted(.dateTime.weekday(.wide).month(.abbreviated).day())
            + " at " + start.formatted(date: .omitted, time: .shortened)
        let place = location.trimmingCharacters(in: .whitespacesAndNewlines)
        return place.isEmpty ? when : "\(when) · \(place)"
    }

    var heroBackground: some View {

        Color.clear
            .overlay {
                if let selectedImageData,
                   let image = UIImage(data: selectedImageData) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .transition(.opacity)
                } else {
                    // Warm placeholder with the type's icon.
                    LinearGradient(
                        colors: [
                            KinColors.primary,
                            KinColors.accent.opacity(0.85)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .overlay(alignment: .topTrailing) {
                        Image(systemName: eventType?.symbol ?? KinIcons.gatherings)
                            .font(.system(size: 150, weight: .bold))
                            .foregroundStyle(.white.opacity(0.14))
                            .rotationEffect(.degrees(-12))
                            .offset(x: 30, y: 50)
                            .contentTransition(.symbolEffect(.replace))
                            .animation(.snappy, value: eventType)
                    }
                }
            }
            .overlay {
                LinearGradient(
                    stops: [
                        .init(color: .black.opacity(0.35), location: 0),
                        .init(color: .clear, location: 0.3),
                        .init(color: .clear, location: 0.45),
                        .init(color: .black.opacity(0.6), location: 1)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
            .clipped()
            .animation(.easeInOut(duration: 0.25), value: selectedImageData)
    }
}


// MARK: - Type

private extension AddGatheringView {

    var typeCard: some View {

        EventFormCard(
            title: "What kind of event?",
            systemImage: "sparkles",
            tint: KinColors.primary
        ) {
            KinEventTypePicker(
                selection: $eventType
            )
        }
    }
}


// MARK: - When

private extension AddGatheringView {

    var whenCard: some View {

        EventFormCard(
            title: "When",
            systemImage: KinIcons.calendar,
            tint: KinColors.warning,
            subtitle: whenSummary
        ) {

            VStack(alignment: .leading, spacing: KinSpacing.medium) {

                if isDateRange {
                    rowLabel("First Day")
                }

                chipRow {
                    ForEach(EventDateChoices.quickDates(), id: \.self) { choice in
                        EventChoiceChip(
                            title: choice.title,
                            isSelected: !isCalendarShown
                                && Calendar.current.isDate(date, inSameDayAs: choice.date)
                        ) {
                            withAnimation(.snappy) {
                                date = choice.date
                                isCalendarShown = false
                            }
                        }
                    }

                    EventChoiceChip(
                        title: "Pick a Date",
                        systemImage: KinIcons.calendar,
                        isSelected: isCalendarShown || !isQuickDate
                    ) {
                        withAnimation(.snappy) {
                            isCalendarShown.toggle()
                        }
                    }
                }

                if isCalendarShown {
                    DatePicker(
                        "Date",
                        selection: $date,
                        in: Calendar.current.startOfDay(for: Date())...,
                        displayedComponents: .date
                    )
                    .datePickerStyle(.graphical)
                    .labelsHidden()
                    .tint(KinColors.primary)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }

                if isDateRange {
                    lastDaySection
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }

                Divider()
                    .overlay(KinColors.secondaryText.opacity(0.15))

                if isDateRange {
                    rowLabel("Drop-off Time Each Day")
                }

                HStack(spacing: KinSpacing.small) {

                    chipRow {
                        ForEach(EventDateChoices.quickHours, id: \.self) { hour in
                            let option = EventDateChoices.time(hour: hour, on: time)
                            EventChoiceChip(
                                title: option.formatted(.dateTime.hour()),
                                isSelected: isSameTime(time, option)
                            ) {
                                withAnimation(.snappy) {
                                    time = option
                                }
                            }
                        }
                    }

                    DatePicker(
                        "Time",
                        selection: $time,
                        displayedComponents: .hourAndMinute
                    )
                    .labelsHidden()
                    .datePickerStyle(.compact)
                    .tint(KinColors.primary)
                    .accessibilityLabel("Other time")
                }
            }
        }
    }

    var whenSummary: String {
        let start = combinedDateAndTime()
        guard let endsAt else {
            return start.formatted(.dateTime.weekday(.wide).month(.wide).day().hour().minute())
        }
        return EventDateRange.rangeText(from: start, to: endsAt)
            + " · " + start.formatted(date: .omitted, time: .shortened) + " drop-off"
    }

    func rowLabel(_ title: String) -> some View {
        Text(title)
            .font(KinTypography.caption.weight(.semibold))
            .textCase(.uppercase)
            .foregroundStyle(KinColors.secondaryText)
    }

    /// How long a Meal Train runs: quick lengths, or a last day from
    /// the calendar.
    var lastDaySection: some View {

        VStack(alignment: .leading, spacing: KinSpacing.medium) {

            Divider()
                .overlay(KinColors.secondaryText.opacity(0.15))

            rowLabel("How Long")

            chipRow {
                ForEach(EventDateRange.quickLengths, id: \.self) { days in
                    EventChoiceChip(
                        title: EventDateRange.lengthText(days),
                        isSelected: !isEndCalendarShown && rangeDays == days
                    ) {
                        withAnimation(.snappy) {
                            rangeDays = days
                            isEndCalendarShown = false
                        }
                    }
                }

                EventChoiceChip(
                    title: "Pick Last Day",
                    systemImage: KinIcons.calendar,
                    isSelected: isEndCalendarShown
                        || !EventDateRange.quickLengths.contains(rangeDays)
                ) {
                    withAnimation(.snappy) {
                        isEndCalendarShown.toggle()
                    }
                }
            }

            if isEndCalendarShown {
                DatePicker(
                    "Last Day",
                    selection: lastDayBinding,
                    in: date...,
                    displayedComponents: .date
                )
                .datePickerStyle(.graphical)
                .labelsHidden()
                .tint(KinColors.primary)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    /// The calendar edits the length, so the range keeps its length
    /// when the first day moves.
    var lastDayBinding: Binding<Date> {
        Binding(
            get: { EventDateRange.lastDay(from: date, days: rangeDays) },
            set: { rangeDays = EventDateRange.dayCount(from: date, to: $0) }
        )
    }

    var isQuickDate: Bool {
        EventDateChoices.quickDates().contains {
            Calendar.current.isDate(date, inSameDayAs: $0.date)
        }
    }

    func isSameTime(_ first: Date, _ second: Date) -> Bool {
        let calendar = Calendar.current
        return calendar.component(.hour, from: first) == calendar.component(.hour, from: second)
            && calendar.component(.minute, from: first) == calendar.component(.minute, from: second)
    }

    /// Chips that scroll sideways when they don't fit.
    func chipRow<Content: View>(
        @ViewBuilder content: () -> Content
    ) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: KinSpacing.small) {
                content()
            }
            .padding(.vertical, 2)
        }
        .scrollClipDisabled()
    }
}


// MARK: - Where

private extension AddGatheringView {

    var whereCard: some View {

        EventFormCard(
            title: "Where",
            systemImage: KinIcons.location,
            tint: KinColors.success
        ) {
            inputField(
                "Address or place, e.g. Grandma's house",
                text: $location,
                field: .location
            )
        }
    }

    func inputField(
        _ placeholder: String,
        text: Binding<String>,
        field: Field
    ) -> some View {

        TextField(placeholder, text: text)
            .font(KinTypography.body)
            .foregroundStyle(KinColors.primaryText)
            .focused($focusedField, equals: field)
            .submitLabel(.done)
            .padding(.horizontal, KinSpacing.medium)
            .padding(.vertical, KinSpacing.medium)
            .background(
                KinColors.background,
                in: RoundedRectangle(cornerRadius: KinRadius.medium)
            )
            .overlay {
                RoundedRectangle(cornerRadius: KinRadius.medium)
                    .strokeBorder(
                        focusedField == field
                            ? KinColors.primary.opacity(0.6)
                            : KinColors.secondaryText.opacity(0.15)
                    )
            }
            .animation(.easeOut(duration: 0.15), value: focusedField)
    }
}


// MARK: - Details

private extension AddGatheringView {

    var detailsCard: some View {

        EventFormCard(
            title: "Details",
            systemImage: "text.alignleft",
            tint: KinColors.secondary,
            subtitle: "Optional"
        ) {

            VStack(alignment: .leading, spacing: KinSpacing.medium) {

                inputField(
                    "Theme",
                    text: $theme,
                    field: .theme
                )

                chipRow {
                    ForEach((eventType ?? .other).themeSuggestions, id: \.self) { idea in
                        EventChoiceChip(
                            title: idea,
                            isSelected: theme == idea
                        ) {
                            withAnimation(.snappy) {
                                theme = theme == idea ? "" : idea
                            }
                        }
                    }
                }

                ZStack(alignment: .topLeading) {

                    if description.isEmpty {
                        Text("What should guests know? Parking, what to wear, the plan...")
                            .font(KinTypography.callout)
                            .foregroundStyle(KinColors.secondaryText.opacity(0.7))
                            .padding(.horizontal, KinSpacing.medium + 5)
                            .padding(.vertical, KinSpacing.medium + 8)
                            .allowsHitTesting(false)
                    }

                    TextEditor(text: $description)
                        .font(KinTypography.callout)
                        .foregroundStyle(KinColors.primaryText)
                        .scrollContentBackground(.hidden)
                        .focused($focusedField, equals: .description)
                        .padding(.horizontal, KinSpacing.medium)
                        .padding(.vertical, KinSpacing.small)
                        .frame(minHeight: 110)
                }
                .background(
                    KinColors.background,
                    in: RoundedRectangle(cornerRadius: KinRadius.medium)
                )
                .overlay {
                    RoundedRectangle(cornerRadius: KinRadius.medium)
                        .strokeBorder(
                            focusedField == .description
                                ? KinColors.primary.opacity(0.6)
                                : KinColors.secondaryText.opacity(0.15)
                        )
                }
            }
        }
    }
}


// MARK: - Guests

private extension AddGatheringView {

    var guestsCard: some View {

        EventFormCard(
            title: "Guests",
            systemImage: KinIcons.participants,
            tint: KinColors.primary
        ) {

            HStack(spacing: KinSpacing.medium) {

                VStack(alignment: .leading, spacing: KinSpacing.xxSmall) {
                    Text(guestLimit.map { "Up to \($0) guest\($0 == 1 ? "" : "s")" } ?? "No guest limit")
                        .font(KinTypography.body)
                        .foregroundStyle(KinColors.primaryText)
                        .contentTransition(.numericText())

                    Text("You'll invite people after creating it.")
                        .font(KinTypography.caption)
                        .foregroundStyle(KinColors.secondaryText)
                }

                Spacer(minLength: KinSpacing.small)

                stepperButton("minus", label: "Fewer guests", isEnabled: guestLimit != nil) {
                    decreaseGuestLimit()
                }

                stepperButton("plus", label: "More guests", isEnabled: true) {
                    increaseGuestLimit()
                }
            }
            .sensoryFeedback(.selection, trigger: guestLimit)
        }
    }

    func stepperButton(
        _ systemImage: String,
        label: String,
        isEnabled: Bool,
        action: @escaping () -> Void
    ) -> some View {

        Button {
            withAnimation(.snappy) {
                action()
            }
        } label: {
            Image(systemName: systemImage)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(isEnabled ? KinColors.primary : KinColors.secondaryText.opacity(0.4))
                .frame(width: 40, height: 40)
                .background(KinColors.primary.opacity(isEnabled ? 0.12 : 0.05), in: Circle())
        }
        .buttonStyle(.kinPressable)
        .disabled(!isEnabled)
        .accessibilityLabel(label)
    }

    func increaseGuestLimit() {
        guestLimit = (guestLimit ?? 0) + 1
    }

    /// Going below 1 means no limit.
    func decreaseGuestLimit() {
        guard let guestLimit else {
            return
        }
        self.guestLimit = guestLimit <= 1 ? nil : guestLimit - 1
    }
}


// MARK: - Create Bar

private extension AddGatheringView {

    /// Pinned at the bottom so Create is always in reach.
    var createBar: some View {

        VStack(spacing: KinSpacing.small) {

            if let errorMessage {
                Text(errorMessage)
                    .font(KinTypography.footnote)
                    .foregroundStyle(KinColors.error)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            } else if let missingText, createdGatheringId == nil {
                Text(missingText)
                    .font(KinTypography.caption)
                    .foregroundStyle(KinColors.secondaryText)
                    .contentTransition(.opacity)
            }

            KinPrimaryButton(
                title:
                    isSaving
                    ? "Saving..."
                    : createdGatheringId == nil
                        ? "Create Event"
                        : "Save Dietary Needs"
            ) {
                focusedField = nil
                Task {
                    await createGathering()
                }
            }
            .disabled(isSaving || (missingText != nil && createdGatheringId == nil))
            .opacity(isSaving || (missingText != nil && createdGatheringId == nil) ? 0.5 : 1)
            .animation(.easeOut(duration: 0.2), value: missingText)
        }
        .padding(.horizontal, KinSpacing.large)
        .padding(.top, KinSpacing.small)
        .padding(.bottom, KinSpacing.small)
        .background {
            KinColors.paper
                .ignoresSafeArea()
                .shadow(color: .black.opacity(0.08), radius: 8, y: -2)
        }
    }
}


// MARK: - Create Gathering

private extension AddGatheringView {

    @MainActor
    func createGathering() async {

        errorMessage = nil

        // Already made; only the dietary needs are left.
        if let createdGatheringId {

            await saveDietaryNeeds(
                gatheringId: createdGatheringId
            )

            return
        }

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

        guard let eventType else {

            errorMessage =
                "Please choose an event type."

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

        let gathering: Gathering

        do {

            var coverImagePath: String?

            if let selectedImageData {

                coverImagePath =
                    try await uploadGatheringPhoto(
                        selectedImageData
                    )
            }

            gathering =
                try await GatheringService
                    .createGathering(
                        name: cleanName,
                        theme:
                            cleaned(
                                theme
                            ),
                        eventType:
                            eventType,
                        coverImagePath:
                            coverImagePath,
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
                        endsAt:
                            endsAt,
                        guestLimit:
                            guestLimit
                    )

            createdGatheringId =
                gathering.id

        } catch {

            errorMessage =
                "Unable to create event. Please try again."

            print(
                "CREATE GATHERING ERROR:",
                error.localizedDescription
            )

            return
        }

        await saveDietaryNeeds(
            gatheringId: gathering.id
        )
    }


    /// Saves the needs for the new event, then closes. On failure the
    /// screen stays so the needs can be retried.
    @MainActor
    func saveDietaryNeeds(
        gatheringId: UUID
    ) async {

        guard !dietaryNeeds.isEmpty else {
            dismiss()
            return
        }

        isSaving = true

        defer {
            isSaving = false
        }

        do {

            try await EventDietaryService
                .saveNeeds(
                    dietaryNeeds,
                    gatheringId: gatheringId
                )

            dismiss()

        } catch {

            errorMessage =
                "Your event was created, but its dietary needs didn't save. Tap Save Dietary Needs to try again."

            print(
                "EVENT DIETARY NEEDS SAVE ERROR:",
                error.localizedDescription
            )
        }
    }
}


// MARK: - Photo Selection

private extension AddGatheringView {

    @MainActor
    func loadSelectedPhoto(
        _ item: PhotosPickerItem
    ) async {

        do {

            guard
                let imageData =
                    try await item.loadTransferable(
                        type: Data.self
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
                "GATHERING PHOTO LOAD ERROR:",
                error.localizedDescription
            )
        }
    }
}


// MARK: - Upload Gathering Photo

private extension AddGatheringView {

    func uploadGatheringPhoto(
        _ imageData: Data
    ) async throws -> String {

        let user =
            try await SupabaseManager.client
                .auth
                .session
                .user

        guard
            let image =
                UIImage(
                    data: imageData
                ),
            let jpegData =
                image.jpegData(
                    compressionQuality: 0.85
                )
        else {

            throw GatheringPhotoError
                .invalidImage
        }

        let fileName =
            "\(UUID().uuidString.lowercased()).jpg"

        let path =
            "\(user.id.uuidString.lowercased())/\(fileName)"

        try await SupabaseManager.client
            .storage
            .from(
                "gathering-photos"
            )
            .upload(
                path,
                data: jpegData,
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


// MARK: - Helpers

private extension AddGatheringView {

    func combinedDateAndTime() -> Date {

        let calendar =
            Calendar.current

        let dateComponents =
            calendar.dateComponents(
                [
                    .year,
                    .month,
                    .day
                ],
                from: date
            )

        let timeComponents =
            calendar.dateComponents(
                [
                    .hour,
                    .minute
                ],
                from: time
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
            from: components
        )
        ?? Date()
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


// MARK: - Photo Error

private enum GatheringPhotoError:
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

        AddGatheringView()
    }
}

//
//  GatheringDetailView.swift
//  KinKitchen
//
//  Created by Greg Hudler on 9/10/26.
//

import SwiftUI
import Supabase


struct GatheringDetailView: View {

    @Environment(\.dismiss) private var dismiss

    let gatheringId: UUID

    @State private var gathering: Gathering?
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var isHost = false

    @State private var selectedTab:
        GatheringDetailTab = .details
    
    @State private var gatheringNeeds: [GatheringNeed] = []
    @State private var gatheringClaims: [GatheringNeedClaim] = []
    
    @State private var contributorProfiles: [Profile] = []
    @State private var currentUserId: UUID?
    
    @State private var currentParticipant: GatheringParticipant?
    @State private var gatheringParticipants: [GatheringParticipant] = []
    @State private var gatheringParticipantProfiles: [Profile] = []
    @State private var isRespondingToInvitation = false
    @State private var invitationResponseError: String?


    var body: some View {

        ZStack {

            KinColors.background
                .ignoresSafeArea()

            if isLoading {

                loadingView

            } else if let errorMessage {

                errorView(
                    message: errorMessage
                )

            } else if let gathering {

                gatheringContent(
                    gathering
                )

            } else {

                errorView(
                    message:
                        "Unable to load this gathering."
                )
            }
        }
        .navigationBarHidden(true)
        .task {

            await loadGathering()
        }
        .onAppear {
            Task {
                await loadGathering()
            }
        }
    }
}


// MARK: - Tabs

private enum GatheringDetailTab:
    String,
    CaseIterable {

    case details = "Details"
    case guests = "Guests"
    case chat = "Chat"
}


// MARK: - Main Content

private extension GatheringDetailView {

    func gatheringContent(
        _ gathering: Gathering
    ) -> some View {

        VStack(
            spacing: 0
        ) {

            navigationHeader
                .padding(
                    .horizontal,
                    KinSpacing.large
                )

            ScrollView(
                showsIndicators: false
            ) {

                VStack(
                    alignment: .leading,
                    spacing: KinSpacing.xLarge
                ) {

                    GatheringHeroImage(
                        path:
                            gathering
                                .coverImagePath
                    )

                    titleSection(
                        gathering
                    )

                    gatheringMetadata(
                        gathering
                    )

                    if currentParticipant?.status == .pending {
                        invitationResponseSection(
                            gathering
                        )
                    }

                    tabPicker

                tabContent(
                    gathering
                )
            }
            .padding(
                .horizontal,
                KinSpacing.large
            )
            .padding(
                .bottom,
                KinSpacing.xxxLarge
            )
        }
            .refreshable {

                await loadGathering()
            }
        }
    }
}


// MARK: - Navigation Header

private extension GatheringDetailView {

    var navigationHeader: some View {

        ZStack {

            Text(
                "Gathering"
            )
            .font(
                KinTypography.navigationTitle
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
        .padding(
            .top,
            KinSpacing.small
        )
    }
}


// MARK: - Title

private extension GatheringDetailView {

    func titleSection(
        _ gathering: Gathering
    ) -> some View {

        VStack(
            alignment: .leading,
            spacing: KinSpacing.small
        ) {

            HStack(
                alignment: .firstTextBaseline,
                spacing: KinSpacing.medium
            ) {

                Text(
                    gathering.name
                )
                .font(
                    KinTypography.largeTitle
                )
                .foregroundStyle(
                    KinColors.primaryText
                )
                .fixedSize(
                    horizontal: false,
                    vertical: true
                )

                Spacer(
                    minLength:
                        KinSpacing.medium
                )

                if isHost {

                    NavigationLink {

                        EditGatheringView(
                            gathering: gathering
                        )

                    } label: {

                        Text(
                            "Edit"
                        )
                        .font(
                            KinTypography.callout
                        )
                        .foregroundStyle(
                            KinColors.primary
                        )
                    }
                    .buttonStyle(
                        .plain
                    )
                }
            }

            HStack {

                statusBadge(
                    gathering.status
                )

                if let theme =
                    gathering.theme,
                   !theme.isEmpty {

                    Text(
                        theme
                    )
                    .font(
                        KinTypography.footnote
                    )
                    .foregroundStyle(
                        KinColors.secondaryText
                    )
                }
            }
        }
    }
}


// MARK: - Status

private extension GatheringDetailView {

    func statusBadge(
        _ status: GatheringStatus
    ) -> some View {

        Text(
            statusDisplayName(
                status
            )
        )
        .font(
            KinTypography.caption
        )
        .foregroundStyle(
            statusColor(
                status
            )
        )
        .padding(
            .horizontal,
            KinSpacing.medium
        )
        .padding(
            .vertical,
            KinSpacing.xSmall
        )
        .background(
            statusColor(
                status
            )
            .opacity(0.10)
        )
        .clipShape(
            Capsule()
        )
    }


    func statusDisplayName(
        _ status: GatheringStatus
    ) -> String {

        switch status {

        case .upcoming:
            return "Upcoming"

        case .completed:
            return "Completed"

        case .cancelled:
            return "Cancelled"
        }
    }


    func statusColor(
        _ status: GatheringStatus
    ) -> Color {

        switch status {

        case .upcoming:
            return KinColors.primary

        case .completed:
            return KinColors.success

        case .cancelled:
            return KinColors.error
        }
    }
}


// MARK: - Metadata

private extension GatheringDetailView {

    func gatheringMetadata(
        _ gathering: Gathering
    ) -> some View {

        VStack(
            alignment: .leading,
            spacing: KinSpacing.small
        ) {

            Label {

                Text(
                    formattedDateTime(
                        gathering.startsAt
                    )
                )

            } icon: {

                Image(
                    systemName:
                        "calendar"
                )
            }
            .font(
                KinTypography.body
            )
            .foregroundStyle(
                KinColors.secondaryText
            )

            if let location =
                gathering.location,
               !location.isEmpty {

                Label {

                    Text(
                        location
                    )

                } icon: {

                    Image(
                        systemName:
                            "mappin.and.ellipse"
                    )
                }
                .font(
                    KinTypography.body
                )
                .foregroundStyle(
                    KinColors.secondaryText
                )
            }
        }
    }


    func formattedDateTime(
        _ date: Date
    ) -> String {

        let dateText =
            date.formatted(
                .dateTime
                    .weekday(.wide)
            )

        let timeText =
            date.formatted(
                date: .omitted,
                time: .shortened
            )

        return "\(dateText) • \(timeText)"
    }
}


// MARK: - Invitation Response

private extension GatheringDetailView {

    func invitationResponseSection(
        _ gathering: Gathering
    ) -> some View {
        VStack(
            alignment: .leading,
            spacing: KinSpacing.medium
        ) {
            Text("You're Invited")
                .font(
                    KinTypography.sectionTitle
                )
                .foregroundStyle(
                    KinColors.primaryText
                )

            Text(
                "You've been invited to \(gathering.name)."
            )
            .font(
                KinTypography.body
            )
            .foregroundStyle(
                KinColors.secondaryText
            )

            HStack(
                spacing: KinSpacing.medium
            ) {
                Button {
                    Task {
                        await respondToInvitation(
                            status: .declined
                        )
                    }
                } label: {
                    Text("Decline")
                        .font(
                            KinTypography.headline
                        )
                        .foregroundStyle(
                            KinColors.primary
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
                .disabled(
                    isRespondingToInvitation
                )

                Button {
                    Task {
                        await respondToInvitation(
                            status: .accepted
                        )
                    }
                } label: {
                    HStack(
                        spacing: KinSpacing.small
                    ) {
                        if isRespondingToInvitation {
                            ProgressView()
                                .tint(.white)
                        }

                        Text("Accept")
                            .font(
                                KinTypography.headline
                            )
                            .foregroundStyle(
                                Color.white
                            )
                    }
                    .frame(
                        maxWidth: .infinity
                    )
                    .padding(
                        .vertical,
                        KinSpacing.medium
                    )
                    .background(
                        KinColors.primary
                    )
                    .clipShape(
                        RoundedRectangle(
                            cornerRadius:
                                KinRadius.medium
                        )
                    )
                }
                .buttonStyle(.plain)
                .disabled(
                    isRespondingToInvitation
                )
            }

            if let invitationResponseError {
                Text(
                    invitationResponseError
                )
                .font(
                    KinTypography.footnote
                )
                .foregroundStyle(
                    KinColors.error
                )
            }
        }
        .padding(
            KinSpacing.large
        )
        .background(
            KinColors.surface
        )
        .clipShape(
            RoundedRectangle(
                cornerRadius:
                    KinRadius.large
            )
        )
    }

    @MainActor
    func respondToInvitation(
        status: InvitationStatus
    ) async {
        guard
            currentParticipant?.status ==
                .pending
        else {
            invitationResponseError =
                "This invitation has already been answered."
            return
        }

        isRespondingToInvitation = true
        invitationResponseError = nil

        do {
            switch status {
            case .accepted:
                _ =
                    try await GatheringInvitationService
                        .acceptInvitation(
                            gatheringId:
                                gatheringId
                        )

            case .declined:
                _ =
                    try await GatheringInvitationService
                        .declineInvitation(
                            gatheringId:
                                gatheringId
                        )

            case .pending:
                break
            }

            await loadGathering()

        } catch {
            invitationResponseError =
                "Unable to respond to this invitation. Please try again."

            print(
                "GATHERING INVITATION RESPONSE ERROR:",
                error.localizedDescription
            )
        }

        isRespondingToInvitation = false
    }
}

// MARK: - Tabs

private extension GatheringDetailView {

    var tabPicker: some View {

        HStack(
            spacing: KinSpacing.small
        ) {

            ForEach(
                GatheringDetailTab.allCases,
                id: \.self
            ) { tab in

                Button {

                    withAnimation(
                        .easeInOut(
                            duration: 0.18
                        )
                    ) {

                        selectedTab = tab
                    }

                } label: {

                    Text(
                        tab.rawValue
                    )
                    .font(
                        KinTypography.footnote
                    )
                    .foregroundStyle(
                        selectedTab == tab
                            ? Color.white
                            : KinColors.primaryText
                    )
                    .frame(
                        maxWidth: .infinity
                    )
                    .padding(
                        .vertical,
                        KinSpacing.medium
                    )
                    .background(
                        selectedTab == tab
                            ? KinColors.primary
                            : KinColors.surface
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
            }
        }
    }
}

// MARK: - Guests

private extension GatheringDetailView {
    var guestsTab: some View {
        VStack(
            alignment: .leading,
            spacing: KinSpacing.xLarge
        ) {
            HStack {
                Text("Guests")
                    .font(
                        KinTypography.sectionTitle
                    )
                    .foregroundStyle(
                        KinColors.primaryText
                    )

                Spacer()

                if isHost {
                    NavigationLink {
                        GatheringInviteUserView(
                            gatheringId:
                                gatheringId
                        )
                    } label: {
                        Text("Invite Guests")
                            .font(
                                KinTypography.footnote
                            )
                            .foregroundStyle(
                                KinColors.primary
                            )
                    }
                    .buttonStyle(.plain)
                }
            }

            participantSection

            if isHost {
                invitationManagementSection
            } else if let currentParticipant {
                currentInvitationSection(
                    currentParticipant
                )
            }
        }
        .frame(
            maxWidth: .infinity,
            alignment: .leading
        )
    }

    var participantSection: some View {
        VStack(
            alignment: .leading,
            spacing: KinSpacing.medium
        ) {
            Text("Who's Coming")
                .font(
                    KinTypography.headline
                )
                .foregroundStyle(
                    KinColors.primaryText
                )

            hostParticipantRow

            ForEach(
                visibleGatheringParticipants,
                id: \.userId
            ) { participant in
                participantRow(
                    participant
                )
            }
        }
    }

    var hostParticipantRow: some View {
        HStack(
            spacing: KinSpacing.medium
        ) {
            VStack(
                alignment: .leading,
                spacing: KinSpacing.xSmall
            ) {
                Text("Host")
                    .font(
                        KinTypography.headline
                    )
                    .foregroundStyle(
                        KinColors.primaryText
                    )

                Text("Gathering Host")
                    .font(
                        KinTypography.footnote
                    )
                    .foregroundStyle(
                        KinColors.secondaryText
                    )
            }

            Spacer()

            Text("Host")
                .font(
                    KinTypography.caption
                )
                .foregroundStyle(
                    KinColors.primary
                )
                .padding(
                    .horizontal,
                    KinSpacing.medium
                )
                .padding(
                    .vertical,
                    KinSpacing.xSmall
                )
                .background(
                    KinColors.primary
                        .opacity(0.10)
                )
                .clipShape(
                    Capsule()
                )
        }
        .padding(
            KinSpacing.large
        )
        .background(
            KinColors.surface
        )
        .clipShape(
            RoundedRectangle(
                cornerRadius:
                    KinRadius.large
            )
        )
    }

    var visibleGatheringParticipants:
        [GatheringParticipant] {
        gatheringParticipants.filter {
            $0.status == .accepted ||
            $0.status == .pending
        }
    }

    var invitationManagementSection:
        some View {
        VStack(
            alignment: .leading,
            spacing: KinSpacing.medium
        ) {
            Text("Invitations")
                .font(
                    KinTypography.headline
                )
                .foregroundStyle(
                    KinColors.primaryText
                )

            if gatheringParticipants.isEmpty {
                Text(
                    "No guests have been invited yet."
                )
                .font(
                    KinTypography.body
                )
                .foregroundStyle(
                    KinColors.secondaryText
                )
            } else {
                VStack(
                    spacing: KinSpacing.medium
                ) {
                    ForEach(
                        gatheringParticipants,
                        id: \.userId
                    ) { participant in
                        participantStatusRow(
                            participant
                        )
                    }
                }
            }
        }
    }

    func currentInvitationSection(
        _ participant: GatheringParticipant
    ) -> some View {
        VStack(
            alignment: .leading,
            spacing: KinSpacing.small
        ) {
            Text("Your Invitation")
                .font(
                    KinTypography.headline
                )
                .foregroundStyle(
                    KinColors.primaryText
                )

            invitationStatusBadge(
                participant.status
            )
        }
        .frame(
            maxWidth: .infinity,
            alignment: .leading
        )
        .padding(
            KinSpacing.large
        )
        .background(
            KinColors.surface
        )
        .clipShape(
            RoundedRectangle(
                cornerRadius:
                    KinRadius.large
            )
        )
    }

    func participantRow(
        _ participant: GatheringParticipant
    ) -> some View {
        HStack(
            spacing: KinSpacing.medium
        ) {
            VStack(
                alignment: .leading,
                spacing: KinSpacing.xSmall
            ) {
                Text(
                    participantDisplayName(
                        participant
                    )
                )
                .font(
                    KinTypography.headline
                )
                .foregroundStyle(
                    KinColors.primaryText
                )

                if let username =
                    participantUsername(
                        participant
                    ) {
                    Text("@\(username)")
                        .font(
                            KinTypography.footnote
                        )
                        .foregroundStyle(
                            KinColors.secondaryText
                        )
                }
            }

            Spacer()

            participantAttendanceBadge(
                participant.status
            )
        }
        .padding(
            KinSpacing.large
        )
        .background(
            KinColors.surface
        )
        .clipShape(
            RoundedRectangle(
                cornerRadius:
                    KinRadius.large
            )
        )
    }

    func participantAttendanceBadge(
        _ status: InvitationStatus
    ) -> some View {
        let title =
            status == .accepted
                ? "Going"
                : "Invited"

        let color =
            status == .accepted
                ? KinColors.success
                : KinColors.warning

        return Text(title)
            .font(
                KinTypography.caption
            )
            .foregroundStyle(
                color
            )
            .padding(
                .horizontal,
                KinSpacing.medium
            )
            .padding(
                .vertical,
                KinSpacing.xSmall
            )
            .background(
                color.opacity(0.10)
            )
            .clipShape(
                Capsule()
            )
    }

    func participantStatusRow(
        _ participant: GatheringParticipant
    ) -> some View {
        HStack(
            spacing: KinSpacing.medium
        ) {
            VStack(
                alignment: .leading,
                spacing: KinSpacing.xSmall
            ) {
                Text(
                    participantDisplayName(
                        participant
                    )
                )
                .font(
                    KinTypography.headline
                )
                .foregroundStyle(
                    KinColors.primaryText
                )

                if let username =
                    participantUsername(
                        participant
                    ) {
                    Text("@\(username)")
                        .font(
                            KinTypography.footnote
                        )
                        .foregroundStyle(
                            KinColors.secondaryText
                        )
                }
            }

            Spacer()

            invitationStatusBadge(
                participant.status
            )
        }
        .padding(
            KinSpacing.large
        )
        .background(
            KinColors.surface
        )
        .clipShape(
            RoundedRectangle(
                cornerRadius:
                    KinRadius.large
            )
        )
    }

    func invitationStatusBadge(
        _ status: InvitationStatus
    ) -> some View {
        Text(
            invitationStatusDisplayName(
                status
            )
        )
        .font(
            KinTypography.caption
        )
        .foregroundStyle(
            invitationStatusColor(
                status
            )
        )
        .padding(
            .horizontal,
            KinSpacing.medium
        )
        .padding(
            .vertical,
            KinSpacing.xSmall
        )
        .background(
            invitationStatusColor(
                status
            )
            .opacity(0.10)
        )
        .clipShape(
            Capsule()
        )
    }

    func invitationStatusDisplayName(
        _ status: InvitationStatus
    ) -> String {
        switch status {
        case .pending:
            return "Pending"
        case .accepted:
            return "Accepted"
        case .declined:
            return "Declined"
        }
    }

    func invitationStatusColor(
        _ status: InvitationStatus
    ) -> Color {
        switch status {
        case .pending:
            return KinColors.warning
        case .accepted:
            return KinColors.success
        case .declined:
            return KinColors.error
        }
    }

    func participantProfile(
        _ participant: GatheringParticipant
    ) -> Profile? {
        gatheringParticipantProfiles.first {
            $0.id ==
                participant.userId
        }
    }

    func participantDisplayName(
        _ participant: GatheringParticipant
    ) -> String {
        guard let profile =
            participantProfile(
                participant
            )
        else {
            return "Guest"
        }

        if let displayName =
            profile.displayName?
                .trimmingCharacters(
                    in:
                        .whitespacesAndNewlines
                ),
           !displayName.isEmpty {
            return displayName
        }

        let firstName =
            profile.firstName?
                .trimmingCharacters(
                    in:
                        .whitespacesAndNewlines
                )
            ?? ""

        let lastName =
            profile.lastName?
                .trimmingCharacters(
                    in:
                        .whitespacesAndNewlines
                )
            ?? ""

        let fullName =
            "\(firstName) \(lastName)"
                .trimmingCharacters(
                    in:
                        .whitespacesAndNewlines
                )

        if !fullName.isEmpty {
            return fullName
        }

        if let username =
            profile.username?
                .trimmingCharacters(
                    in:
                        .whitespacesAndNewlines
                ),
           !username.isEmpty {
            return username
        }

        return "Guest"
    }

    func participantUsername(
        _ participant: GatheringParticipant
    ) -> String? {
        guard
            let username =
                participantProfile(
                    participant
                )?
                .username?
                .trimmingCharacters(
                    in:
                        .whitespacesAndNewlines
                ),
            !username.isEmpty
        else {
            return nil
        }

        return username
    }
}

// MARK: - Tab Content

private extension GatheringDetailView {

    @ViewBuilder
    func tabContent(
        _ gathering: Gathering
    ) -> some View {

        switch selectedTab {

        case .details:

            detailsTab(
                gathering
            )

        case .guests:
            guestsTab

        case .chat:

            futureTab(
                icon:
                    "bubble.left.and.bubble.right",
                title: "Gathering Chat",
                message:
                    "Gathering chat will be available here."
            )
        }
    }
}


// MARK: - Details Tab

private extension GatheringDetailView {

    func detailsTab(
        _ gathering: Gathering
    ) -> some View {

        VStack(
            alignment: .leading,
            spacing: KinSpacing.xLarge
        ) {

            descriptionSection(
                gathering
            )

            dishesSection

            suppliesSection
        }
    }
}


// MARK: - About

private extension GatheringDetailView {

    func descriptionSection(
        _ gathering: Gathering
    ) -> some View {

        VStack(
            alignment: .leading,
            spacing: KinSpacing.medium
        ) {

            Text(
                "About"
            )
            .font(
                KinTypography.sectionTitle
            )
            .foregroundStyle(
                KinColors.primaryText
            )

            if let description =
                gathering.description,
               !description.isEmpty {

                Text(
                    description
                )
                .font(
                    KinTypography.body
                )
                .foregroundStyle(
                    KinColors.primaryText
                )
                .frame(
                    maxWidth: .infinity,
                    alignment: .leading
                )
                .padding(
                    KinSpacing.large
                )
                .background(
                    KinColors.surface
                )
                .clipShape(
                    RoundedRectangle(
                        cornerRadius:
                            KinRadius.large
                    )
                )

            } else {

                Text(
                    "No description has been added."
                )
                .font(
                    KinTypography.body
                )
                .foregroundStyle(
                    KinColors.secondaryText
                )
                .frame(
                    maxWidth: .infinity,
                    alignment: .leading
                )
                .padding(
                    KinSpacing.large
                )
                .background(
                    KinColors.surface
                )
                .clipShape(
                    RoundedRectangle(
                        cornerRadius:
                            KinRadius.large
                    )
                )
            }
        }
    }
}


// MARK: - Dishes

private extension GatheringDetailView {
    var dishesSection: some View {
        VStack(
            alignment: .leading,
            spacing: KinSpacing.medium
        ) {
            HStack {
                Text("Dishes Needed")
                    .font(KinTypography.sectionTitle)
                    .foregroundStyle(KinColors.primaryText)

                Spacer()

                if isHost {
                    NavigationLink {
                        AddDishView(
                            gatheringId: gatheringId
                        )
                    } label: {
                        Text("Add Dish")
                            .font(KinTypography.footnote)
                            .foregroundStyle(KinColors.primary)
                    }
                    .buttonStyle(.plain)
                }
            }

            if dishGatheringNeeds.isEmpty {
                emptyDishesView
            } else {
                VStack(
                    spacing: KinSpacing.medium
                ) {
                    ForEach(dishGatheringNeeds) { need in
                        NavigationLink {
                            GatheringNeedDetailView(
                                need: need,
                                isHost: isHost
                            )
                        } label: {
                            gatheringNeedCard(need)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    var emptyDishesView: some View {
        VStack(
            spacing: KinSpacing.medium
        ) {
            Image(systemName: "fork.knife")
                .font(
                    .system(
                        size: 30,
                        weight: .medium
                    )
                )
                .foregroundStyle(KinColors.primary)

            Text("No dishes yet")
                .font(KinTypography.headline)
                .foregroundStyle(KinColors.primaryText)

            Text("Dish sign-ups will appear here.")
                .font(KinTypography.footnote)
                .foregroundStyle(KinColors.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, KinSpacing.xLarge)
        .background(KinColors.surface)
        .clipShape(
            RoundedRectangle(
                cornerRadius: KinRadius.large
            )
        )
    }

    func gatheringNeedCard(
        _ need: GatheringNeed
    ) -> some View {
        HStack(
            spacing: KinSpacing.medium
        ) {
            ZStack {
                Circle()
                    .fill(
                        KinColors.primary.opacity(0.10)
                    )
                    .frame(
                        width: 46,
                        height: 46
                    )

                Image(
                    systemName: dishIcon(
                        for: need.category
                    )
                )
                .foregroundStyle(KinColors.primary)
            }

            VStack(
                alignment: .leading,
                spacing: KinSpacing.xSmall
            ) {
                Text(need.name)
                    .font(KinTypography.headline)
                    .foregroundStyle(KinColors.primaryText)

                Text(need.category.displayName)
                    .font(KinTypography.footnote)
                    .foregroundStyle(KinColors.secondaryText)

                if need.quantityNeeded > 1 {
                    Text(
                        "\(need.quantityNeeded) Dishes needed"
                    )
                    .font(KinTypography.caption)
                    .foregroundStyle(KinColors.secondaryText)
                }
                Text(
                    claimStatus(for: need)
                )
                .font(KinTypography.caption)
                .foregroundStyle(
                    remainingQuantity(for: need) == 0
                        ? KinColors.success
                        : KinColors.primary
                )
                if let contributor =
                    contributorText(
                        for: need
                    ) {
                    Text(contributor)
                        .font(KinTypography.caption)
                        .foregroundStyle(
                            KinColors.secondaryText
                        )
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(KinTypography.footnote)
                .foregroundStyle(KinColors.secondaryText)
        }
        .padding(KinSpacing.large)
        .background(KinColors.surface)
        .clipShape(
            RoundedRectangle(
                cornerRadius: KinRadius.large
            )
        )
    }
    
    func claims(
        for need: GatheringNeed
    ) -> [GatheringNeedClaim] {
        gatheringClaims.filter {
            $0.gatheringNeedId == need.id
        }
    }

    func claimedQuantity(
        for need: GatheringNeed
    ) -> Int {
        claims(for: need).reduce(0) {
            $0 + $1.quantity
        }
    }

    func remainingQuantity(
        for need: GatheringNeed
    ) -> Int {
        max(
            need.quantityNeeded -
            claimedQuantity(for: need),
            0
        )
    }

    func claimStatus(
        for need: GatheringNeed
    ) -> String {
        let claimed =
            claimedQuantity(for: need)

        let remaining =
            remainingQuantity(for: need)

        if remaining == 0 {
            return "Claimed"
        }

        if claimed == 0 {
            return "Available"
        }

        return "\(remaining) remaining"
    }
    
    func contributorProfiles(
        for need: GatheringNeed
    ) -> [Profile] {
        let userIds =
            Set(
                claims(for: need)
                    .map(\.userId)
            )

        return contributorProfiles.filter {
            userIds.contains($0.id)
        }
    }

    func contributorText(
        for need: GatheringNeed
    ) -> String? {
        let profiles =
            contributorProfiles(
                for: need
            )

        guard !profiles.isEmpty else {
            return nil
        }

        let names =
            profiles.map { profile in
                if profile.id == currentUserId {
                    return "You"
                }

                if let displayName =
                    profile.displayName?
                        .trimmingCharacters(
                            in: .whitespacesAndNewlines
                        ),
                   !displayName.isEmpty {
                    return displayName
                }

                let firstName =
                    profile.firstName?
                        .trimmingCharacters(
                            in: .whitespacesAndNewlines
                        ) ?? ""

                let lastName =
                    profile.lastName?
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
                    profile.username?
                        .trimmingCharacters(
                            in: .whitespacesAndNewlines
                        ),
                   !username.isEmpty {
                    return username
                }

                return "Contributor"
            }

        if names.count == 1 {
            return "Bringing: \(names[0])"
        }

        return "Bringing: \(names.joined(separator: ", "))"
    }
    
    func dishIcon(
        for category: DishCategory
    ) -> String {
        switch category {
        case .appetizer:
            return "takeoutbag.and.cup.and.straw"
        case .entree:
            return "fork.knife"
        case .side:
            return "takeoutbag.and.cup.and.straw"
        case .salad:
            return "leaf.fill"
        case .bread:
            return "basket.fill"
        case .dessert:
            return "birthday.cake"
        case .drink:
            return "cup.and.saucer"
        case .condimentSauce:
            return "takeoutbag.and.cup.and.straw"
        case .other:
            return "fork.knife"
        }
    }
}

// MARK: - Gathering Supplies

private extension GatheringDetailView {

    var dishGatheringNeeds: [GatheringNeed] {
        gatheringNeeds.filter {
            !isSupplyNeed($0)
        }
    }

    var supplyGatheringNeeds: [GatheringNeed] {
        gatheringNeeds.filter {
            isSupplyNeed($0)
        }
    }

    var suppliesSection: some View {
        VStack(
            alignment: .leading,
            spacing: KinSpacing.medium
        ) {
            HStack {
                Text("Supplies Needed")
                    .font(
                        KinTypography.sectionTitle
                    )
                    .foregroundStyle(
                        KinColors.primaryText
                    )

                Spacer()

                if isHost {
                    NavigationLink {
                        AddGatheringSuppliesView(
                            gatheringId:
                                gatheringId
                        )
                    } label: {
                        Text("Add Supplies")
                            .font(
                                KinTypography.footnote
                            )
                            .foregroundStyle(
                                KinColors.primary
                            )
                    }
                    .buttonStyle(.plain)
                }
            }

            if supplyGatheringNeeds.isEmpty {
                emptySuppliesView
            } else {
                VStack(
                    spacing: KinSpacing.medium
                ) {
                    ForEach(
                        supplyGatheringNeeds
                    ) { need in
                        NavigationLink {
                            GatheringNeedDetailView(
                                need: need,
                                isHost: isHost
                            )
                        } label: {
                            supplyNeedCard(need)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    var emptySuppliesView: some View {
        VStack(
            spacing: KinSpacing.medium
        ) {
            Image(
                systemName: "shippingbox"
            )
            .font(
                .system(
                    size: 30,
                    weight: .medium
                )
            )
            .foregroundStyle(
                KinColors.primary
            )

            Text("No supplies needed")
                .font(
                    KinTypography.headline
                )
                .foregroundStyle(
                    KinColors.primaryText
                )

            Text(
                "Gathering supplies will appear here."
            )
            .font(
                KinTypography.footnote
            )
            .foregroundStyle(
                KinColors.secondaryText
            )
        }
        .frame(
            maxWidth: .infinity
        )
        .padding(
            .vertical,
            KinSpacing.xLarge
        )
        .background(
            KinColors.surface
        )
        .clipShape(
            RoundedRectangle(
                cornerRadius:
                    KinRadius.large
            )
        )
    }

    func supplyNeedCard(
        _ need: GatheringNeed
    ) -> some View {
        HStack(
            spacing: KinSpacing.medium
        ) {
            ZStack {
                Circle()
                    .fill(
                        KinColors.primary
                            .opacity(0.10)
                    )
                    .frame(
                        width: 46,
                        height: 46
                    )

                Image(
                    systemName:
                        "shippingbox.fill"
                )
                .foregroundStyle(
                    KinColors.primary
                )
            }

            VStack(
                alignment: .leading,
                spacing: KinSpacing.xSmall
            ) {
                Text(need.name)
                    .font(
                        KinTypography.headline
                    )
                    .foregroundStyle(
                        KinColors.primaryText
                    )

                if need.quantityNeeded > 1 {
                    Text(
                        "\(need.quantityNeeded) needed"
                    )
                    .font(
                        KinTypography.caption
                    )
                    .foregroundStyle(
                        KinColors.secondaryText
                    )
                }

                Text(
                    claimStatus(
                        for: need
                    )
                )
                .font(
                    KinTypography.caption
                )
                .foregroundStyle(
                    remainingQuantity(
                        for: need
                    ) == 0
                    ? KinColors.success
                    : KinColors.primary
                )

                if let contributor =
                    contributorText(
                        for: need
                    ) {
                    Text(contributor)
                        .font(
                            KinTypography.caption
                        )
                        .foregroundStyle(
                            KinColors.secondaryText
                        )
                }
            }

            Spacer()

            Image(
                systemName: "chevron.right"
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
        .background(
            KinColors.surface
        )
        .clipShape(
            RoundedRectangle(
                cornerRadius:
                    KinRadius.large
            )
        )
    }

    func isSupplyNeed(
        _ need: GatheringNeed
    ) -> Bool {
        DishSupply.allCases.contains {
            $0.displayName == need.name
        } &&
        need.category == .other &&
        need.recipeId == nil
    }
}

// MARK: - Future Tabs

private extension GatheringDetailView {

    func futureTab(
        icon: String,
        title: String,
        message: String
    ) -> some View {

        VStack(
            spacing: KinSpacing.medium
        ) {

            Image(
                systemName: icon
            )
            .font(
                .system(
                    size: 30
                )
            )
            .foregroundStyle(
                KinColors.primary
            )

            Text(
                title
            )
            .font(
                KinTypography.sectionTitle
            )
            .foregroundStyle(
                KinColors.primaryText
            )

            Text(
                message
            )
            .font(
                KinTypography.body
            )
            .foregroundStyle(
                KinColors.secondaryText
            )
            .multilineTextAlignment(
                .center
            )
        }
        .frame(
            maxWidth: .infinity
        )
        .padding(
            .vertical,
            KinSpacing.xxxLarge
        )
    }
}


// MARK: - Hero Image

private struct GatheringHeroImage: View {

    let path: String?

    @State private var imageData: Data?
    @State private var isLoading = false


    var body: some View {

        ZStack {

            RoundedRectangle(
                cornerRadius:
                    KinRadius.large
            )
            .fill(
                KinColors.surface
            )

            if
                let imageData,
                let image =
                    UIImage(
                        data: imageData
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
                    height: 225
                )
                .clipped()

            } else if isLoading {

                ProgressView()
                    .tint(
                        KinColors.primary
                    )

            } else {

                Image(
                    systemName:
                        "house.fill"
                )
                .font(
                    .system(
                        size: 48,
                        weight: .semibold
                    )
                )
                .foregroundStyle(
                    KinColors.primary
                )
            }
        }
        .frame(
            maxWidth: .infinity
        )
        .frame(
            height: 225
        )
        .clipShape(
            RoundedRectangle(
                cornerRadius:
                    KinRadius.large
            )
        )
        .task(
            id: path
        ) {

            await loadImage()
        }
    }


    @MainActor
    private func loadImage() async {

        imageData = nil

        guard
            let path,
            !path.isEmpty
        else {

            return
        }

        isLoading = true

        defer {

            isLoading = false
        }

        do {

            imageData =
                try await SupabaseManager.client
                    .storage
                    .from(
                        "gathering-photos"
                    )
                    .download(
                        path: path
                    )

        } catch {

            print(
                "GATHERING HERO IMAGE ERROR:",
                error.localizedDescription
            )
        }
    }
}


// MARK: - Loading

private extension GatheringDetailView {

    var loadingView: some View {

        VStack(
            spacing: KinSpacing.medium
        ) {

            ProgressView()
                .tint(
                    KinColors.primary
                )

            Text(
                "Loading gathering..."
            )
            .font(
                KinTypography.body
            )
            .foregroundStyle(
                KinColors.secondaryText
            )
        }
    }
}


// MARK: - Error

private extension GatheringDetailView {

    func errorView(
        message: String
    ) -> some View {

        VStack(
            spacing: KinSpacing.large
        ) {

            Image(
                systemName:
                    "exclamationmark.triangle"
            )
            .font(
                .system(
                    size: 36
                )
            )
            .foregroundStyle(
                KinColors.error
            )

            Text(
                message
            )
            .font(
                KinTypography.body
            )
            .foregroundStyle(
                KinColors.primaryText
            )
            .multilineTextAlignment(
                .center
            )

            KinSecondaryButton(
                title: "Try Again"
            ) {

                Task {

                    await loadGathering()
                }
            }
        }
        .padding(
            KinSpacing.xLarge
        )
    }
}


// MARK: - Load Gathering

private extension GatheringDetailView {

    @MainActor
    func loadGathering() async {

        isLoading = true
        errorMessage = nil

        do {

            async let gatheringRequest =
                GatheringService
                    .fetchGathering(
                        id: gatheringId
                    )

            async let userRequest =
                SupabaseManager.client
                    .auth
                    .session
                    .user

            async let needsRequest =
                GatheringDishService
                    .fetchNeeds(
                        gatheringId: gatheringId
                    )
            
            let loadedNeeds =
                try await needsRequest

            async let claimsRequest =
                GatheringDishService
                    .fetchClaims(
                        gatheringNeedIds:
                            loadedNeeds.map(\.id)
                    )
            let loadedClaims =
                try await claimsRequest

            async let profilesRequest =
                ProfileService.fetchProfiles(
                    userIds: loadedClaims.map(\.userId)
                )

            let (
                loadedGathering,
                currentUser,
                loadedProfiles
            ) = try await (
                gatheringRequest,
                userRequest,
                profilesRequest
            )

            gathering =
                loadedGathering

            gatheringNeeds =
                loadedNeeds

            gatheringClaims =
                loadedClaims

            contributorProfiles =
                loadedProfiles

            currentUserId =
                currentUser.id
            
            let participants =
                try await GatheringInvitationService
                    .fetchInvitations(
                        gatheringId:
                            gatheringId
                    )

            gatheringParticipants =
                participants

            gatheringParticipantProfiles =
                try await ProfileService.fetchProfiles(
                    userIds:
                        participants.map(\.userId)
                )

            currentParticipant =
                participants.first {
                    $0.userId ==
                        currentUser.id
                }

            isHost =
                loadedGathering.hostId ==
                currentUser.id

            isLoading = false
            
            
        } catch {

            gathering = nil
            gatheringNeeds = []
            isHost = false
            isLoading = false
            gatheringClaims = []
            contributorProfiles = []
            currentUserId = nil
            currentParticipant = nil
            gatheringParticipants = []
            gatheringParticipantProfiles = []

            errorMessage =
                "Unable to load gathering. Please try again."

            print(
                "GATHERING DETAIL ERROR:",
                error.localizedDescription
            )
        }
    }
}

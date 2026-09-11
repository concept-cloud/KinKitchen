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

            futureTab(
                icon: "person.2",
                title: "Guests",
                message:
                    "Guest management will be available here."
            )

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

            if gatheringNeeds.isEmpty {
                emptyDishesView
            } else {
                VStack(
                    spacing: KinSpacing.medium
                ) {
                    ForEach(gatheringNeeds) { need in
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
                        "\(need.quantityNeeded) servings needed"
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
    
    
    func dishIcon(
        for category: DishCategory
    ) -> String {
        switch category {
        case .entree:
            return "fork.knife"
        case .side:
            return "takeoutbag.and.cup.and.straw"
        case .dessert:
            return "birthday.cake"
        case .drink:
            return "cup.and.saucer"
        case .supplies:
            return "shippingbox"
        case .other:
            return "fork.knife"
        }
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
            
            let (
                loadedGathering,
                currentUser,
                loadedClaims
            ) = try await (
                gatheringRequest,
                userRequest,
                claimsRequest
            )

            gathering =
                loadedGathering

            gatheringNeeds =
                loadedNeeds

            gatheringClaims =
                loadedClaims

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

            errorMessage =
                "Unable to load gathering. Please try again."

            print(
                "GATHERING DETAIL ERROR:",
                error.localizedDescription
            )
        }
    }
}

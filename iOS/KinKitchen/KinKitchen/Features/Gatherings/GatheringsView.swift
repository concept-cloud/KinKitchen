//
//  GatheringsView.swift
//  KinKitchen
//
//  Created by Greg Hudler on 8/26/26.
//

import SwiftUI
import UIKit
import Supabase



struct GatheringsView: View {
    
    enum GatheringTab:
        String,
        CaseIterable {
        
        case upcoming = "Upcoming"
        case hosting = "Hosting"
        case past = "Past"
    }
    
    
    @State private var selectedTab: GatheringTab = .upcoming
    
    @State private var isLoading = true
    
    @State private var errorMessage: String?
    
    @State private var selectedGatheringId: UUID?
    
    @State private var showingGatheringDetail = false
    
    @State private var showingAddGathering = false
    
    @State private var gatherings: [GatheringListItem] = []
    
    
    var body: some View {
        
        NavigationStack {
            
            ZStack {
                
                KinColors.background
                    .ignoresSafeArea()
                
                VStack(
                    spacing: 0
                ) {
                    
                    header
                    
                    tabs
                    
                    content
                }
            }
            .navigationBarHidden(true)
            .task {
                
                await loadGatherings()
            }
            .navigationDestination(
                isPresented:
                    $showingGatheringDetail
            ) {
                
                if let selectedGatheringId {
                    
                    GatheringDetailView(
                        gatheringId: selectedGatheringId
                    )
                    .multilineTextAlignment(
                        .center
                    )
                    .foregroundStyle(
                        KinColors.primaryText
                    )
                    .frame(
                        maxWidth: .infinity,
                        maxHeight: .infinity
                    )
                    .background(
                        KinColors.background
                    )
                }
            }
            .navigationDestination(
                isPresented:
                    $showingAddGathering
            ) {
                
                AddGatheringView()
            }
        }
    }
}


// MARK: - Header

private extension GatheringsView {

    var header: some View {

        HStack {

            Text(
                "Gatherings"
            )
            .font(
                KinTypography.largeTitle
            )
            .foregroundStyle(
                KinColors.primaryText
            )
            
            Spacer()

            Button {

                showingAddGathering =
                    true

            } label: {

                Image(
                    systemName: "plus"
                )
                .font(
                    .system(
                        size: 22,
                        weight: .bold
                    )
                )
                .foregroundStyle(
                    .white
                )
                .frame(
                    width: 52,
                    height: 52
                )
                .background(
                    KinColors.primary
                )
                .clipShape(
                    Circle()
                )
            }
            .buttonStyle(
                .plain
            )
            .accessibilityLabel(
                "Add Gathering"
            )
        }
        .padding(
            .horizontal,
            KinSpacing.large
        )
        .padding(
            .top,
            KinSpacing.large
        )
        .padding(
            .bottom,
            KinSpacing.medium
        )
    }
}


// MARK: - Tabs

private extension GatheringsView {

    var tabs: some View {

        HStack(
            spacing: KinSpacing.small
        ) {

            ForEach(
                GatheringTab.allCases,
                id: \.self
            ) { tab in

                Button {

                    selectedTab = tab

                    Task {
                        await loadGatherings()
                    }

                } label: {

                    Text(
                        tab.rawValue
                    )
                    .font(
                        KinTypography.subheadline
                    )
                    .foregroundStyle(
                        selectedTab == tab
                            ? .white
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
        .padding(
            .horizontal,
            KinSpacing.large
        )
        .padding(
            .bottom,
            KinSpacing.large
        )
    }
}


// MARK: - Content

private extension GatheringsView {

    @ViewBuilder
    var content: some View {

        if isLoading {

            loadingState

        } else if let errorMessage {

            errorState(
                errorMessage
            )

        } else if gatherings.isEmpty {

            emptyState

        } else {

            gatheringList
        }
    }
}


// MARK: - Gathering List

private extension GatheringsView {

    var gatheringList: some View {

        ScrollView {

            LazyVStack(
                spacing:
                    KinSpacing.medium
            ) {

                ForEach(
                    gatherings
                ) { item in

                    Button {

                        selectedGatheringId =
                            item.gathering.id

                        showingGatheringDetail =
                            true

                    } label: {

                        gatheringCard(
                            item
                        )
                    }
                    .buttonStyle(
                        .plain
                    )
                }
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
            await loadGatherings()
        }
    }
}


// MARK: - Gathering Card

private extension GatheringsView {

    func gatheringCard(
        _ item: GatheringListItem
    ) -> some View {

        let gathering =
            item.gathering

        return HStack(
            spacing: KinSpacing.medium
        ) {

            GatheringCardImage(
                path: gathering.coverImagePath
            )

            VStack(
                alignment: .leading,
                spacing: KinSpacing.xSmall
            ) {

                Text(
                    gathering.name
                )
                .font(
                    KinTypography.title3
                )
                .foregroundStyle(
                    KinColors.primaryText
                )
                .multilineTextAlignment(
                    .leading
                )
                .lineLimit(2)
                .fixedSize(
                    horizontal: false,
                    vertical: true
                )
                .layoutPriority(1)

                Text(
                    formattedDateTime(
                        gathering.startsAt
                    )
                )
                .font(
                    KinTypography.caption
                )
                .foregroundStyle(
                    KinColors.secondaryText
                )

                if let location =
                    cleaned(
                        gathering.location
                    ) {

                    Text(
                        location
                    )
                    .font(
                        KinTypography.caption
                    )
                    .foregroundStyle(
                        KinColors.secondaryText
                    )
                    .lineLimit(1)
                }
            }
            .frame(
                maxWidth: .infinity,
                alignment: .leading
            )

            VStack(
                alignment: .center,
                spacing: KinSpacing.xSmall
            ) {

                Image(
                    systemName:
                        cardIcon(
                            for: item
                        )
                )
                .font(
                    .system(
                        size: 20,
                        weight: .semibold
                    )
                )
                .foregroundStyle(
                    relationshipColor(
                        for: item
                    )
                )

                Text(
                    item.relationship.displayName
                )
                .font(
                    KinTypography.caption
                )
                .foregroundStyle(
                    relationshipColor(
                        for: item
                    )
                )
                .padding(
                    .horizontal,
                    KinSpacing.small
                )
                .padding(
                    .vertical,
                    KinSpacing.xSmall
                )
                .background(
                    relationshipColor(
                        for: item
                    )
                    .opacity(0.10)
                )
                .clipShape(
                    Capsule()
                )

                Image(
                    systemName:
                        "chevron.right"
                )
                .font(
                    .caption
                )
                .foregroundStyle(
                    KinColors.secondaryText
                )
            }
            .fixedSize(
                horizontal: true,
                vertical: false
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


    private func relationshipColor(
        for item: GatheringListItem
    ) -> Color {

        switch item.relationship {

        case .hosting:
            return KinColors.primary

        case .going:
            return .green

        case .invited:
            return KinColors.warning
        }
    }


    func cardIcon(
        for item: GatheringListItem
    ) -> String {

        switch item.relationship {

        case .hosting:
            return "house.fill"

        case .invited:
            return "envelope.fill"

        case .going:
            return "person.3.fill"
        }
    }
}

// MARK: - Gathering Card Image

private struct GatheringCardImage: View {

    let path: String?

    @State private var imageData: Data?
    @State private var isLoading = false


    var body: some View {

        ZStack {

            RoundedRectangle(
                cornerRadius:
                    KinRadius.medium
            )
            .fill(
                KinColors.background
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
                    width: 82,
                    height: 82
                )
                .clipped()

            } else {

                Image(
                    systemName:
                        "fork.knife"
                )
                .font(
                    .system(
                        size: 26,
                        weight: .semibold
                    )
                )
                .foregroundStyle(
                    KinColors.secondaryText
                )
            }
        }
        .frame(
            width: 82,
            height: 82
        )
        .clipShape(
            RoundedRectangle(
                cornerRadius:
                    KinRadius.medium
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

        guard
            !isLoading,
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
                "GATHERING CARD IMAGE ERROR:",
                error.localizedDescription
            )
        }
    }
}


// MARK: - Loading

private extension GatheringsView {

    var loadingState: some View {

        VStack(
            spacing:
                KinSpacing.medium
        ) {

            ProgressView()

            Text(
                "Loading gatherings..."
            )
            .font(
                KinTypography.body
            )
            .foregroundStyle(
                KinColors.secondaryText
            )
        }
        .frame(
            maxWidth: .infinity,
            maxHeight: .infinity
        )
    }
}


// MARK: - Empty State

private extension GatheringsView {

    var emptyState: some View {

        VStack(
            spacing:
                KinSpacing.large
        ) {

            Image(
                systemName:
                    KinIcons.gatherings
            )
            .font(
                .system(
                    size: 48
                )
            )
            .foregroundStyle(
                KinColors.primary
            )


            Text(
                emptyTitle
            )
            .font(
                KinTypography.title2
            )
            .foregroundStyle(
                KinColors.primaryText
            )


            Text(
                emptyMessage
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
        .padding(
            KinSpacing.xLarge
        )
        .frame(
            maxWidth: .infinity,
            maxHeight: .infinity
        )
    }


    var emptyTitle: String {

        switch selectedTab {

        case .upcoming:
            return "No Upcoming Gatherings"

        case .hosting:
            return "Nothing You're Hosting"

        case .past:
            return "No Past Gatherings"
        }
    }


    var emptyMessage: String {

        switch selectedTab {

        case .upcoming:
            return "Your upcoming gatherings will appear here."

        case .hosting:
            return "Gatherings you host will appear here."

        case .past:
            return "Past gatherings will appear here."
        }
    }
}


// MARK: - Error State

private extension GatheringsView {

    func errorState(
        _ message: String
    ) -> some View {

        VStack(
            spacing:
                KinSpacing.large
        ) {

            Image(
                systemName:
                    "exclamationmark.triangle"
            )
            .font(
                .system(
                    size: 42
                )
            )
            .foregroundStyle(
                KinColors.error
            )


            Text(
                "Unable to Load Gatherings"
            )
            .font(
                KinTypography.title2
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


            Button(
                "Try Again"
            ) {

                Task {
                    await loadGatherings()
                }
            }
            .font(
                KinTypography.button
            )
            .foregroundStyle(
                .white
            )
            .padding(
                .horizontal,
                KinSpacing.xLarge
            )
            .padding(
                .vertical,
                KinSpacing.medium
            )
            .background(
                KinColors.primary
            )
            .clipShape(
                Capsule()
            )
        }
        .padding(
            KinSpacing.large
        )
        .frame(
            maxWidth: .infinity,
            maxHeight: .infinity
        )
    }
}


// MARK: - Loading Data

private extension GatheringsView {

    @MainActor
    func loadGatherings() async {

        isLoading =
            true

        errorMessage =
            nil

        defer {
            isLoading =
                false
        }


        do {

            switch selectedTab {

            case .upcoming:

                gatherings =
                    try await GatheringService
                        .fetchUpcomingGatheringItems()


            case .hosting:

                gatherings =
                    try await GatheringService
                        .fetchHostedGatheringItems()


            case .past:

                gatherings =
                    try await GatheringService
                        .fetchPastGatheringItems()
            }

        } catch {

            gatherings =
                []

            errorMessage =
                "Please check your connection and try again."

            print(
                "GATHERINGS LOAD ERROR:",
                error.localizedDescription
            )
        }
    }
}


// MARK: - Formatting

private extension GatheringsView {

    func formattedDateTime(
        _ date: Date
    ) -> String {

        date.formatted(
            .dateTime
                .weekday(
                    .wide
                )
                .hour()
                .minute()
        )
    }


    func cleaned(
        _ value: String?
    ) -> String? {

        guard let value else {
            return nil
        }

        let cleanValue =
            value.trimmingCharacters(
                in:
                    .whitespacesAndNewlines
            )

        return cleanValue.isEmpty
            ? nil
            : cleanValue
    }
}


#Preview {

    NavigationStack {
        GatheringsView()
    }
}

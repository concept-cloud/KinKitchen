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
        case history = "History"
    }
    
    
    @State private var selectedTab: GatheringTab = .upcoming
    
    @State private var isLoading = true

    /// After the first load, coming back from an event refreshes
    /// quietly instead of showing the loader again.
    @State private var hasLoaded = false
    
    @State private var errorMessage: String?
    
    @State private var showingAddGathering = false
    
    @State private var gatherings: [GatheringListItem] = []

    @State private var notifications: [KinNotification] = []

    @State private var navigationPath = NavigationPath()
    
    
    var body: some View {
        
        NavigationStack(path: $navigationPath) {
            
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

                await loadGatherings(
                    showsLoading: !hasLoaded
                )
            }
            .navigationDestination(
                isPresented:
                    $showingAddGathering
            ) {
                
                AddGatheringView()
            }
            .navigationDestination(
                for: UUID.self
            ) { gatheringId in

                GatheringDetailView(
                    gatheringId: gatheringId
                )
            }
        }
    }
}


// MARK: - Header

private extension GatheringsView {

    var header: some View {

        HStack {

            Text(
                "Events"
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
                "Add Event"
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

                    NavigationLink(
                        value: item.gathering.id
                    ) {

                        KinEventCard(
                            item: item,
                            unread: notifications.unread(
                                forGathering: item.gathering.id
                            )
                        )
                    }
                    .buttonStyle(.kinPressable)
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
            // Pull to refresh has its own spinner.
            await loadGatherings(showsLoading: false)
        }
    }
}


// MARK: - Loading

private extension GatheringsView {

    var loadingState: some View {
        KinLoadingView(message: "Loading events...")
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
            return "No Upcoming Events"

        case .hosting:
            return "Nothing You're Hosting"

        case .history:
            return "No Event History Yet"
        }
    }


    var emptyMessage: String {

        switch selectedTab {

        case .upcoming:
            return "Your upcoming events will appear here."

        case .hosting:
            return "Events you host will appear here."

        case .history:
            return "Completed events you hosted or attended will appear here, with their guests and dishes."
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
                "Unable to Load Events"
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
    func loadGatherings(
        showsLoading: Bool = true
    ) async {

        if showsLoading {
            isLoading = true
            errorMessage = nil
        }

        defer {
            isLoading = false
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


            case .history:

                gatherings =
                    try await GatheringService
                        .fetchPastGatheringItems()
            }

            hasLoaded = true

        } catch {

            // A failed quiet refresh keeps the list already showing.
            if showsLoading {
                gatherings = []

                errorMessage =
                    "Please check your connection and try again."
            }

            print(
                "GATHERINGS LOAD ERROR:",
                error.localizedDescription
            )
        }

        // Notifications only drive the card indicators,
        // so a failure here shouldn't block the list.

        await loadNotifications()
    }


    @MainActor
    func loadNotifications() async {

        do {

            notifications =
                try await NotificationService
                    .fetchNotifications()

        } catch {

            if !(error is CancellationError) {

                print(
                    "GATHERINGS NOTIFICATION LOAD ERROR:",
                    error.localizedDescription
                )
            }
        }
    }
}


#Preview {

    NavigationStack {
        GatheringsView()
    }
}

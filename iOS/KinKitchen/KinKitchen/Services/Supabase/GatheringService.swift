//
//  GatheringService.swift
//  KinKitchen
//
//  Created by Greg Hudler on 9/9/26.
//

import Foundation
import Supabase


enum GatheringService {

    // MARK: - Create Gathering

    static func createGathering(
        name: String,
        description: String?,
        location: String?,
        startsAt: Date,
        guestLimit: Int?
    ) async throws -> Gathering {

        let user =
            try await SupabaseManager.client
                .auth
                .session
                .user

        let payload =
            GatheringCreate(
                hostId: user.id,
                name: name.trimmingCharacters(
                    in: .whitespacesAndNewlines
                ),
                description:
                    cleanedOptionalString(
                        description
                    ),
                location:
                    cleanedOptionalString(
                        location
                    ),
                startsAt:
                    startsAt,
                guestLimit:
                    guestLimit
            )

        let gathering: Gathering =
            try await SupabaseManager.client
                .from("gatherings")
                .insert(payload)
                .select()
                .single()
                .execute()
                .value

        return gathering
    }


    // MARK: - Fetch Gathering

    static func fetchGathering(
        id gatheringId: UUID
    ) async throws -> Gathering {

        let gathering: Gathering =
            try await SupabaseManager.client
                .from("gatherings")
                .select()
                .eq(
                    "id",
                    value: gatheringId
                )
                .single()
                .execute()
                .value

        return gathering
    }


    // MARK: - Fetch Upcoming Gatherings

    static func fetchUpcomingGatherings()
        async throws -> [Gathering] {

        let user =
            try await SupabaseManager.client
                .auth
                .session
                .user

        let now =
            Date()

        let hostedGatherings: [Gathering] =
            try await SupabaseManager.client
                .from("gatherings")
                .select()
                .eq(
                    "host_id",
                    value: user.id
                )
                .eq(
                    "status",
                    value:
                        GatheringStatus
                            .upcoming
                            .rawValue
                )
                .gte(
                    "starts_at",
                    value: now
                )
                .order(
                    "starts_at",
                    ascending: true
                )
                .execute()
                .value

        let participantRows:
            [GatheringParticipantLookup] =
            try await SupabaseManager.client
                .from("gathering_participants")
                .select(
                    """
                    gathering_id
                    """
                )
                .eq(
                    "user_id",
                    value: user.id
                )
                .execute()
                .value

        let participantGatheringIds =
            Set(
                participantRows.map(
                    \.gatheringId
                )
            )

        guard !participantGatheringIds.isEmpty else {
            return hostedGatherings
        }

        let participantGatherings:
            [Gathering] =
            try await SupabaseManager.client
                .from("gatherings")
                .select()
                .in(
                    "id",
                    values:
                        Array(
                            participantGatheringIds
                        )
                )
                .eq(
                    "status",
                    value:
                        GatheringStatus
                            .upcoming
                            .rawValue
                )
                .gte(
                    "starts_at",
                    value: now
                )
                .order(
                    "starts_at",
                    ascending: true
                )
                .execute()
                .value

        return mergeGatherings(
            hostedGatherings,
            participantGatherings
        )
    }


    // MARK: - Fetch Hosted Gatherings

    static func fetchHostedGatherings()
        async throws -> [Gathering] {

        let user =
            try await SupabaseManager.client
                .auth
                .session
                .user

        let gatherings:
            [Gathering] =
            try await SupabaseManager.client
                .from("gatherings")
                .select()
                .eq(
                    "host_id",
                    value: user.id
                )
                .order(
                    "starts_at",
                    ascending: true
                )
                .execute()
                .value

        return gatherings
    }


    // MARK: - Fetch Past Gatherings

    static func fetchPastGatherings()
        async throws -> [Gathering] {

        let user =
            try await SupabaseManager.client
                .auth
                .session
                .user

        let now =
            Date()

        let hostedGatherings: [Gathering] =
            try await SupabaseManager.client
                .from("gatherings")
                .select()
                .eq(
                    "host_id",
                    value: user.id
                )
                .lt(
                    "starts_at",
                    value: now
                )
                .order(
                    "starts_at",
                    ascending: false
                )
                .execute()
                .value

        let participantRows:
            [GatheringParticipantLookup] =
            try await SupabaseManager.client
                .from("gathering_participants")
                .select(
                    """
                    gathering_id
                    """
                )
                .eq(
                    "user_id",
                    value: user.id
                )
                .execute()
                .value

        let participantGatheringIds =
            Set(
                participantRows.map(
                    \.gatheringId
                )
            )

        guard !participantGatheringIds.isEmpty else {
            return hostedGatherings
        }

        let participantGatherings:
            [Gathering] =
            try await SupabaseManager.client
                .from("gatherings")
                .select()
                .in(
                    "id",
                    values:
                        Array(
                            participantGatheringIds
                        )
                )
                .lt(
                    "starts_at",
                    value: now
                )
                .order(
                    "starts_at",
                    ascending: false
                )
                .execute()
                .value

        return mergeGatherings(
            hostedGatherings,
            participantGatherings,
            descending: true
        )
    }


    // MARK: - Update Gathering

    static func updateGathering(
        id gatheringId: UUID,
        name: String,
        description: String?,
        location: String?,
        startsAt: Date,
        guestLimit: Int?
    ) async throws -> Gathering {

        let user =
            try await SupabaseManager.client
                .auth
                .session
                .user

        let payload =
            GatheringUpdate(
                name: name.trimmingCharacters(
                    in: .whitespacesAndNewlines
                ),
                description:
                    cleanedOptionalString(
                        description
                    ),
                location:
                    cleanedOptionalString(
                        location
                    ),
                startsAt:
                    startsAt,
                guestLimit:
                    guestLimit
            )

        let gathering: Gathering =
            try await SupabaseManager.client
                .from("gatherings")
                .update(payload)
                .eq(
                    "id",
                    value: gatheringId
                )
                .eq(
                    "host_id",
                    value: user.id
                )
                .select()
                .single()
                .execute()
                .value

        return gathering
    }


    // MARK: - Cancel Gathering

    static func cancelGathering(
        id gatheringId: UUID
    ) async throws -> Gathering {

        let user =
            try await SupabaseManager.client
                .auth
                .session
                .user

        let payload =
            GatheringStatusUpdate(
                status: .cancelled
            )

        let gathering: Gathering =
            try await SupabaseManager.client
                .from("gatherings")
                .update(payload)
                .eq(
                    "id",
                    value: gatheringId
                )
                .eq(
                    "host_id",
                    value: user.id
                )
                .select()
                .single()
                .execute()
                .value

        return gathering
    }


    // MARK: - Mark Gathering Completed

    static func completeGathering(
        id gatheringId: UUID
    ) async throws -> Gathering {

        let user =
            try await SupabaseManager.client
                .auth
                .session
                .user

        let payload =
            GatheringStatusUpdate(
                status: .completed
            )

        let gathering: Gathering =
            try await SupabaseManager.client
                .from("gatherings")
                .update(payload)
                .eq(
                    "id",
                    value: gatheringId
                )
                .eq(
                    "host_id",
                    value: user.id
                )
                .select()
                .single()
                .execute()
                .value

        return gathering
    }


    // MARK: - Helpers

    private static func mergeGatherings(
        _ first: [Gathering],
        _ second: [Gathering],
        descending: Bool = false
    ) -> [Gathering] {

        var gatheringsById:
            [UUID: Gathering] = [:]

        for gathering in first {
            gatheringsById[
                gathering.id
            ] = gathering
        }

        for gathering in second {
            gatheringsById[
                gathering.id
            ] = gathering
        }

        return gatheringsById
            .values
            .sorted {

                if descending {
                    return $0.startsAt >
                        $1.startsAt
                }

                return $0.startsAt <
                    $1.startsAt
            }
    }


    private static func cleanedOptionalString(
        _ value: String?
    ) -> String? {

        guard let value else {
            return nil
        }

        let cleaned =
            value.trimmingCharacters(
                in:
                    .whitespacesAndNewlines
            )

        return cleaned.isEmpty
            ? nil
            : cleaned
    }
    
    // MARK: - Fetch Upcoming Gathering List Items

    static func fetchUpcomingGatheringItems()
        async throws -> [GatheringListItem] {

        let user =
            try await SupabaseManager.client
                .auth
                .session
                .user

        let now =
            Date()


        // MARK: Gatherings Current User Hosts

        let hostedGatherings:
            [Gathering] =
            try await SupabaseManager.client
                .from("gatherings")
                .select()
                .eq(
                    "host_id",
                    value: user.id
                )
                .eq(
                    "status",
                    value:
                        GatheringStatus
                            .upcoming
                            .rawValue
                )
                .gte(
                    "starts_at",
                    value: now
                )
                .order(
                    "starts_at",
                    ascending: true
                )
                .execute()
                .value


        var itemsById:
            [UUID: GatheringListItem] = [:]


        for gathering in hostedGatherings {

            itemsById[
                gathering.id
            ] =
                GatheringListItem(
                    gathering:
                        gathering,
                    relationship:
                        .hosting
                )
        }


        // MARK: Gatherings Current User Is Invited To

        let participantRows:
            [GatheringParticipantListLookup] =
            try await SupabaseManager.client
                .from(
                    "gathering_participants"
                )
                .select(
                    """
                    gathering_id,
                    status
                    """
                )
                .eq(
                    "user_id",
                    value:
                        user.id
                )
                .in(
                    "status",
                    values: [
                        InvitationStatus
                            .pending
                            .rawValue,

                        InvitationStatus
                            .accepted
                            .rawValue
                    ]
                )
                .execute()
                .value


        guard !participantRows.isEmpty else {

            return itemsById
                .values
                .sorted {
                    $0.gathering.startsAt <
                        $1.gathering.startsAt
                }
        }


        let gatheringIds =
            Array(
                Set(
                    participantRows.map(
                        \.gatheringId
                    )
                )
            )


        let participantGatherings:
            [Gathering] =
            try await SupabaseManager.client
                .from("gatherings")
                .select()
                .in(
                    "id",
                    values:
                        gatheringIds
                )
                .eq(
                    "status",
                    value:
                        GatheringStatus
                            .upcoming
                            .rawValue
                )
                .gte(
                    "starts_at",
                    value:
                        now
                )
                .order(
                    "starts_at",
                    ascending:
                        true
                )
                .execute()
                .value


        let participantStatusByGatheringId =
            Dictionary(
                uniqueKeysWithValues:
                    participantRows.map {
                        (
                            $0.gatheringId,
                            $0.status
                        )
                    }
            )


        for gathering in participantGatherings {

            // If somehow the host also has a participant
            // record, Hosting always wins.

            guard
                itemsById[
                    gathering.id
                ] == nil
            else {
                continue
            }


            guard let invitationStatus =
                participantStatusByGatheringId[
                    gathering.id
                ]
            else {
                continue
            }


            let relationship:
                GatheringRelationship


            switch invitationStatus {

            case .pending:

                relationship =
                    .invited


            case .accepted:

                relationship =
                    .going


            case .declined:

                continue
            }


            itemsById[
                gathering.id
            ] =
                GatheringListItem(
                    gathering:
                        gathering,
                    relationship:
                        relationship
                )
        }


        return itemsById
            .values
            .sorted {
                $0.gathering.startsAt <
                    $1.gathering.startsAt
            }
    }


    // MARK: - Fetch Hosted Gathering List Items

    static func fetchHostedGatheringItems()
        async throws -> [GatheringListItem] {

        let user =
            try await SupabaseManager.client
                .auth
                .session
                .user

        let now =
            Date()


        let gatherings:
            [Gathering] =
            try await SupabaseManager.client
                .from("gatherings")
                .select()
                .eq(
                    "host_id",
                    value:
                        user.id
                )
                .eq(
                    "status",
                    value:
                        GatheringStatus
                            .upcoming
                            .rawValue
                )
                .gte(
                    "starts_at",
                    value:
                        now
                )
                .order(
                    "starts_at",
                    ascending:
                        true
                )
                .execute()
                .value


        return gatherings.map {

            GatheringListItem(
                gathering:
                    $0,
                relationship:
                    .hosting
            )
        }
    }


    // MARK: - Fetch Past Gathering List Items

    static func fetchPastGatheringItems()
        async throws -> [GatheringListItem] {

        let user =
            try await SupabaseManager.client
                .auth
                .session
                .user

        let now =
            Date()


        // MARK: Hosted History

        let hostedGatherings:
            [Gathering] =
            try await SupabaseManager.client
                .from("gatherings")
                .select()
                .eq(
                    "host_id",
                    value:
                        user.id
                )
                .lt(
                    "starts_at",
                    value:
                        now
                )
                .order(
                    "starts_at",
                    ascending:
                        false
                )
                .execute()
                .value


        var itemsById:
            [UUID: GatheringListItem] = [:]


        for gathering in hostedGatherings {

            itemsById[
                gathering.id
            ] =
                GatheringListItem(
                    gathering:
                        gathering,
                    relationship:
                        .hosting
                )
        }


        // MARK: Accepted Participant History

        let participantRows:
            [GatheringParticipantListLookup] =
            try await SupabaseManager.client
                .from(
                    "gathering_participants"
                )
                .select(
                    """
                    gathering_id,
                    status
                    """
                )
                .eq(
                    "user_id",
                    value:
                        user.id
                )
                .eq(
                    "status",
                    value:
                        InvitationStatus
                            .accepted
                            .rawValue
                )
                .execute()
                .value


        guard !participantRows.isEmpty else {

            return itemsById
                .values
                .sorted {
                    $0.gathering.startsAt >
                        $1.gathering.startsAt
                }
        }


        let gatheringIds =
            Array(
                Set(
                    participantRows.map(
                        \.gatheringId
                    )
                )
            )


        let participantGatherings:
            [Gathering] =
            try await SupabaseManager.client
                .from("gatherings")
                .select()
                .in(
                    "id",
                    values:
                        gatheringIds
                )
                .lt(
                    "starts_at",
                    value:
                        now
                )
                .order(
                    "starts_at",
                    ascending:
                        false
                )
                .execute()
                .value


        for gathering in participantGatherings {

            guard
                itemsById[
                    gathering.id
                ] == nil
            else {
                continue
            }


            itemsById[
                gathering.id
            ] =
                GatheringListItem(
                    gathering:
                        gathering,
                    relationship:
                        .going
                )
        }


        return itemsById
            .values
            .sorted {
                $0.gathering.startsAt >
                    $1.gathering.startsAt
            }
    }
}

// MARK: - Gathering List Item

struct GatheringListItem:
    Identifiable,
    Hashable {

    let gathering:
        Gathering

    let relationship:
        GatheringRelationship


    var id: UUID {
        gathering.id
    }
}


// MARK: - Gathering Relationship

enum GatheringRelationship:
    String,
    Hashable {

    case hosting

    case invited

    case going


    var displayName: String {

        switch self {

        case .hosting:
            return "Hosting"

        case .invited:
            return "Invited"

        case .going:
            return "Going"
        }
    }
}


// MARK: - Invitation Status

enum InvitationStatus:
    String,
    Codable,
    Hashable {

    case pending

    case accepted

    case declined
}


// MARK: - Gathering Participant List Lookup

private struct GatheringParticipantListLookup:
    Decodable {

    let gatheringId:
        UUID

    let status:
        InvitationStatus


    enum CodingKeys:
        String,
        CodingKey {

        case gatheringId =
            "gathering_id"

        case status
    }
}
// MARK: - Participant Lookup

private struct GatheringParticipantLookup:
    Decodable {

    let gatheringId: UUID

    enum CodingKeys:
        String,
        CodingKey {

        case gatheringId =
            "gathering_id"
    }
}

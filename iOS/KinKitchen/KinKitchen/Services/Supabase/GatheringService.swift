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
        theme: String?,
        eventType: KinEventType?,
        coverImagePath: String?,
        description: String?,
        location: String?,
        startsAt: Date,
        endsAt: Date?,
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
                theme:
                    cleanedOptionalString(
                        theme
                    ),
                eventType: eventType,
                coverImagePath:
                    cleanedOptionalString(
                        coverImagePath
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
                endsAt:
                    endsAt,
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
                    "active_through",
                    value: now.addingTimeInterval(-Gathering.activeWindowAfterStart)
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
                    "active_through",
                    value: now.addingTimeInterval(-Gathering.activeWindowAfterStart)
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
        theme: String?,
        eventType: KinEventType?,
        coverImagePath: String?,
        description: String?,
        location: String?,
        startsAt: Date,
        endsAt: Date?,
        guestLimit: Int?
    ) async throws -> Gathering {

        struct Parameters: Encodable {

            let gatheringId: UUID
            let name: String
            let theme: String?
            /// nil keeps the event's current type.
            let eventType: KinEventType?
            let coverImagePath: String?
            let description: String?
            let location: String?
            let startsAt: Date
            /// nil for one-day events. Left out of the call, which the
            /// database reads as "no end" whenever a type is sent.
            let endsAt: Date?
            let guestLimit: Int?

            enum CodingKeys:
                String,
                CodingKey {

                case gatheringId =
                    "p_gathering_id"

                case name =
                    "p_name"

                case theme =
                    "p_theme"

                case eventType =
                    "p_event_type"

                case coverImagePath =
                    "p_cover_image_path"

                case description =
                    "p_description"

                case location =
                    "p_location"

                case startsAt =
                    "p_starts_at"

                case endsAt =
                    "p_ends_at"

                case guestLimit =
                    "p_guest_limit"
            }
        }

        let parameters =
            Parameters(
                gatheringId: gatheringId,
                name:
                    name.trimmingCharacters(
                        in: .whitespacesAndNewlines
                    ),
                theme:
                    cleanedOptionalString(
                        theme
                    ),
                eventType: eventType,
                coverImagePath:
                    cleanedOptionalString(
                        coverImagePath
                    ),
                description:
                    cleanedOptionalString(
                        description
                    ),
                location:
                    cleanedOptionalString(
                        location
                    ),
                startsAt: startsAt,
                endsAt: endsAt,
                guestLimit: guestLimit
            )

        let gathering: Gathering =
            try await SupabaseManager.client
                .rpc(
                    "update_gathering_with_notifications",
                    params: parameters
                )
                .single()
                .execute()
                .value

        return gathering
    }
    
    
    // MARK: - Cancel Gathering

    /// Cancels an upcoming gathering the user hosts. Everything is kept
    /// and invited guests are notified (see supabase/KINKIT-183).
    static func cancelGathering(
        id gatheringId: UUID
    ) async throws -> Gathering {

        let gathering: Gathering =
            try await SupabaseManager.client
                .rpc(
                    "cancel_gathering",
                    params: ["p_gathering_id": gatheringId]
                )
                .single()
                .execute()
                .value

        return gathering
    }


    /// Friendly text for the database's cancel/delete refusal reasons.
    static func friendlyMessage(
        for error: Error,
        fallback: String
    ) -> String {

        let description =
            String(describing: error)

        if description.contains("NOT_GATHERING_HOST") {
            return "Only the host can do this."
        }

        if description.contains("GATHERING_ALREADY_OCCURRED") {
            return "This event has already happened, so it's kept in Event History and can't be deleted."
        }

        if description.contains("GATHERING_CANNOT_BE_CANCELLED") {
            return "Only upcoming events that haven't started can be cancelled."
        }

        return fallback
    }


    // MARK: - Delete Gathering

    /// Permanently deletes an upcoming or cancelled gathering the user
    /// hosts, with its guests, dishes and claims, in one database
    /// transaction. Gatherings that happened can't be deleted.
    static func deleteGathering(
        id gatheringId: UUID
    ) async throws {

        let result: GatheringDeletionResult =
            try await SupabaseManager.client
                .rpc(
                    "delete_gathering",
                    params: ["p_gathering_id": gatheringId]
                )
                .execute()
                .value

        // Already deleted; a leftover photo shouldn't fail the delete.
        if let coverPath = result.coverImagePath,
           !coverPath.isEmpty {
            _ = try? await SupabaseManager.client.storage
                .from("gathering-photos")
                .remove(paths: [coverPath])
        }
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
                    "active_through",
                    value: now.addingTimeInterval(-Gathering.activeWindowAfterStart)
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
                    "active_through",
                    value:
                        now.addingTimeInterval(-Gathering.activeWindowAfterStart)
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
                // Cancelled gatherings stay here for the host (marked
                // Cancelled) so they can still be deleted.
                .in(
                    "status",
                    values: [
                        GatheringStatus.upcoming.rawValue,
                        GatheringStatus.cancelled.rawValue
                    ]
                )
                .gte(
                    "active_through",
                    value:
                        now.addingTimeInterval(-Gathering.activeWindowAfterStart)
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

        // History is decided by Gathering.isHistorical, not the
        // date alone, so a gathering the host completed early
        // moves here too.
        let allHostedGatherings:
            [Gathering] =
            try await SupabaseManager.client
                .from("gatherings")
                .select()
                .eq(
                    "host_id",
                    value:
                        user.id
                )
                .order(
                    "starts_at",
                    ascending:
                        false
                )
                .execute()
                .value

        let hostedGatherings =
            allHostedGatherings.filter {
                $0.isHistorical(asOf: now)
            }


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


        let allParticipantGatherings:
            [Gathering] =
            try await SupabaseManager.client
                .from("gatherings")
                .select()
                .in(
                    "id",
                    values:
                        gatheringIds
                )
                .order(
                    "starts_at",
                    ascending:
                        false
                )
                .execute()
                .value

        let participantGatherings =
            allParticipantGatherings.filter {
                $0.isHistorical(asOf: now)
            }


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

// MARK: - Gathering Deletion Result

/// What `delete_gathering` returns.
private struct GatheringDeletionResult: Decodable {

    let coverImagePath: String?

    enum CodingKeys: String, CodingKey {
        case coverImagePath = "cover_image_path"
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

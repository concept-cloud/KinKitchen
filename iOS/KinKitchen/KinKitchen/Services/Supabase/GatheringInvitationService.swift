import Foundation
import Supabase

// MARK: - Gathering Invitation Service

enum GatheringInvitationService {

    // MARK: - Create Invitation

    static func createInvitation(
        gatheringId: UUID,
        userId: UUID
    ) async throws -> GatheringParticipant {

        struct Parameters: Encodable {

            let gatheringId: UUID
            let userId: UUID

            enum CodingKeys:
                String,
                CodingKey {

                case gatheringId = "p_gathering_id"
                case userId = "p_user_id"
            }
        }

        let parameters =
            Parameters(
                gatheringId: gatheringId,
                userId: userId
            )

        let invitation: GatheringParticipant =
            try await SupabaseManager.client
                .rpc(
                    "create_gathering_invitation",
                    params: parameters
                )
                .single()
                .execute()
                .value

        return invitation
    }

    // MARK: - Fetch Gathering Invitations

    static func fetchInvitations(
        gatheringId: UUID
    ) async throws -> [GatheringParticipant] {

        let invitations: [GatheringParticipant] =
            try await SupabaseManager.client
                .from("gathering_participants")
                .select()
                .eq(
                    "gathering_id",
                    value: gatheringId
                )
                .order(
                    "invited_at",
                    ascending: true
                )
                .execute()
                .value

        return invitations
    }

    // MARK: - Fetch Current User Invitations

    static func fetchCurrentUserInvitations()
        async throws -> [GatheringParticipant] {

        let user =
            try await SupabaseManager.client
                .auth
                .session
                .user

        let invitations: [GatheringParticipant] =
            try await SupabaseManager.client
                .from("gathering_participants")
                .select()
                .eq(
                    "user_id",
                    value: user.id
                )
                .order(
                    "invited_at",
                    ascending: false
                )
                .execute()
                .value

        return invitations
    }

    // MARK: - Fetch Pending Current User Invitations

    static func fetchPendingInvitations()
        async throws -> [GatheringParticipant] {

        let user =
            try await SupabaseManager.client
                .auth
                .session
                .user

        let invitations: [GatheringParticipant] =
            try await SupabaseManager.client
                .from("gathering_participants")
                .select()
                .eq(
                    "user_id",
                    value: user.id
                )
                .eq(
                    "status",
                    value: InvitationStatus.pending.rawValue
                )
                .order(
                    "invited_at",
                    ascending: false
                )
                .execute()
                .value

        return invitations
    }

    // MARK: - Update Invitation Status

    static func updateInvitationStatus(
        gatheringId: UUID,
        status: InvitationStatus
    ) async throws -> GatheringParticipant {

        struct Parameters: Encodable {

            let gatheringId: UUID
            let status: String

            enum CodingKeys:
                String,
                CodingKey {

                case gatheringId = "p_gathering_id"
                case status = "p_status"
            }
        }

        let parameters =
            Parameters(
                gatheringId: gatheringId,
                status: status.rawValue
            )

        let invitation: GatheringParticipant =
            try await SupabaseManager.client
                .rpc(
                    "respond_to_gathering_invitation",
                    params: parameters
                )
                .single()
                .execute()
                .value

        return invitation
    }

    // MARK: - Accept Invitation

    static func acceptInvitation(
        gatheringId: UUID
    ) async throws -> GatheringParticipant {

        try await updateInvitationStatus(
            gatheringId: gatheringId,
            status: .accepted
        )
    }

    // MARK: - Decline Invitation

    static func declineInvitation(
        gatheringId: UUID
    ) async throws -> GatheringParticipant {

        try await updateInvitationStatus(
            gatheringId: gatheringId,
            status: .declined
        )
    }
}

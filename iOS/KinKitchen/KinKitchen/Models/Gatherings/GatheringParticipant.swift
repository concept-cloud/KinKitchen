//
//  GatheringParticipant.swift
//  KinKitchen
//
//  Created by Greg Hudler on 9/17/26.
//

import Foundation

// MARK: - Gathering Participant

struct GatheringParticipant:
    Codable,
    Hashable {

    let gatheringId: UUID
    let userId: UUID
    let role: ParticipantRole
    let status: InvitationStatus
    let invitedAt: Date
    let respondedAt: Date?

    enum CodingKeys:
        String,
        CodingKey {

        case gatheringId =
            "gathering_id"
        case userId =
            "user_id"
        case role
        case status
        case invitedAt =
            "invited_at"
        case respondedAt =
            "responded_at"
    }
}

// MARK: - Participant Role

enum ParticipantRole:
    String,
    Codable,
    Hashable {

    case host
    case guest
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

// MARK: - Gathering Participant Create

struct GatheringParticipantCreate:
    Encodable {

    let gatheringId: UUID
    let userId: UUID
    let role: ParticipantRole
    let status: InvitationStatus

    enum CodingKeys:
        String,
        CodingKey {

        case gatheringId =
            "gathering_id"
        case userId =
            "user_id"
        case role
        case status
    }
}

// MARK: - Gathering Participant Status Update

struct GatheringParticipantStatusUpdate:
    Encodable {

    let status: InvitationStatus
    let respondedAt: Date?

    enum CodingKeys:
        String,
        CodingKey {

        case status
        case respondedAt =
            "responded_at"
    }
}

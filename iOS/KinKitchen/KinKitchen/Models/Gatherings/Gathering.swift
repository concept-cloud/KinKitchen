//
//  Gathering.swift
//  KinKitchen
//
//  Created by Greg Hudler on 9/9/26.
//

import Foundation


// MARK: - Gathering

struct Gathering:
    Codable,
    Identifiable,
    Hashable {

    let id: UUID

    let hostId: UUID

    var name: String

    var description: String?

    var location: String?

    var startsAt: Date

    var guestLimit: Int?

    var status: GatheringStatus

    let createdAt: Date

    var updatedAt: Date


    enum CodingKeys:
        String,
        CodingKey {

        case id

        case hostId =
            "host_id"

        case name

        case description

        case location

        case startsAt =
            "starts_at"

        case guestLimit =
            "guest_limit"

        case status

        case createdAt =
            "created_at"

        case updatedAt =
            "updated_at"
    }
}


// MARK: - Gathering Status

enum GatheringStatus:
    String,
    Codable,
    Hashable {

    case upcoming

    case completed

    case cancelled
}


// MARK: - Gathering Create

struct GatheringCreate:
    Encodable {

    let hostId: UUID

    let name: String

    let description: String?

    let location: String?

    let startsAt: Date

    let guestLimit: Int?


    enum CodingKeys:
        String,
        CodingKey {

        case hostId =
            "host_id"

        case name

        case description

        case location

        case startsAt =
            "starts_at"

        case guestLimit =
            "guest_limit"
    }
}


// MARK: - Gathering Update

struct GatheringUpdate:
    Encodable {

    let name: String

    let description: String?

    let location: String?

    let startsAt: Date

    let guestLimit: Int?


    enum CodingKeys:
        String,
        CodingKey {

        case name

        case description

        case location

        case startsAt =
            "starts_at"

        case guestLimit =
            "guest_limit"
    }
}


// MARK: - Gathering Status Update

struct GatheringStatusUpdate:
    Encodable {

    let status: GatheringStatus
}

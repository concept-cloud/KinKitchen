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
    var theme: String?
    /// nil for events made before event types.
    var eventType: KinEventType? = nil
    var coverImagePath: String?
    var description: String?
    var location: String?
    var startsAt: Date
    /// Last day of an event that runs over several days, like a Meal
    /// Train. nil for one-day events.
    var endsAt: Date? = nil
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

        case theme

        case eventType =
            "event_type"

        case coverImagePath =
            "cover_image_path"

        case description

        case location

        case startsAt =
            "starts_at"

        case endsAt =
            "ends_at"

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


// MARK: - Completion

extension Gathering {

    /// How long a gathering stays active after it starts, so guests
    /// can still claim dishes and the host can still edit while it's
    /// happening. After this it moves to History automatically.
    static let activeWindowAfterStart: TimeInterval =
        12 * 60 * 60


    /// The last day it runs: the end for a date range, otherwise
    /// the start. Matches `gatherings.active_through`.
    var activeThrough: Date {
        endsAt ?? startsAt
    }


    /// Runs over more than one day, like a Meal Train.
    var isDateRange: Bool {
        endsAt != nil
    }


    /// When the gathering automatically moves to History: after
    /// the last day for a date range.
    var autoCompletesAt: Date {

        activeThrough.addingTimeInterval(
            Self.activeWindowAfterStart
        )
    }


    /// Completed when the host marked it, or automatically once
    /// the active window after its start has passed. Cancelled
    /// gatherings are never completed.
    func isCompleted(
        asOf now: Date = Date()
    ) -> Bool {

        switch status {
        case .completed:
            return true
        case .upcoming:
            return autoCompletesAt < now
        case .cancelled:
            return false
        }
    }


    /// Matches cancel_gathering (supabase/KINKIT-183): only an
    /// upcoming gathering that hasn't started.
    func canBeCancelled(
        asOf now: Date = Date()
    ) -> Bool {

        status == .upcoming
            && startsAt > now
    }


    /// Matches delete_gathering (supabase/KINKIT-183): a cancelled
    /// gathering, or an upcoming one that hasn't started. Anything
    /// that happened stays in Gathering History.
    func canBeDeleted(
        asOf now: Date = Date()
    ) -> Bool {

        status == .cancelled
            || canBeCancelled(asOf: now)
    }


    /// Still active: upcoming or happening now, not completed
    /// (by the host or by time) and not cancelled.
    func isActive(
        asOf now: Date = Date()
    ) -> Bool {

        status == .upcoming
            && autoCompletesAt >= now
    }


    /// Belongs in Gathering History: completed (by the host or by
    /// date), or cancelled once its date has passed.
    func isHistorical(
        asOf now: Date = Date()
    ) -> Bool {

        isCompleted(asOf: now)
            || (status == .cancelled && startsAt < now)
    }


    /// Status to show, with past gatherings shown as completed.
    func displayStatus(
        asOf now: Date = Date()
    ) -> GatheringStatus {

        isCompleted(asOf: now)
            ? .completed
            : status
    }
}


// MARK: - Gathering Create

struct GatheringCreate:
    Encodable {

    let hostId: UUID

    let name: String
    let theme: String?
    let eventType: KinEventType?
    let coverImagePath: String?
    let description: String?
    let location: String?
    let startsAt: Date
    let endsAt: Date?
    let guestLimit: Int?


    enum CodingKeys:
        String,
        CodingKey {

        case hostId =
            "host_id"

        case name

        case theme

        case eventType =
            "event_type"

        case coverImagePath =
            "cover_image_path"

        case description

        case location

        case startsAt =
            "starts_at"

        case endsAt =
            "ends_at"

        case guestLimit =
            "guest_limit"
    }
}


// MARK: - Gathering Update

struct GatheringUpdate:
    Encodable {

    let name: String
    let theme: String?
    let eventType: KinEventType?
    let coverImagePath: String?
    let description: String?
    let location: String?
    let startsAt: Date
    let endsAt: Date?
    let guestLimit: Int?


    enum CodingKeys:
        String,
        CodingKey {

        case name

        case theme

        case eventType =
            "event_type"

        case coverImagePath =
            "cover_image_path"

        case description

        case location

        case startsAt =
            "starts_at"

        case endsAt =
            "ends_at"

        case guestLimit =
            "guest_limit"
    }
}


// MARK: - Gathering Status Update

struct GatheringStatusUpdate:
    Encodable {

    let status: GatheringStatus
}

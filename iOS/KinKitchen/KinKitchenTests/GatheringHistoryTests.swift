//
//  GatheringHistoryTests.swift
//  KinKitchenTests
//
//  Created by Greg Hudler on 10/4/26.
//

import Foundation
import Testing
@testable import KinKitchen

/// KINKIT-145: completed gatherings and history.
struct GatheringHistoryTests {

    static let now = Date()

    static func gathering(
        status: GatheringStatus,
        daysFromNow: Double
    ) -> Gathering {
        Gathering(
            id: UUID(),
            hostId: UUID(),
            name: "Sunday Supper",
            theme: nil,
            coverImagePath: nil,
            description: nil,
            location: nil,
            startsAt:
                now.addingTimeInterval(daysFromNow * 86_400),
            guestLimit: nil,
            status: status,
            createdAt: now,
            updatedAt: now
        )
    }

    // MARK: - KINKIT-153 Completed State

    @Test func markedCompletedIsCompletedEvenBeforeItsDate() {
        let gathering =
            Self.gathering(status: .completed, daysFromNow: 3)

        #expect(gathering.isCompleted(asOf: Self.now))
        #expect(!gathering.isActive(asOf: Self.now))
    }

    @Test func pastUpcomingGatheringCountsAsCompleted() {
        let gathering =
            Self.gathering(status: .upcoming, daysFromNow: -1)

        #expect(gathering.isCompleted(asOf: Self.now))
        #expect(gathering.displayStatus(asOf: Self.now) == .completed)
    }

    @Test func futureUpcomingGatheringIsActive() {
        let gathering =
            Self.gathering(status: .upcoming, daysFromNow: 2)

        #expect(gathering.isActive(asOf: Self.now))
        #expect(!gathering.isCompleted(asOf: Self.now))
        #expect(gathering.displayStatus(asOf: Self.now) == .upcoming)
    }

    @Test func cancelledIsNeverCompleted() {
        let past =
            Self.gathering(status: .cancelled, daysFromNow: -5)

        #expect(!past.isCompleted(asOf: Self.now))
        #expect(!past.isActive(asOf: Self.now))
        #expect(past.displayStatus(asOf: Self.now) == .cancelled)
    }

    @Test func completedStatusDecodesFromSupabase() throws {
        let json = """
        {
          "id": "6F1C2C6E-1B7A-4C3B-9D0E-2A4F5B6C7D8E",
          "host_id": "0A1B2C3D-4E5F-6071-8293-A4B5C6D7E8F9",
          "name": "Sunday Supper",
          "starts_at": "2026-09-01T18:00:00Z",
          "status": "completed",
          "created_at": "2026-08-01T00:00:00Z",
          "updated_at": "2026-09-02T00:00:00Z"
        }
        """

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let gathering =
            try decoder.decode(
                Gathering.self,
                from: Data(json.utf8)
            )

        #expect(gathering.status == .completed)
        #expect(
            gathering.id.uuidString
                == "6F1C2C6E-1B7A-4C3B-9D0E-2A4F5B6C7D8E"
        )
    }

    @Test func completedStatusEncodesForSupabase() throws {
        let data =
            try JSONEncoder().encode(
                GatheringStatusUpdate(status: .completed)
            )

        #expect(
            String(decoding: data, as: UTF8.self)
                == #"{"status":"completed"}"#
        )
    }
}

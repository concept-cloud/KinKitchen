//
//  GatheringNotesService.swift
//  KinKitchen
//
//  Created by Greg Hudler on 10/4/26.
//

import Foundation
import Supabase

// MARK: - Gathering Host Notes

/// A host's private notes on a gathering. Row in `gathering_host_notes`;
/// only the host can read or write it.
struct GatheringHostNotes: Codable, Hashable {

    let gatheringId: UUID
    var notes: String

    enum CodingKeys: String, CodingKey {
        case gatheringId = "gathering_id"
        case notes
    }
}

// MARK: - Gathering Notes Service

enum GatheringNotesService {

    /// The host's notes, or an empty string when there are none.
    static func fetchNotes(
        gatheringId: UUID
    ) async throws -> String {

        let rows: [GatheringHostNotes] =
            try await SupabaseManager.client
                .from("gathering_host_notes")
                .select("gathering_id, notes")
                .eq(
                    "gathering_id",
                    value: gatheringId
                )
                .limit(1)
                .execute()
                .value

        return rows.first?.notes ?? ""
    }


    static func saveNotes(
        gatheringId: UUID,
        notes: String
    ) async throws {

        try await SupabaseManager.client
            .from("gathering_host_notes")
            .upsert(
                GatheringHostNotes(
                    gatheringId: gatheringId,
                    notes: notes
                ),
                onConflict: "gathering_id"
            )
            .execute()
    }
}

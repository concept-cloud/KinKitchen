//
//  EventDietaryNeed.swift
//  KinKitchen
//
//  Created by Greg Hudler on 10/15/26.
//

import Foundation

/// An allergy, restriction or preference added straight to an event
/// (`gathering_dietary_needs`), e.g. for a Meal Train where the person
/// being helped isn't on Kin Kitchen.
///
/// Built-in items keep their catalog id so the allergen checks match
/// them; ones the host typed in have none and are matched by name.
struct EventDietaryNeed: Codable, Hashable, Identifiable {

    let kind: CustomDietaryItem.Kind
    var catalogId: UUID?
    let name: String

    var isCustom: Bool {
        catalogId == nil
    }

    /// Built-in items by catalog id, typed-in ones by name.
    var id: String {
        "\(kind.rawValue):"
            + (catalogId?.uuidString ?? CustomDietaryMatcher.normalize(name))
    }

    enum CodingKeys: String, CodingKey {
        case kind
        case catalogId = "catalog_id"
        case name
    }
}


extension Array where Element == EventDietaryNeed {

    func of(
        _ kind: CustomDietaryItem.Kind
    ) -> [EventDietaryNeed] {
        filter { $0.kind == kind }
    }

    /// Allergens first, then restrictions, then preferences, each A–Z.
    var sortedForDisplay: [EventDietaryNeed] {
        let order: [CustomDietaryItem.Kind] = [.allergen, .restriction, .preference]
        return sorted {
            let first = order.firstIndex(of: $0.kind) ?? 0
            let second = order.firstIndex(of: $1.kind) ?? 0
            if first != second {
                return first < second
            }
            return $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
        }
    }

    /// The same shape the recipe checks use for a person.
    func dietaryInformation(
        eventId: UUID
    ) -> RecipientDietaryInformation {

        // Typed-in items need an id of their own; a stable one keeps
        // conflict rows from jumping around.
        func id(for need: EventDietaryNeed) -> UUID {
            need.catalogId ?? UUID.stable(from: need.id)
        }

        let created = Date(timeIntervalSince1970: 0)

        return RecipientDietaryInformation(
            userId: eventId,
            allergens: of(.allergen).map {
                Allergen(id: id(for: $0), name: $0.name, createdAt: created, isCustom: $0.isCustom)
            },
            restrictions: of(.restriction).map {
                DietaryRestriction(id: id(for: $0), name: $0.name, createdAt: created, isCustom: $0.isCustom)
            },
            preferences: of(.preference).map {
                DietaryPreference(id: id(for: $0), name: $0.name, createdAt: created, isCustom: $0.isCustom)
            }
        )
    }
}


private extension UUID {

    /// Same text, same UUID (FNV-1a over the bytes).
    nonisolated static func stable(from text: String) -> UUID {
        var first: UInt64 = 0xcbf29ce484222325
        var second: UInt64 = 0x84222325cbf29ce4
        for byte in text.utf8 {
            first = (first ^ UInt64(byte)) &* 0x100000001b3
            second = (second ^ UInt64(byte)) &* 0x100000001b3 &+ 1
        }
        let bytes = withUnsafeBytes(of: first.bigEndian) { Array($0) }
            + withUnsafeBytes(of: second.bigEndian) { Array($0) }
        return UUID(uuid: (
            bytes[0], bytes[1], bytes[2], bytes[3],
            bytes[4], bytes[5], bytes[6], bytes[7],
            bytes[8], bytes[9], bytes[10], bytes[11],
            bytes[12], bytes[13], bytes[14], bytes[15]
        ))
    }
}

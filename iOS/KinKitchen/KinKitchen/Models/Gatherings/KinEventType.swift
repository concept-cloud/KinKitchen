//
//  KinEventType.swift
//  KinKitchen
//
//  Created by Greg Hudler on 10/15/26.
//

import Foundation

/// What kind of event it is. Stored in `gatherings.event_type`
/// (supabase/REGRESSION-event-types). Older events have none.
nonisolated enum KinEventType: String, CaseIterable, Identifiable, Hashable, Codable {

    case backyardBBQ = "backyard_bbq"
    case potluck
    case buffet
    case dinnerParty = "dinner_party"
    case mealTrain = "meal_train"
    case holiday
    case brunch
    case celebration
    case other

    var id: String { rawValue }

    var title: String {
        switch self {
        case .backyardBBQ: return "Backyard BBQ"
        case .potluck: return "Potluck"
        case .buffet: return "Buffet Style"
        case .dinnerParty: return "Dinner Party"
        case .mealTrain: return "Meal Train"
        case .holiday: return "Holiday"
        case .brunch: return "Brunch"
        case .celebration: return "Celebration"
        case .other: return "Other"
        }
    }

    var subtitle: String {
        switch self {
        case .backyardBBQ: return "Grill, sides and the great outdoors"
        case .potluck: return "Everyone brings a dish to share"
        case .buffet: return "A serve-yourself spread"
        case .dinnerParty: return "A sit-down meal at the table"
        case .mealTrain: return "Meals for someone who needs support"
        case .holiday: return "Thanksgiving, Christmas and more"
        case .brunch: return "A late-morning get-together"
        case .celebration: return "Birthdays, showers and graduations"
        case .other: return "Any other get-together"
        }
    }

    var symbol: String {
        switch self {
        case .backyardBBQ: return "flame.fill"
        case .potluck: return "frying.pan.fill"
        case .buffet: return "fork.knife"
        case .dinnerParty: return "wineglass.fill"
        case .mealTrain: return "heart.fill"
        case .holiday: return "gift.fill"
        case .brunch: return "cup.and.saucer.fill"
        case .celebration: return "party.popper.fill"
        case .other: return "sparkles"
        }
    }

    /// A type added later that this version doesn't know shows as
    /// Other instead of failing to load the event.
    init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        self = KinEventType(rawValue: raw) ?? .other
    }
}

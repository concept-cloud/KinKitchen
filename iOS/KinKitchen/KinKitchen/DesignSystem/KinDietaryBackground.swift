//
//  KinDietaryBackground.swift
//  KinKitchen
//
//  Created by Greg Hudler on 10/14/26.
//

import Foundation

/// The photo behind the Dietary Profile header. Each has a light and a
/// dark version in the asset catalog, so it follows the app's mode.
nonisolated enum KinDietaryBackground: String, CaseIterable, Identifiable {

    case sunnyKitchen
    case eveningAmbience
    case modernMarble
    case rusticTable
    case farmhouse
    case herbGarden
    case autumnHarvest

    var id: String { rawValue }

    static let storageKey = "kinDietaryBackground"
    static let `default`: KinDietaryBackground = .sunnyKitchen

    /// The saved choice, falling back to the default for anything
    /// unknown (e.g. a background that was later removed).
    static func saved(_ rawValue: String) -> KinDietaryBackground {
        KinDietaryBackground(rawValue: rawValue) ?? .default
    }

    var title: String {
        switch self {
        case .sunnyKitchen: return "Sunny Kitchen"
        case .eveningAmbience: return "Evening Ambience"
        case .modernMarble: return "Modern Marble"
        case .rusticTable: return "Rustic Table"
        case .farmhouse: return "Farmhouse"
        case .herbGarden: return "Herb Garden"
        case .autumnHarvest: return "Autumn Harvest"
        }
    }

    var subtitle: String {
        switch self {
        case .sunnyKitchen: return "Bright and welcoming"
        case .eveningAmbience: return "Warm and cozy"
        case .modernMarble: return "Clean and fresh"
        case .rusticTable: return "Natural and warm"
        case .farmhouse: return "Classic and cozy"
        case .herbGarden: return "Simple and elegant"
        case .autumnHarvest: return "Seasonal and festive"
        }
    }

    /// Asset catalog name, e.g. "DietaryBgSunnyKitchen".
    var imageName: String {
        "DietaryBg" + rawValue.prefix(1).uppercased() + rawValue.dropFirst()
    }
}

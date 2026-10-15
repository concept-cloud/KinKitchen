//
//  KinAppearance.swift
//  KinKitchen
//
//  Created by Greg Hudler on 10/14/26.
//

import SwiftUI

/// Light, Dark, or follow the iPhone's setting. Saved under
/// "kinAppearanceMode" as "light", "dark" or "system".
nonisolated enum KinAppearance: String, CaseIterable, Identifiable {

    case light
    case dark
    case system

    var id: String { rawValue }

    static let storageKey = "kinAppearanceMode"

    /// Unknown values fall back to Light, the app's original look.
    static func saved(_ rawValue: String) -> KinAppearance {
        KinAppearance(rawValue: rawValue) ?? .light
    }

    var title: String {
        switch self {
        case .light: return "Light"
        case .dark: return "Dark"
        case .system: return "System"
        }
    }

    /// nil lets the iPhone decide.
    var colorScheme: ColorScheme? {
        switch self {
        case .light: return .light
        case .dark: return .dark
        case .system: return nil
        }
    }
}


// MARK: - Keep Screen On

/// Stops the screen dimming while a recipe is open, so it stays
/// readable with messy hands. Counts open recipe screens so moving
/// from one to another doesn't briefly switch it off.
@MainActor
enum KinScreenAwake {

    static let storageKey = "kinKeepScreenOn"

    private static var openCount = 0

    static func opened() {
        openCount += 1
        update()
    }

    static func closed() {
        openCount = max(0, openCount - 1)
        update()
    }

    static func update() {
        let isOn =
            UserDefaults.standard.object(forKey: storageKey) as? Bool ?? true
        UIApplication.shared.isIdleTimerDisabled = isOn && openCount > 0
    }
}

extension View {

    /// Keeps the screen on while this view is showing, if the user has
    /// Keep Screen On turned on in Settings.
    func kinKeepsScreenAwake() -> some View {
        onAppear { KinScreenAwake.opened() }
            .onDisappear { KinScreenAwake.closed() }
    }
}

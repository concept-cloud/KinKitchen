//
//  KinHomeTheme.swift
//  KinKitchen
//
//  Created by Greg Hudler on 10/14/26.
//

import SwiftUI

/// Home's background look. Golden Kitchen is the default; with
/// Seasonal on, Home follows the time of year. Only the page wash and
/// small accents change: the logo, brand colors, cards and layout stay
/// the same in every theme.
nonisolated enum KinHomeTheme: String, CaseIterable, Identifiable {

    case goldenKitchen
    case spring
    case summer
    case autumn
    case winter

    var id: String { rawValue }

    /// The user's choice, saved under `storageKey`.
    enum Choice: String, CaseIterable, Identifiable {
        case goldenKitchen
        case seasonal

        var id: String { rawValue }

        var title: String {
            switch self {
            case .goldenKitchen: return "Golden Kitchen"
            case .seasonal: return "Seasonal"
            }
        }
    }

    static let storageKey = "kinHomeTheme"

    /// The theme to show for a saved choice on a given day.
    static func current(
        choice: Choice,
        on date: Date = .now,
        calendar: Calendar = .current
    ) -> KinHomeTheme {
        switch choice {
        case .goldenKitchen:
            return .goldenKitchen
        case .seasonal:
            return season(of: date, calendar: calendar)
        }
    }

    /// Meteorological seasons (northern hemisphere): spring Mar–May,
    /// summer Jun–Aug, autumn Sep–Nov, winter Dec–Feb.
    static func season(
        of date: Date,
        calendar: Calendar = .current
    ) -> KinHomeTheme {
        switch calendar.component(.month, from: date) {
        case 3...5: return .spring
        case 6...8: return .summer
        case 9...11: return .autumn
        default: return .winter
        }
    }

    var title: String {
        switch self {
        case .goldenKitchen: return "Golden Kitchen"
        case .spring: return "Spring"
        case .summer: return "Summer"
        case .autumn: return "Autumn"
        case .winter: return "Winter"
        }
    }

    /// Small decorative symbol used beside Home's section titles.
    var accentSymbol: String {
        switch self {
        case .goldenKitchen: return "sparkles"
        case .spring: return "camera.macro"
        case .summer: return "sun.max.fill"
        case .autumn: return "leaf.fill"
        case .winter: return "snowflake"
        }
    }
}


// MARK: - Colors

extension KinHomeTheme {

    /// Accent for the small seasonal touches.
    var accent: Color {
        switch self {
        case .goldenKitchen: return KinColors.accent
        case .spring: return Color(red: 0.91, green: 0.45, blue: 0.62)
        case .summer: return Color(red: 0.98, green: 0.62, blue: 0.20)
        case .autumn: return Color(red: 0.80, green: 0.38, blue: 0.13)
        case .winter: return Color(red: 0.36, green: 0.60, blue: 0.84)
        }
    }

    /// Two soft tints for the page wash below the hero.
    private var tints: (Color, Color) {
        switch self {
        case .goldenKitchen:
            return (KinColors.accent, Color(red: 0.95, green: 0.70, blue: 0.35))
        case .spring:
            return (Color(red: 0.95, green: 0.62, blue: 0.75), Color(red: 0.55, green: 0.80, blue: 0.50))
        case .summer:
            return (Color(red: 1.00, green: 0.80, blue: 0.30), Color(red: 1.00, green: 0.55, blue: 0.45))
        case .autumn:
            return (Color(red: 0.93, green: 0.55, blue: 0.20), Color(red: 0.70, green: 0.30, blue: 0.15))
        case .winter:
            return (Color(red: 0.60, green: 0.78, blue: 0.95), Color(red: 0.35, green: 0.55, blue: 0.45))
        }
    }

    /// Starts as the plain page color (so the hero's fade still meets
    /// it cleanly), then picks up the season's tints further down.
    /// Light enough that text and cards keep their contrast; fainter
    /// still in dark mode.
    func pageGradient(isDark: Bool) -> LinearGradient {
        let strength = isDark ? 0.10 : 0.22
        let (first, second) = tints

        return LinearGradient(
            stops: [
                .init(color: KinColors.background, location: 0),
                .init(color: KinColors.background, location: 0.25),
                .init(color: first.opacity(strength), location: 0.6),
                .init(color: second.opacity(strength * 0.8), location: 1)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}

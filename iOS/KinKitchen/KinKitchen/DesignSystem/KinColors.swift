//
//  KinColors.swift
//  KinKitchen
//
//  Created by Greg Hudler on 8/26/26.
//

import SwiftUI

enum KinColors {
    
    // MARK: - Base
    
    static let background = Color("Background")
    static let surface = Color("Surface")
    
    // MARK: - Text
    
    static let primaryText = Color("PrimaryText")
    static let secondaryText = Color("SecondaryText")
    
    // MARK: - Brand
    
    static let primary = Color("Primary")
    static let secondary = Color("Secondary")
    static let accent = Color("Accent")
    
    // MARK: - Status
    
    static let error = Color("Error")
    static let warning = Color("Warning")
    static let success = Color("Success")

    // MARK: - Pages

    /// Recipe pages (cookbook reading and Recipe Detail): a warm,
    /// slightly creamy page in light mode; the card color in dark mode.
    static let paper =
        Color(
            UIColor { traits in
                traits.userInterfaceStyle == .dark
                    ? UIColor(KinColors.surface)
                    : UIColor(red: 1.0, green: 0.985, blue: 0.95, alpha: 1)
            }
        )

    /// A page that holds cards (Recipe Detail): the same cream in
    /// light mode, but the page color in dark mode so cards (which use
    /// `surface`) still stand out.
    static let cardPage =
        Color(
            UIColor { traits in
                traits.userInterfaceStyle == .dark
                    ? UIColor(KinColors.background)
                    : UIColor(red: 1.0, green: 0.985, blue: 0.95, alpha: 1)
            }
        )
}

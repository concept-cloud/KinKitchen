//
//  KinElevation.swift
//  KinKitchen
//
//  Created by Greg Hudler on 10/14/26.
//

import SwiftUI

/// The app's shadows, so every card, floating control and photo
/// caption is lifted the same way.
extension View {

    /// Cards resting on the page: tiles, recipe and gathering cards,
    /// cookbook covers.
    func kinCardShadow() -> some View {
        shadow(color: .black.opacity(0.06), radius: 6, y: 2)
    }

    /// Controls floating over content: page bars, buttons over photos.
    func kinFloatingShadow() -> some View {
        shadow(color: .black.opacity(0.12), radius: 8, y: 2)
    }

    /// Paper sheets that overlap a photo above them.
    func kinSheetShadow() -> some View {
        shadow(color: .black.opacity(0.08), radius: 10, y: -2)
    }

    /// White text written over a photo.
    func kinTextOnPhoto() -> some View {
        shadow(color: .black.opacity(0.5), radius: 4, y: 1)
    }
}


/// Cards and tiles that open something: a gentle press-in so taps feel
/// answered.
struct KinPressableStyle: ButtonStyle {

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .opacity(configuration.isPressed ? 0.9 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == KinPressableStyle {
    static var kinPressable: KinPressableStyle { KinPressableStyle() }
}

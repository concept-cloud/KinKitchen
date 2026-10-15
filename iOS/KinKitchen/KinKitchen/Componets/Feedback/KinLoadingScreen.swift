//
//  KinLoadingScreen.swift
//  KinKitchen
//
//  Created by Greg Hudler on 10/14/26.
//

import SwiftUI

/// Full-screen loading while the app checks the session and profile.
/// Matches the launch screen (same logo, size and spot on the page
/// color), so opening the app is one smooth step instead of a flash
/// to a spinner.
struct KinLoadingScreen: View {

    @Environment(\.accessibilityReduceMotion)
    private var reduceMotion

    @State private var isBreathing = false
    @State private var showsProgress = false

    var body: some View {

        ZStack {

            KinColors.background
                .ignoresSafeArea()

            // LaunchLogo is the launch screen's image: 260 × 173 pt,
            // centered.
            Image("LaunchLogo")
                .renderingMode(.original)
                .resizable()
                .interpolation(.high)
                .frame(width: 260, height: 173)
                .scaleEffect(isBreathing ? 1.03 : 1)
                .accessibilityLabel("Kin Kitchen")

            // Only shows if loading takes a moment, so quick launches
            // stay clean.
            KinUtensilOrbit(isSpinning: !reduceMotion)
                .opacity(showsProgress ? 1 : 0)
                .accessibilityLabel("Loading")
        }
        .task {
            if !reduceMotion {
                withAnimation(
                    .easeInOut(duration: 1.4)
                        .repeatForever(autoreverses: true)
                ) {
                    isBreathing = true
                }
            }

            try? await Task.sleep(for: .seconds(0.8))

            withAnimation(.easeIn(duration: 0.3)) {
                showsProgress = true
            }
        }
    }
}

#Preview {
    KinLoadingScreen()
}


// MARK: - Utensil Orbit

/// The loading spinner: forks and knives circling the logo, brightest
/// at the front with a fading tail, like a spinner wheel.
struct KinUtensilOrbit: View {

    var isSpinning = true
    var count = 10
    /// Clears the corners of the 260 × 173 logo.
    var radius: CGFloat = 168
    var iconSize: CGFloat = 24

    @State private var angle: Angle = .zero

    var body: some View {

        ZStack {
            ForEach(0..<count, id: \.self) { index in

                let position =
                    Angle.degrees(Double(index) / Double(count) * 360)

                Image(systemName: KinIcons.recipes)
                    .font(.system(size: iconSize, weight: .semibold))
                    .foregroundStyle(KinColors.primary)
                    // Point along the circle, like they're marching
                    // around it.
                    .rotationEffect(position + .degrees(90))
                    .opacity(KinUtensilOrbit.opacity(index: index, count: count))
                    .offset(
                        x: radius * cos(position.radians),
                        y: radius * sin(position.radians)
                    )
            }
        }
        .frame(width: radius * 2 + iconSize * 2, height: radius * 2 + iconSize * 2)
        .rotationEffect(angle)
        .onAppear {
            guard isSpinning else {
                return
            }
            withAnimation(
                .linear(duration: 2.4)
                    .repeatForever(autoreverses: false)
            ) {
                angle = .degrees(360)
            }
        }
        .accessibilityElement()
    }

    /// The leading utensil is solid; the ones behind it fade out.
    nonisolated static func opacity(
        index: Int,
        count: Int
    ) -> Double {
        guard count > 1 else {
            return 1
        }
        return 0.15 + 0.85 * Double(index) / Double(count - 1)
    }
}

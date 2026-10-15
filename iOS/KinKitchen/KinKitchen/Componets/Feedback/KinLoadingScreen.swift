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
            ProgressView()
                .tint(KinColors.primary)
                .opacity(showsProgress ? 1 : 0)
                .offset(y: 140)
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

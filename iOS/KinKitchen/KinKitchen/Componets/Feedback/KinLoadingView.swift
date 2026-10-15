//
//  KinLoadingView.swift
//  KinKitchen
//
//  Created by Greg Hudler on 8/26/26.
//

import SwiftUI

/// The Kin Kitchen loader for anywhere a screen or section is loading:
/// the logo with forks and knives circling it, like the launch screen,
/// and a short message under it.
///
/// Small waits inside buttons or photos keep a plain spinner.
struct KinLoadingView: View {

    enum Size {
        /// Fills a screen.
        case regular
        /// For a section of a screen, like Home's Upcoming Events.
        case compact

        var logoWidth: CGFloat { self == .regular ? 150 : 96 }
        var orbitRadius: CGFloat { self == .regular ? 98 : 64 }
        var iconSize: CGFloat { self == .regular ? 17 : 12 }
    }

    var message: String = "Loading..."
    var size: Size = .regular

    @Environment(\.accessibilityReduceMotion)
    private var reduceMotion

    @State private var isBreathing = false

    var body: some View {

        VStack(
            spacing: size == .regular ? KinSpacing.large : KinSpacing.small
        ) {

            ZStack {
                KinUtensilOrbit(
                    isSpinning: !reduceMotion,
                    count: 10,
                    radius: size.orbitRadius,
                    iconSize: size.iconSize
                )

                // Same artwork as the launch screen (3:2).
                Image("LaunchLogo")
                    .renderingMode(.original)
                    .resizable()
                    .interpolation(.high)
                    .frame(
                        width: size.logoWidth,
                        height: size.logoWidth * 2 / 3
                    )
                    .scaleEffect(isBreathing ? 1.03 : 1)
            }
            .accessibilityHidden(true)

            Text(message)
                .font(
                    size == .regular
                        ? KinTypography.body
                        : KinTypography.footnote
                )
                .foregroundStyle(KinColors.secondaryText)
        }
        .frame(
            maxWidth: .infinity,
            maxHeight: size == .regular ? .infinity : nil
        )
        .padding(.vertical, size == .compact ? KinSpacing.small : 0)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(message)
        .onAppear {
            guard !reduceMotion else {
                return
            }
            withAnimation(
                .easeInOut(duration: 1.4)
                    .repeatForever(autoreverses: true)
            ) {
                isBreathing = true
            }
        }
    }
}

#Preview {

    VStack {
        KinLoadingView(message: "Loading recipe...")
        KinLoadingView(message: "Loading events...", size: .compact)
    }
    .background(KinColors.background)
}

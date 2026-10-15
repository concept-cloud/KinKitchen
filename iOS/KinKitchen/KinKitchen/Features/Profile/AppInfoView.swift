//
//  AppInfoView.swift
//  KinKitchen
//
//  Created by Greg Hudler on 10/14/26.
//

import SwiftUI

/// Which build of Kin Kitchen this is. Kin Kitchen hasn't been released
/// yet, so every build is a pre-release of version 1.
struct AppInfoView: View {

    private let info = AppBuildInfo()

    var body: some View {

        ScrollView {

            VStack(spacing: KinSpacing.xLarge) {

                KinLogo(height: 130)
                    .padding(.top, KinSpacing.large)

                KinCard {
                    VStack(spacing: KinSpacing.medium) {
                        row("Version", info.version)
                        Divider()
                        row("Build", info.build)
                        Divider()
                        row("Release", info.releaseStatus)
                    }
                }

                Text("Fonts: Arvo and Lora (SIL Open Font License)")
                    .font(KinTypography.caption)
                    .foregroundStyle(KinColors.secondaryText)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, KinSpacing.large)
            .padding(.bottom, KinSpacing.xxLarge)
        }
        .background(KinColors.background)
        .navigationTitle("App Info")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func row(
        _ title: String,
        _ value: String
    ) -> some View {
        HStack {
            Text(title)
                .font(KinTypography.body)
                .foregroundStyle(KinColors.secondaryText)

            Spacer()

            Text(value)
                .font(KinTypography.headline)
                .foregroundStyle(KinColors.primaryText)
                .textSelection(.enabled)
        }
        .accessibilityElement(children: .combine)
    }
}


// MARK: - Build Info

/// Version details read from the app bundle, so they update with each
/// build without touching this code.
nonisolated struct AppBuildInfo {

    let version: String
    let build: String

    init(bundle: Bundle = .main) {
        version =
            bundle.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        build =
            bundle.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }

    init(version: String, build: String) {
        self.version = version
        self.build = build
    }

    /// Pre-release until version 1.0 ships; Development for debug
    /// builds run from Xcode.
    var releaseStatus: String {
        #if DEBUG
        return "Pre-release (Development)"
        #else
        return "Pre-release"
        #endif
    }
}


#Preview {
    NavigationStack {
        AppInfoView()
    }
}

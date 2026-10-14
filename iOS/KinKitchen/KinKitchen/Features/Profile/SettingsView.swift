//
//  SettingsView.swift
//  KinKitchen
//
//  Created by Greg Hudler on 8/30/26.
//

import SwiftUI

struct SettingsView: View {

    // MARK: - Appearance

    @AppStorage("kinAppearanceMode")
    private var appearanceMode = "light"

    @AppStorage(KinHomeTheme.storageKey)
    private var homeThemeChoice = KinHomeTheme.Choice.goldenKitchen.rawValue

    var body: some View {

        ScrollView {

            VStack(
                alignment: .leading,
                spacing: KinSpacing.xLarge
            ) {

                // MARK: - Appearance

                VStack(
                    alignment: .leading,
                    spacing: KinSpacing.medium
                ) {

                    Text("Appearance")
                        .font(KinTypography.title)
                        .foregroundStyle(
                            KinColors.primaryText
                        )

                    Text(
                        "Choose how Kin Kitchen appears on this device."
                    )
                    .font(KinTypography.caption)
                    .foregroundStyle(
                        KinColors.secondaryText
                    )

                    Picker(
                        "Appearance",
                        selection: $appearanceMode
                    ) {

                        Label(
                            "Light",
                            systemImage: "sun.max"
                        )
                        .tag("light")

                        Label(
                            "Dark",
                            systemImage: "moon"
                        )
                        .tag("dark")
                    }
                    .pickerStyle(.segmented)

                    // MARK: - Home Theme

                    Text("Home Theme")
                        .font(KinTypography.headline)
                        .foregroundStyle(KinColors.primaryText)
                        .padding(.top, KinSpacing.small)

                    Text(
                        homeThemeChoice == KinHomeTheme.Choice.seasonal.rawValue
                            ? "Home changes with the seasons. Right now: \(KinHomeTheme.season(of: .now).title)."
                            : "The warm Golden Kitchen look, all year."
                    )
                    .font(KinTypography.caption)
                    .foregroundStyle(KinColors.secondaryText)

                    Picker(
                        "Home Theme",
                        selection: $homeThemeChoice
                    ) {
                        ForEach(KinHomeTheme.Choice.allCases) { choice in
                            Text(choice.title).tag(choice.rawValue)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                .padding(KinSpacing.large)
                .frame(
                    maxWidth: .infinity,
                    alignment: .leading
                )
                .background(KinColors.surface)
                .clipShape(
                    RoundedRectangle(
                        cornerRadius: KinRadius.medium
                    )
                )

                Spacer()
            }
            .padding(KinSpacing.xLarge)
        }
        .background(KinColors.background)
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .preferredColorScheme(
            appearanceMode == "dark"
                ? .dark
                : .light
        )
    }
}

#Preview {

    NavigationStack {
        SettingsView()
    }
}

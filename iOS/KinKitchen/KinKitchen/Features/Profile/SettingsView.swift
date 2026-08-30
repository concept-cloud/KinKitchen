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

//
//  SettingsView.swift
//  KinKitchen
//
//  Created by Greg Hudler on 8/30/26.
//

import SwiftUI

struct SettingsView: View {

    // MARK: - Saved Settings

    @AppStorage(KinAppearance.storageKey)
    private var appearanceMode = KinAppearance.light.rawValue

    @AppStorage(KinHomeTheme.storageKey)
    private var homeThemeChoice = KinHomeTheme.Choice.goldenKitchen.rawValue

    @AppStorage(KinDietaryBackground.storageKey)
    private var dietaryBackground = KinDietaryBackground.default.rawValue

    @AppStorage(KinScreenAwake.storageKey)
    private var keepScreenOn = true

    @State private var isChoosingBackground = false

    private let buildInfo = AppBuildInfo()

    var body: some View {

        ScrollView {

            VStack(
                alignment: .leading,
                spacing: KinSpacing.xLarge
            ) {

                // MARK: - Appearance

                settingsSection(
                    "Appearance",
                    systemImage: "circle.lefthalf.filled"
                ) {

                    VStack(
                        alignment: .leading,
                        spacing: KinSpacing.medium
                    ) {

                        Text("Choose how Kin Kitchen looks on this device.")
                            .font(KinTypography.footnote)
                            .foregroundStyle(KinColors.secondaryText)

                        HStack(
                            spacing: KinSpacing.medium
                        ) {
                            ForEach(KinAppearance.allCases) { mode in
                                appearanceTile(mode)
                            }
                        }
                    }
                    .padding(KinSpacing.large)
                }

                // MARK: - Themes

                settingsSection(
                    "Themes",
                    systemImage: "paintpalette.fill"
                ) {

                    VStack(
                        alignment: .leading,
                        spacing: KinSpacing.medium
                    ) {

                        Text("Home Theme")
                            .font(KinTypography.headline)
                            .foregroundStyle(KinColors.primaryText)

                        Text(homeThemeDescription)
                            .font(KinTypography.footnote)
                            .foregroundStyle(KinColors.secondaryText)

                        HStack(
                            spacing: KinSpacing.medium
                        ) {
                            ForEach(KinHomeTheme.Choice.allCases) { choice in
                                homeThemeTile(choice)
                            }
                        }
                    }
                    .padding(KinSpacing.large)

                    Divider()
                        .padding(.leading, KinSpacing.large)

                    Button {
                        isChoosingBackground = true
                    } label: {
                        dietaryBackgroundRow
                    }
                    .buttonStyle(.kinPressable)
                }

                // MARK: - Cooking

                settingsSection(
                    "Cooking",
                    systemImage: KinIcons.recipes
                ) {

                    Toggle(isOn: $keepScreenOn) {

                        rowLabel(
                            title: "Keep Screen On",
                            subtitle: "Your screen won't dim while a recipe is open.",
                            systemImage: "sun.max.fill",
                            tint: KinColors.warning
                        )
                    }
                    .tint(KinColors.success)
                    .padding(KinSpacing.large)
                }

                // MARK: - About

                VStack(
                    spacing: KinSpacing.xSmall
                ) {

                    KinLogo(height: 44)
                        .opacity(0.8)

                    Text("Kin Kitchen \(buildInfo.version) (\(buildInfo.build))")
                        .font(KinTypography.caption)
                        .foregroundStyle(KinColors.secondaryText)

                    Text("Made for families who cook together.")
                        .font(KinTypography.caption)
                        .foregroundStyle(KinColors.secondaryText)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, KinSpacing.medium)
                .accessibilityElement(children: .combine)
            }
            .padding(.horizontal, KinSpacing.large)
            .padding(.vertical, KinSpacing.xLarge)
        }
        .background(KinColors.background)
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .sensoryFeedback(.selection, trigger: appearanceMode)
        .sensoryFeedback(.selection, trigger: homeThemeChoice)
        .onChange(of: keepScreenOn) {
            KinScreenAwake.update()
        }
        .sheet(isPresented: $isChoosingBackground) {
            DietaryBackgroundPicker()
                .presentationDetents([.medium, .large])
        }
    }

    private var homeThemeDescription: String {
        homeThemeChoice == KinHomeTheme.Choice.seasonal.rawValue
            ? "Home changes with the seasons. Right now: \(KinHomeTheme.season(of: .now).title)."
            : "The warm Golden Kitchen look, all year."
    }


    // MARK: - Section

    /// Small caps heading above a card of settings.
    private func settingsSection<Content: View>(
        _ title: String,
        systemImage: String,
        @ViewBuilder content: () -> Content
    ) -> some View {

        VStack(
            alignment: .leading,
            spacing: KinSpacing.small
        ) {

            Label(
                title.uppercased(),
                systemImage: systemImage
            )
            .font(KinTypography.caption.weight(.semibold))
            .tracking(1.2)
            .foregroundStyle(KinColors.secondaryText)
            .padding(.leading, KinSpacing.xSmall)
            .accessibilityAddTraits(.isHeader)

            VStack(
                alignment: .leading,
                spacing: 0
            ) {
                content()
            }
            .frame(
                maxWidth: .infinity,
                alignment: .leading
            )
            .background(
                KinColors.surface,
                in: RoundedRectangle(
                    cornerRadius: KinRadius.large
                )
            )
            .kinCardShadow()
        }
    }

    /// Icon tile, title and a line of help text.
    private func rowLabel(
        title: String,
        subtitle: String,
        systemImage: String,
        tint: Color
    ) -> some View {

        HStack(
            spacing: KinSpacing.medium
        ) {

            Image(systemName: systemImage)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: 36, height: 36)
                .background(
                    tint.opacity(0.15),
                    in: RoundedRectangle(cornerRadius: KinRadius.small)
                )
                .accessibilityHidden(true)

            VStack(
                alignment: .leading,
                spacing: KinSpacing.xxSmall
            ) {

                Text(title)
                    .font(KinTypography.headline)
                    .foregroundStyle(KinColors.primaryText)

                Text(subtitle)
                    .font(KinTypography.footnote)
                    .foregroundStyle(KinColors.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }


    // MARK: - Appearance Tiles

    private func appearanceTile(
        _ mode: KinAppearance
    ) -> some View {

        let isSelected =
            KinAppearance.saved(appearanceMode) == mode

        return Button {
            appearanceMode = mode.rawValue
        } label: {

            VStack(
                spacing: KinSpacing.small
            ) {

                AppearancePreview(mode: mode)
                    .frame(height: 76)
                    .clipShape(
                        RoundedRectangle(cornerRadius: KinRadius.medium)
                    )
                    .overlay {
                        RoundedRectangle(cornerRadius: KinRadius.medium)
                            .strokeBorder(
                                isSelected
                                    ? KinColors.primary
                                    : KinColors.secondaryText.opacity(0.3),
                                lineWidth: isSelected ? 3 : 1
                            )
                    }

                Text(mode.title)
                    .font(KinTypography.subheadline)
                    .foregroundStyle(
                        isSelected
                            ? KinColors.primary
                            : KinColors.primaryText
                    )
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.kinPressable)
        .accessibilityLabel(mode.title)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }


    // MARK: - Home Theme Tiles

    private func homeThemeTile(
        _ choice: KinHomeTheme.Choice
    ) -> some View {

        let isSelected = homeThemeChoice == choice.rawValue

        // Seasonal shows the season it would use today.
        let theme = KinHomeTheme.current(choice: choice)

        return Button {
            homeThemeChoice = choice.rawValue
        } label: {

            HStack(
                spacing: KinSpacing.small
            ) {

                Image(systemName: theme.accentSymbol)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 32, height: 32)
                    .background(theme.previewGradient, in: Circle())

                Text(choice.title)
                    .font(KinTypography.subheadline)
                    .foregroundStyle(KinColors.primaryText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                Spacer(minLength: 0)
            }
            .padding(KinSpacing.small)
            .frame(maxWidth: .infinity)
            .background(
                isSelected ? KinColors.primary.opacity(0.1) : .clear,
                in: RoundedRectangle(cornerRadius: KinRadius.medium)
            )
            .overlay {
                RoundedRectangle(cornerRadius: KinRadius.medium)
                    .strokeBorder(
                        isSelected
                            ? KinColors.primary
                            : KinColors.secondaryText.opacity(0.3),
                        lineWidth: isSelected ? 2 : 1
                    )
            }
        }
        .buttonStyle(.kinPressable)
        .accessibilityLabel(choice.title)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }


    // MARK: - Dietary Background

    private var dietaryBackgroundRow: some View {

        let background = KinDietaryBackground.saved(dietaryBackground)

        return HStack(
            spacing: KinSpacing.medium
        ) {

            VStack(
                alignment: .leading,
                spacing: KinSpacing.xxSmall
            ) {

                Text("Dietary Profile Background")
                    .font(KinTypography.headline)
                    .foregroundStyle(KinColors.primaryText)

                Text(background.title)
                    .font(KinTypography.footnote)
                    .foregroundStyle(KinColors.secondaryText)
            }

            Spacer()

            Color.clear
                .frame(width: 44, height: 56)
                .overlay {
                    Image(background.imageName)
                        .resizable()
                        .scaledToFill()
                }
                .clipShape(
                    RoundedRectangle(cornerRadius: KinRadius.small)
                )
                .accessibilityHidden(true)

            Image(systemName: KinIcons.forward)
                .font(.caption)
                .foregroundStyle(KinColors.secondaryText)
        }
        .padding(KinSpacing.large)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityHint("Opens the background choices")
    }
}


// MARK: - Appearance Preview

/// A tiny phone screen in light or dark colors; System shows both.
private struct AppearancePreview: View {

    let mode: KinAppearance

    private static let lightPage = Color(red: 0.97, green: 0.95, blue: 0.91)
    private static let lightCard = Color.white
    private static let darkPage = Color(red: 0.07, green: 0.09, blue: 0.15)
    private static let darkCard = Color(red: 0.12, green: 0.16, blue: 0.23)

    var body: some View {

        switch mode {

        case .light:
            screen(page: Self.lightPage, card: Self.lightCard)

        case .dark:
            screen(page: Self.darkPage, card: Self.darkCard)

        case .system:
            HStack(spacing: 0) {
                screen(page: Self.lightPage, card: Self.lightCard)
                screen(page: Self.darkPage, card: Self.darkCard)
            }
        }
    }

    private func screen(
        page: Color,
        card: Color
    ) -> some View {

        VStack(
            alignment: .leading,
            spacing: 5
        ) {

            Capsule()
                .fill(KinColors.primary)
                .frame(width: 22, height: 5)

            RoundedRectangle(cornerRadius: 3)
                .fill(card)
                .frame(height: 14)

            RoundedRectangle(cornerRadius: 3)
                .fill(card)
                .frame(height: 14)
        }
        .padding(8)
        .frame(
            maxWidth: .infinity,
            maxHeight: .infinity,
            alignment: .top
        )
        .background(page)
    }
}

#Preview {

    NavigationStack {
        SettingsView()
    }
}

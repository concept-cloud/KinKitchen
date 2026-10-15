//
//  DietaryProfileComponents.swift
//  KinKitchen
//
//  Created by Greg Hudler on 10/14/26.
//

import SwiftUI

// MARK: - Page

/// The Dietary Profile layout shared by viewing and editing: the user's
/// background photo with a headline across the top, cards tucked into
/// its fade, and a bar that turns from white-on-photo to page colors
/// once the photo scrolls away.
struct DietaryHeroPage<Content: View, Trailing: View>: View {

    let title: String
    let eyebrow: String
    let headline: String
    let message: String
    @ViewBuilder var content: Content
    @ViewBuilder var trailing: Trailing

    @State private var scrolledPastHero = false
    @State private var isChoosingBackground = false

    @AppStorage(KinDietaryBackground.storageKey)
    private var backgroundChoice = KinDietaryBackground.default.rawValue

    private static var heroHeight: CGFloat { 340 }

    var body: some View {

        ScrollView {

            VStack(
                spacing: 0
            ) {

                hero

                VStack(
                    spacing: KinSpacing.medium
                ) {
                    content
                }
                .padding(.horizontal, KinSpacing.large)
                .padding(.bottom, KinSpacing.xxLarge)
                // Cards tuck slightly up into the fading photo.
                .padding(.top, -KinSpacing.xLarge)
            }
        }
        .background(KinColors.background)
        .onScrollGeometryChange(
            for: Bool.self
        ) { geometry in
            geometry.contentOffset.y
                + geometry.contentInsets.top
                > Self.heroHeight - 120
        } action: { _, isPast in
            withAnimation(.easeInOut(duration: 0.2)) {
                scrolledPastHero = isPast
            }
        }
        .ignoresSafeArea(edges: .top)
        .toolbarBackgroundVisibility(
            .hidden,
            for: .navigationBar
        )
        .scrollEdgeEffectHidden(
            true,
            for: .top
        )
        .overlay(
            alignment: .top
        ) {

            // Behind the back button once the photo is gone, so cards
            // fade away instead of being sliced.
            LinearGradient(
                stops: [
                    .init(color: KinColors.background, location: 0),
                    .init(color: KinColors.background, location: 0.7),
                    .init(color: KinColors.background.opacity(0), location: 1)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 140)
            .ignoresSafeArea(edges: .top)
            .opacity(scrolledPastHero ? 1 : 0)
            .allowsHitTesting(false)
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {

            ToolbarItem(
                placement: .principal
            ) {

                Text(title)
                    .font(KinTypography.headline)
                    .foregroundStyle(
                        scrolledPastHero
                            ? KinColors.primaryText
                            : .white
                    )
                    .shadow(
                        color: .black.opacity(scrolledPastHero ? 0 : 0.5),
                        radius: 4,
                        y: 1
                    )
            }

            ToolbarItem(
                placement: .topBarTrailing
            ) {
                trailing
            }
        }
        .sheet(isPresented: $isChoosingBackground) {
            DietaryBackgroundPicker()
                .presentationDetents([.medium, .large])
        }
    }

    private var hero: some View {

        Color.clear
            .frame(height: Self.heroHeight)
            .frame(maxWidth: .infinity)
            .overlay {

                Image(KinDietaryBackground.saved(backgroundChoice).imageName)
                    .resizable()
                    .scaledToFill()
                    .accessibilityHidden(true)
            }
            .overlay {

                // Darkens the photo enough for white text in both modes.
                LinearGradient(
                    stops: [
                        .init(color: .black.opacity(0.55), location: 0),
                        .init(color: .black.opacity(0.35), location: 0.45),
                        .init(color: .black.opacity(0.5), location: 1)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
            .clipped()
            .mask {

                LinearGradient(
                    stops: [
                        .init(color: .black, location: 0.7),
                        .init(color: .clear, location: 1)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
            .overlay {

                VStack(
                    spacing: KinSpacing.small
                ) {

                    Label(
                        eyebrow,
                        systemImage: KinIcons.dietary
                    )
                    .font(KinTypography.caption.weight(.semibold))
                    .tracking(1.5)
                    .foregroundStyle(.white.opacity(0.9))

                    Text(headline)
                        .font(KinTypography.largeTitle)
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)

                    Text(message)
                        .font(KinTypography.callout)
                        .foregroundStyle(.white.opacity(0.92))
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 320)
                }
                .kinTextOnPhoto()
                .padding(.horizontal, KinSpacing.xLarge)
                .padding(.top, 60)
                .padding(.bottom, KinSpacing.xLarge)
                .accessibilityElement(children: .combine)
                .accessibilityAddTraits(.isHeader)
            }
            .overlay(
                alignment: .bottomTrailing
            ) {

                Button {
                    isChoosingBackground = true
                } label: {
                    Image(systemName: KinIcons.photo)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 36, height: 36)
                        .background(.black.opacity(0.35), in: Circle())
                }
                .buttonStyle(.kinPressable)
                .accessibilityLabel("Change background")
                // Sits above where the cards tuck into the fade.
                .padding(.trailing, KinSpacing.large)
                .padding(.bottom, KinSpacing.xLarge + KinSpacing.medium)
            }
            .animation(.easeInOut(duration: 0.25), value: backgroundChoice)
    }
}


// MARK: - Sections

/// The three parts of a dietary profile, with the icon and color each
/// uses on both the view and edit screens.
nonisolated enum DietarySection {

    case allergens
    case restrictions
    case preferences

    var title: String {
        switch self {
        case .allergens: return "Foods to Watch"
        case .restrictions: return "Dietary Restrictions"
        case .preferences: return "How You Like to Eat"
        }
    }

    var icon: String {
        switch self {
        case .allergens: return "heart.fill"
        case .restrictions: return "nosign"
        case .preferences: return KinIcons.dietary
        }
    }

    /// Which kind of `custom_dietary_items` row "Add your own" makes.
    var customKind: CustomDietaryItem.Kind {
        switch self {
        case .allergens: return .allergen
        case .restrictions: return .restriction
        case .preferences: return .preference
        }
    }

    var addPlaceholder: String {
        switch self {
        case .allergens: return "Add your own, e.g. Strawberry"
        case .restrictions: return "Add your own, e.g. No Pork"
        case .preferences: return "Add your own, e.g. Cilantro"
        }
    }

    var emptyMessage: String {
        switch self {
        case .allergens: return "No allergens selected."
        case .restrictions: return "No dietary restrictions selected."
        case .preferences: return "No dietary preferences selected."
        }
    }
}

extension DietarySection {

    var tint: Color {
        switch self {
        case .allergens: return KinColors.primary
        case .restrictions: return KinColors.secondaryText
        case .preferences: return KinColors.success
        }
    }
}


// MARK: - Card

/// Icon tile, title, optional count badge and a line of help text,
/// with the chips (or anything else) below.
struct DietaryCard<Content: View>: View {

    let section: DietarySection
    let subtitle: String
    var badge: String? = nil
    @ViewBuilder var content: Content

    var body: some View {

        VStack(
            alignment: .leading,
            spacing: KinSpacing.medium
        ) {

            HStack(
                alignment: .top,
                spacing: KinSpacing.medium
            ) {

                Image(systemName: section.icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(section.tint)
                    .frame(width: 44, height: 44)
                    .background(
                        section.tint.opacity(0.15),
                        in: RoundedRectangle(
                            cornerRadius: KinRadius.medium
                        )
                    )
                    .accessibilityHidden(true)

                VStack(
                    alignment: .leading,
                    spacing: KinSpacing.xSmall
                ) {

                    HStack(
                        alignment: .firstTextBaseline
                    ) {

                        Text(section.title)
                            .font(KinTypography.headline)
                            .foregroundStyle(KinColors.primaryText)
                            .accessibilityAddTraits(.isHeader)

                        Spacer(minLength: KinSpacing.small)

                        if let badge {

                            Text(badge)
                                .font(KinTypography.caption)
                                .foregroundStyle(section.tint)
                                .padding(.horizontal, KinSpacing.small)
                                .padding(.vertical, KinSpacing.xSmall)
                                .background(
                                    section.tint.opacity(0.15),
                                    in: Capsule()
                                )
                        }
                    }

                    Text(subtitle)
                        .font(KinTypography.footnote)
                        .foregroundStyle(KinColors.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            content
        }
        .padding(KinSpacing.large)
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


// MARK: - Chip

/// A dietary item in its section's color. Selected chips are tinted
/// (with a check while editing); unselected ones are outlined.
struct DietaryChip: View {

    let title: String
    let tint: Color
    var isSelected = true
    var showsCheck = false

    var body: some View {

        HStack(
            spacing: KinSpacing.xSmall
        ) {

            if showsCheck && isSelected {
                Image(systemName: KinIcons.check)
                    .font(.system(size: 12, weight: .bold))
            }

            Text(title)
                .font(KinTypography.subheadline)
        }
        .foregroundStyle(
            isSelected ? tint : KinColors.primaryText
        )
        .padding(.horizontal, KinSpacing.medium)
        .padding(.vertical, KinSpacing.small)
        .background(
            isSelected ? tint.opacity(0.14) : .clear,
            in: Capsule()
        )
        .overlay {
            Capsule()
                .strokeBorder(
                    isSelected
                        ? tint.opacity(0.5)
                        : KinColors.secondaryText.opacity(0.35),
                    lineWidth: 1
                )
        }
        .contentShape(Capsule())
    }
}

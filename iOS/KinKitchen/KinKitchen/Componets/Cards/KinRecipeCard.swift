//
//  KinRecipeCard.swift
//  KinKitchen
//
//  Created by Greg Hudler on 10/14/26.
//

import SwiftUI

/// A recipe as a card: the photo across the top (like a cookbook
/// page) with its category and time on it, the name below, and any
/// extra lines (sharing, dietary notes) under that.
///
/// Only the look; wrap it in a Button to open the recipe. Anything
/// placed over the top-right corner (like a Save button) sits on the
/// photo.
struct KinRecipeCard<Footer: View>: View {

    let name: String
    var category: String? = nil
    /// e.g. "45 min"; nil when unknown.
    var totalTime: String? = nil
    var photo: UIImage? = nil
    var placeholderIcon: String = KinIcons.recipes
    var photoHeight: CGFloat = 170
    @ViewBuilder var footer: Footer

    var body: some View {

        VStack(
            alignment: .leading,
            spacing: 0
        ) {

            photoArea

            VStack(
                alignment: .leading,
                spacing: KinSpacing.small
            ) {

                Text(name)
                    .font(KinTypography.title3)
                    .foregroundStyle(KinColors.primaryText)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                footer
            }
            .padding(KinSpacing.medium)
            .frame(
                maxWidth: .infinity,
                alignment: .leading
            )
        }
        .background(KinColors.surface)
        .clipShape(
            RoundedRectangle(cornerRadius: KinRadius.large)
        )
        .kinCardShadow()
        .contentShape(
            RoundedRectangle(cornerRadius: KinRadius.large)
        )
    }


    // MARK: - Photo

    private var photoArea: some View {

        // Color.clear takes the card's width; the photo fills it
        // without widening the list.
        Color.clear
            .frame(height: photoHeight)
            .frame(maxWidth: .infinity)
            .overlay {
                if let photo {
                    Image(uiImage: photo)
                        .resizable()
                        .scaledToFill()
                        .transition(.opacity)
                } else {
                    KinPhotoPlaceholder(
                        icon: placeholderIcon,
                        iconSize: 40
                    )
                }
            }
            .overlay(alignment: .bottom) {
                // Keeps the tags readable on bright photos.
                if photo != nil {
                    LinearGradient(
                        colors: [.clear, .black.opacity(0.45)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 70)
                }
            }
            .overlay(alignment: .bottomLeading) {
                tags
            }
            .clipped()
            .animation(.easeOut(duration: 0.2), value: photo != nil)
            .accessibilityHidden(true)
    }

    @ViewBuilder
    private var tags: some View {

        let category = KinRecipeCard.cleaned(category)
        let totalTime = KinRecipeCard.cleaned(totalTime)

        if category != nil || totalTime != nil {

            HStack(
                spacing: KinSpacing.xSmall
            ) {
                if let category {
                    tag(category, systemImage: nil)
                }
                if let totalTime {
                    tag(totalTime, systemImage: KinIcons.time)
                }
            }
            .padding(KinSpacing.medium)
        }
    }

    private func tag(
        _ text: String,
        systemImage: String?
    ) -> some View {

        HStack(
            spacing: KinSpacing.xSmall
        ) {
            if let systemImage {
                Image(systemName: systemImage)
            }
            Text(text)
                .lineLimit(1)
        }
        .font(KinTypography.caption.weight(.semibold))
        .foregroundStyle(.white)
        .padding(.horizontal, KinSpacing.small)
        .padding(.vertical, KinSpacing.xSmall)
        .background(.black.opacity(0.4), in: Capsule())
    }

    /// nil for empty text and the "—" used when there's no time.
    nonisolated static func cleaned(
        _ value: String?
    ) -> String? {
        guard
            let value = value?.trimmingCharacters(in: .whitespacesAndNewlines),
            !value.isEmpty,
            value != "—"
        else {
            return nil
        }
        return value
    }
}

extension KinRecipeCard where Footer == EmptyView {

    init(
        name: String,
        category: String? = nil,
        totalTime: String? = nil,
        photo: UIImage? = nil,
        placeholderIcon: String = KinIcons.recipes,
        photoHeight: CGFloat = 170
    ) {
        self.init(
            name: name,
            category: category,
            totalTime: totalTime,
            photo: photo,
            placeholderIcon: placeholderIcon,
            photoHeight: photoHeight
        ) {
            EmptyView()
        }
    }
}

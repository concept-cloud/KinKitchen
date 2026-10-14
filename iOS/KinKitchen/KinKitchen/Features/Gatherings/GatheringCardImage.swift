//
//  GatheringCardImage.swift
//  KinKitchen
//
//  Created by Greg Hudler on 10/13/26.
//

import SwiftUI
import Supabase

/// Gathering cover for cards, with a placeholder when there's no photo.
/// Shared by the Gatherings list and Home.
///
/// With a `size` it's a rounded square. Without one it fills whatever
/// space it's given (e.g. as a card background) and leaves clipping and
/// corners to the parent.
struct GatheringCardImage: View {

    let path: String?
    var size: CGFloat? = 82

    @State private var imageData: Data?
    @State private var isLoading = false


    var body: some View {

        if let size {

            cover
                .frame(
                    width: size,
                    height: size
                )
                .clipShape(
                    RoundedRectangle(
                        cornerRadius:
                            KinRadius.medium
                    )
                )

        } else {

            cover
        }
    }


    private var cover: some View {

        // Color.clear sizes to the space offered, so a large photo
        // never stretches its parent.
        Color.clear
            .overlay {

                if
                    let imageData,
                    let image =
                        UIImage(
                            data: imageData
                        )
                {

                    Image(
                        uiImage: image
                    )
                    .resizable()
                    .scaledToFill()

                } else {

                    ZStack {

                        LinearGradient(
                            colors: [
                                KinColors.accent.opacity(0.35),
                                KinColors.primary.opacity(0.25)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )

                        Image(
                            systemName:
                                "fork.knife"
                        )
                        .font(
                            .system(
                                size: (size ?? 84) * 0.32,
                                weight: .semibold
                            )
                        )
                        .foregroundStyle(
                            KinColors.primary.opacity(0.6)
                        )
                    }
                }
            }
            .clipped()
            .accessibilityHidden(true)
            .task(
                id: path
            ) {

                await loadImage()
            }
    }


    @MainActor
    private func loadImage() async {

        guard
            !isLoading,
            let path,
            !path.isEmpty
        else {
            return
        }

        isLoading = true

        defer {
            isLoading = false
        }

        do {

            imageData =
                try await StorageImageCache.shared.data(
                    bucket: "gathering-photos",
                    path: path
                )

        } catch {

            print(
                "GATHERING CARD IMAGE ERROR:",
                error.localizedDescription
            )
        }
    }
}



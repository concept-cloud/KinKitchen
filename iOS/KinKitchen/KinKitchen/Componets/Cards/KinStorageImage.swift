//
//  KinStorageImage.swift
//  KinKitchen
//
//  Created by Greg Hudler on 10/13/26.
//

import SwiftUI
import Supabase

/// A photo from a Supabase storage bucket that fills the space it's
/// given, with a warm placeholder while loading or when there's none.
struct KinStorageImage: View {

    let bucket: String
    let path: String?
    var placeholderIcon: String = KinIcons.recipes

    @State private var image: UIImage?

    var body: some View {

        // Color.clear sizes to the space offered, so a large photo
        // never stretches its parent.
        Color.clear
            .overlay {

                if let image {

                    Image(uiImage: image)
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

                        Image(systemName: placeholderIcon)
                            .font(
                                .system(
                                    size: 26,
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
            .task(id: path) {
                await load()
            }
    }


    @MainActor
    private func load() async {

        guard
            let path,
            !path.isEmpty
        else {
            image = nil
            return
        }

        if let cached =
            StorageImageCache.shared.cached(bucket: bucket, path: path) {
            image = UIImage(data: cached)
            return
        }

        do {

            let data =
                try await StorageImageCache.shared.data(
                    bucket: bucket,
                    path: path
                )

            image = UIImage(data: data)

        } catch {

            if !(error is CancellationError) {
                print(
                    "STORAGE IMAGE ERROR (\(bucket)):",
                    error.localizedDescription
                )
            }
        }
    }
}

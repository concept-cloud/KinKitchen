//
//  GatheringCardImage.swift
//  KinKitchen
//
//  Created by Greg Hudler on 10/13/26.
//

import SwiftUI
import Supabase

/// Square gathering cover for cards, with a placeholder when there's
/// no photo. Shared by the Gatherings list and Home.
struct GatheringCardImage: View {

    let path: String?
    var size: CGFloat = 82

    @State private var imageData: Data?
    @State private var isLoading = false


    var body: some View {

        ZStack {

            RoundedRectangle(
                cornerRadius:
                    KinRadius.medium
            )
            .fill(
                KinColors.background
            )

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
                .frame(
                    width: size,
                    height: size
                )
                .clipped()

            } else {

                Image(
                    systemName:
                        "fork.knife"
                )
                .font(
                    .system(
                        size: size * 0.32,
                        weight: .semibold
                    )
                )
                .foregroundStyle(
                    KinColors.secondaryText
                )
            }
        }
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
                try await SupabaseManager.client
                    .storage
                    .from(
                        "gathering-photos"
                    )
                    .download(
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



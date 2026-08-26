//
//  KinImageCard.swift
//  KinKitchen
//
//  Created by Greg Hudler on 8/26/26.
//

import SwiftUI

struct KinImageCard: View {
    let image: Image
    let title: String
    let subtitle: String?

    var body: some View {
        VStack(alignment: .leading, spacing: KinSpacing.medium) {
            image
                .resizable()
                .scaledToFill()
                .frame(height: 160)
                .clipped()
                .clipShape(
                    RoundedRectangle(cornerRadius: KinRadius.medium)
                )

            Text(title)
                .font(KinTypography.title3)
                .foregroundStyle(KinColors.primaryText)

            if let subtitle {
                Text(subtitle)
                    .font(KinTypography.subheadline)
                    .foregroundStyle(KinColors.secondaryText)
            }
        }
        .padding(KinSpacing.large)
        .background(KinColors.surface)
        .clipShape(
            RoundedRectangle(cornerRadius: KinRadius.large)
        )
    }
}

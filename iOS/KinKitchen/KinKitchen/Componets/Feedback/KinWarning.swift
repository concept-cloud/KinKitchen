//
//  KinWarning.swift
//  KinKitchen
//
//  Created by Greg Hudler on 8/26/26.
//

import SwiftUI

struct KinWarning: View {
    let title: String
    let message: String

    var body: some View {
        HStack(alignment: .top, spacing: KinSpacing.medium) {
            Image(systemName: KinIcons.warning)
                .foregroundStyle(KinColors.warning)

            VStack(alignment: .leading, spacing: KinSpacing.xSmall) {
                Text(title)
                    .font(KinTypography.headline)
                    .foregroundStyle(KinColors.primaryText)

                Text(message)
                    .font(KinTypography.body)
                    .foregroundStyle(KinColors.secondaryText)
            }

            Spacer()
        }
        .padding(KinSpacing.large)
        .background(KinColors.surface)
        .clipShape(
            RoundedRectangle(cornerRadius: KinRadius.large)
        )
    }
}

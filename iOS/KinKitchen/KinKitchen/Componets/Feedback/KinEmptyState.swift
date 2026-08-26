//
//  KinEmptyState.swift
//  KinKitchen
//
//  Created by Greg Hudler on 8/26/26.
//

import SwiftUI

struct KinEmptyState: View {
    let icon: String
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: KinSpacing.medium) {
            Image(systemName: icon)
                .font(.system(size: 42))
                .foregroundStyle(KinColors.secondaryText)

            Text(title)
                .font(KinTypography.title3)
                .foregroundStyle(KinColors.primaryText)

            Text(message)
                .font(KinTypography.body)
                .foregroundStyle(KinColors.secondaryText)
                .multilineTextAlignment(.center)
        }
        .padding(KinSpacing.xLarge)
    }
}

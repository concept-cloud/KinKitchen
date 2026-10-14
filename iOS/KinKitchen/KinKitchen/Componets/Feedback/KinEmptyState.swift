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
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: KinSpacing.medium) {
            Image(systemName: icon)
                .font(.system(size: 40))
                .foregroundStyle(KinColors.primary)
                .frame(width: 96, height: 96)
                .background(KinColors.primary.opacity(0.12))
                .clipShape(Circle())
                .accessibilityHidden(true)

            Text(title)
                .font(KinTypography.title3)
                .foregroundStyle(KinColors.primaryText)
                .multilineTextAlignment(.center)

            Text(message)
                .font(KinTypography.body)
                .foregroundStyle(KinColors.secondaryText)
                .multilineTextAlignment(.center)

            if let actionTitle, let action {
                Button(action: action) {
                    Text(actionTitle)
                        .font(KinTypography.headline)
                        .foregroundStyle(.white)
                        .padding(.horizontal, KinSpacing.large)
                        .padding(.vertical, KinSpacing.medium)
                        .background(KinColors.primary)
                        .clipShape(Capsule())
                }
                .buttonStyle(.kinPressable)
                .padding(.top, KinSpacing.small)
            }
        }
        .padding(KinSpacing.xLarge)
    }
}

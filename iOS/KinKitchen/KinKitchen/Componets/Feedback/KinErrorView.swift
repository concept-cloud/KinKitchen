//
//  KinErrorView.swift
//  KinKitchen
//
//  Created by Greg Hudler on 8/26/26.
//

import SwiftUI

struct KinErrorView: View {
    let message: String
    var retryAction: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: KinSpacing.medium) {
            Image(systemName: KinIcons.error)
                .font(.system(size: 36))
                .foregroundStyle(KinColors.error)

            Text("Something Went Wrong")
                .font(KinTypography.title3)
                .foregroundStyle(KinColors.primaryText)

            Text(message)
                .font(KinTypography.body)
                .foregroundStyle(KinColors.secondaryText)
                .multilineTextAlignment(.center)

            if let retryAction {
                KinPrimaryButton(title: "Retry", action: retryAction)
            }
        }
        .padding(KinSpacing.xLarge)
    }
}

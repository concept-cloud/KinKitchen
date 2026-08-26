//
//  KinLoadingView.swift
//  KinKitchen
//
//  Created by Greg Hudler on 8/26/26.
//

import SwiftUI

struct KinLoadingView: View {
    var message: String = "Loading..."

    var body: some View {
        VStack(spacing: KinSpacing.medium) {
            ProgressView()

            Text(message)
                .font(KinTypography.body)
                .foregroundStyle(KinColors.secondaryText)
        }
        .padding(KinSpacing.large)
    }
}

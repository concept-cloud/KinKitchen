//
//  GatheringsView.swift
//  KinKitchen
//
//  Created by Greg Hudler on 8/26/26.
//

import SwiftUI

struct GatheringsView: View {
    var body: some View {
        VStack(spacing: KinSpacing.large) {
            Image(systemName: KinIcons.gatherings)
                .font(.system(size: 48))
                .foregroundStyle(KinColors.primary)

            Text("Gatherings")
                .font(KinTypography.largeTitle)
                .foregroundStyle(KinColors.primaryText)

            Text("Your upcoming gatherings will appear here.")
                .font(KinTypography.body)
                .foregroundStyle(KinColors.secondaryText)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(KinColors.background)
    }
}

#Preview {
    GatheringsView()
}

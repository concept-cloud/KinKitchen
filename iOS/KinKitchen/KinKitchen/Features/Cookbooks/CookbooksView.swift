//
//  CookbooksView.swift
//  KinKitchen
//
//  Created by Greg Hudler on 8/26/26.
//

import SwiftUI

struct CookbooksView: View {
    var body: some View {
        VStack(spacing: KinSpacing.large) {
            Image(systemName: KinIcons.cookbooks)
                .font(.system(size: 48))
                .foregroundStyle(KinColors.primary)

            Text("Cookbooks")
                .font(KinTypography.largeTitle)
                .foregroundStyle(KinColors.primaryText)

            Text("Your private cookbooks and recipe collections will appear here.")
                .font(KinTypography.body)
                .foregroundStyle(KinColors.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, KinSpacing.large)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(KinColors.background)
    }
}

#Preview {
    CookbooksView()
}

//
//  RecipesView.swift
//  KinKitchen
//
//  Created by Greg Hudler on 8/26/26.
//

import SwiftUI

struct RecipesView: View {
    var body: some View {
        VStack(spacing: KinSpacing.large) {
            Image(systemName: KinIcons.recipes)
                .font(.system(size: 48))
                .foregroundStyle(KinColors.primary)

            Text("Recipes")
                .font(KinTypography.largeTitle)
                .foregroundStyle(KinColors.primaryText)

            Text("Your recipes will appear here.")
                .font(KinTypography.body)
                .foregroundStyle(KinColors.secondaryText)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(KinColors.background)
    }
}

#Preview {
    RecipesView()
}

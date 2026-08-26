//
//  ContentView.swift
//  KinKitchen
//
//  Created by Greg Hudler on 8/26/26.
//

import SwiftUI

struct ContentView: View {

    var body: some View {
        ScrollView {
            VStack(spacing: KinSpacing.xLarge) {

                // MARK: - Typography

                Text("Typography")
                    .font(KinTypography.title2)
                    .foregroundStyle(KinColors.primaryText)

                Text("Arvo Bold")
                    .font(.custom("Arvo-Bold", size: 28))
                    .foregroundStyle(KinColors.primaryText)

                Text("Arvo Regular")
                    .font(.custom("Arvo-Regular", size: 22))
                    .foregroundStyle(KinColors.primaryText)

                Text("Lora Bold")
                    .font(.custom("Lora-Bold", size: 22))
                    .foregroundStyle(KinColors.primaryText)

                Text("Lora Regular")
                    .font(.custom("Lora-Regular", size: 17))
                    .foregroundStyle(KinColors.primaryText)

                Divider()

                // MARK: - Spacing & Radius

                Text("Spacing & Radius")
                    .font(KinTypography.title2)
                    .foregroundStyle(KinColors.primaryText)

                HStack(spacing: KinSpacing.large) {

                    RoundedRectangle(cornerRadius: KinRadius.small)
                        .fill(KinColors.primary)
                        .frame(width: 60, height: 60)

                    RoundedRectangle(cornerRadius: KinRadius.medium)
                        .fill(KinColors.secondary)
                        .frame(width: 60, height: 60)

                    RoundedRectangle(cornerRadius: KinRadius.large)
                        .fill(KinColors.accent)
                        .frame(width: 60, height: 60)

                    RoundedRectangle(cornerRadius: KinRadius.xLarge)
                        .fill(KinColors.success)
                        .frame(width: 60, height: 60)
                }

                Divider()

                // MARK: - Icons

                Text("Icons")
                    .font(KinTypography.title2)
                    .foregroundStyle(KinColors.primaryText)

                HStack(spacing: KinSpacing.xLarge) {
                    Image(systemName: KinIcons.home)
                    Image(systemName: KinIcons.gatherings)
                    Image(systemName: KinIcons.recipes)
                    Image(systemName: KinIcons.cookbooks)
                    Image(systemName: KinIcons.profile)
                }
                .font(.title2)
                .foregroundStyle(KinColors.primary)
            }
            .padding(KinSpacing.large)
        }
        .background(KinColors.background)
    }
}

#Preview {
    ContentView()
}

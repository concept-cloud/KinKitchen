//
//  KinTabBar.swift
//  KinKitchen
//
//  Created by Greg Hudler on 8/26/26.
//

import SwiftUI

struct KinTabBarItem: Identifiable {
    let id = UUID()
    let title: String
    let icon: String
}

struct KinTabBar: View {
    let items: [KinTabBarItem]
    @Binding var selectedIndex: Int

    var body: some View {
        HStack {
            ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                Button {
                    selectedIndex = index
                } label: {
                    VStack(spacing: KinSpacing.xSmall) {
                        Image(systemName: item.icon)
                            .font(.title3)

                        Text(item.title)
                            .font(KinTypography.caption2)
                    }
                    .foregroundStyle(
                        selectedIndex == index
                            ? KinColors.primary
                            : KinColors.secondaryText
                    )
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(.vertical, KinSpacing.small)
        .background(KinColors.surface)
    }
}

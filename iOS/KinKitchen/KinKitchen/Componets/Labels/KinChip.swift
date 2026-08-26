//
//  KinChip.swift
//  KinKitchen
//
//  Created by Greg Hudler on 8/26/26.
//

import SwiftUI

struct KinChip: View {
    let title: String
    var isSelected: Bool = false

    var body: some View {
        Text(title)
            .font(KinTypography.caption)
            .foregroundStyle(
                isSelected ? KinColors.background : KinColors.primaryText
            )
            .padding(.horizontal, KinSpacing.medium)
            .padding(.vertical, KinSpacing.small)
            .background(
                isSelected ? KinColors.primary : KinColors.surface
            )
            .clipShape(Capsule())
    }
}

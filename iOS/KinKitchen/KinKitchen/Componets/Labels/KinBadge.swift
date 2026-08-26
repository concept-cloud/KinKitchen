//
//  KinBadge.swift
//  KinKitchen
//
//  Created by Greg Hudler on 8/26/26.
//

import SwiftUI

struct KinBadge: View {
    let title: String
    let color: Color

    var body: some View {
        Text(title)
            .font(KinTypography.caption)
            .foregroundStyle(KinColors.background)
            .padding(.horizontal, KinSpacing.small)
            .padding(.vertical, KinSpacing.xSmall)
            .background(color)
            .clipShape(Capsule())
    }
}

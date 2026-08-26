//
//  KinStatusBadge.swift
//  KinKitchen
//
//  Created by Greg Hudler on 8/26/26.
//

import SwiftUI

enum KinStatusType {
    case success
    case warning
    case error
    case info

    var color: Color {
        switch self {
        case .success:
            return KinColors.success
        case .warning:
            return KinColors.warning
        case .error:
            return KinColors.error
        case .info:
            return KinColors.secondary
        }
    }
}

struct KinStatusBadge: View {
    let title: String
    let status: KinStatusType

    var body: some View {
        Text(title)
            .font(KinTypography.caption)
            .foregroundStyle(KinColors.background)
            .padding(.horizontal, KinSpacing.small)
            .padding(.vertical, KinSpacing.xSmall)
            .background(status.color)
            .clipShape(Capsule())
    }
}

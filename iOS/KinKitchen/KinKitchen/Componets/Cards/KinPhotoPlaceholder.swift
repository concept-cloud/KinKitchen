//
//  KinPhotoPlaceholder.swift
//  KinKitchen
//
//  Created by Greg Hudler on 10/14/26.
//

import SwiftUI

/// What shows where a photo would be when there isn't one (or while it
/// loads): the warm Kin Kitchen gradient with a matching icon.
struct KinPhotoPlaceholder: View {

    var icon: String = KinIcons.recipes
    var iconSize: CGFloat = 26

    var body: some View {
        LinearGradient(
            colors: [
                KinColors.accent.opacity(0.35),
                KinColors.primary.opacity(0.25)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .overlay {
            Image(systemName: icon)
                .font(.system(size: iconSize, weight: .semibold))
                .foregroundStyle(KinColors.primary.opacity(0.6))
        }
        .accessibilityHidden(true)
    }
}

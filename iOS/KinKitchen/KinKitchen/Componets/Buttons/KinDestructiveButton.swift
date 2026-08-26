//
//  KinDestructiveButton.swift
//  KinKitchen
//
//  Created by Greg Hudler on 8/26/26.
//

import SwiftUI

struct KinDestructiveButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(KinTypography.button)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, KinSpacing.medium)
                .background(KinColors.error)
                .clipShape(
                    RoundedRectangle(cornerRadius: KinRadius.medium)
                )
        }
    }
}

#Preview {
    KinDestructiveButton(title: "Delete") {
        print("Destructive button tapped")
    }
    .padding()
    .background(KinColors.background)
}

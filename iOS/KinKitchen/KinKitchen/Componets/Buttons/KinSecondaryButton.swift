//
//  KinSecondaryButton.swift
//  KinKitchen
//
//  Created by Greg Hudler on 8/26/26.
//

import SwiftUI

struct KinSecondaryButton: View {

    let title: String
    var color: Color = KinColors.primary
    let action: () -> Void

    var body: some View {

        Button(action: action) {

            Text(title)
                .font(KinTypography.button)
                .foregroundStyle(color)
                .frame(maxWidth: .infinity)
                .padding(.vertical, KinSpacing.medium)
                .background(KinColors.surface)
                .overlay {
                    RoundedRectangle(cornerRadius: KinRadius.medium)
                        .stroke(color, lineWidth: 1)
                }
                .clipShape(
                    RoundedRectangle(cornerRadius: KinRadius.medium)
                )
        }
    }
}

#Preview {
    KinSecondaryButton(title: "Cancel") {
        print("Secondary button tapped")
    }
    .padding()
    .background(KinColors.background)
}

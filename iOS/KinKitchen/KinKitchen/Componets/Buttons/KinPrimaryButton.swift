//
//  KinPrimaryButton.swift
//  KinKitchen
//
//  Created by Greg Hudler on 8/26/26.
//

import SwiftUI

struct KinPrimaryButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(KinTypography.button)
                .foregroundStyle(KinColors.background)
                .frame(maxWidth: .infinity)
                .padding(.vertical, KinSpacing.medium)
                .background(KinColors.primary)
                .clipShape(
                    RoundedRectangle(cornerRadius: KinRadius.medium)
                )
        }
    }
}

#Preview {
    KinPrimaryButton(title: "Continue") {
        print("Primary button tapped")
    }
    .padding()
    .background(KinColors.background)
}

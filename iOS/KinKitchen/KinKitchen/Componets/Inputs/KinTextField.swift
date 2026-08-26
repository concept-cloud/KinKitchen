//
//  KinTextField.swift
//  KinKitchen
//
//  Created by Greg Hudler on 8/26/26.
//

import SwiftUI

struct KinTextField: View {
    let title: String
    @Binding var text: String

    var body: some View {
        TextField(title, text: $text)
            .font(KinTypography.body)
            .foregroundStyle(KinColors.primaryText)
            .padding(KinSpacing.large)
            .background(KinColors.surface)
            .clipShape(
                RoundedRectangle(cornerRadius: KinRadius.medium)
            )
    }
}

//
//  KintTextEditor.swift
//  KinKitchen
//
//  Created by Greg Hudler on 8/26/26.
//

import SwiftUI

struct KinTextEditor: View {
    @Binding var text: String
    var minHeight: CGFloat = 120

    var body: some View {
        TextEditor(text: $text)
            .font(KinTypography.body)
            .foregroundStyle(KinColors.primaryText)
            .scrollContentBackground(.hidden)
            .padding(KinSpacing.small)
            .frame(minHeight: minHeight)
            .background(KinColors.surface)
            .clipShape(
                RoundedRectangle(cornerRadius: KinRadius.medium)
            )
    }
}

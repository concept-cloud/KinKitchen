//
//  KinSecureField.swift
//  KinKitchen
//
//  Created by Greg Hudler on 8/26/26.
//


import SwiftUI

struct KinSecureField: View {

    let title: String
    @Binding var text: String
    var textContentType: UITextContentType? = .password

    var body: some View {
        SecureField(title, text: $text)
            .font(KinTypography.body)
            .foregroundStyle(KinColors.primaryText)
            .textContentType(textContentType)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .padding(KinSpacing.large)
            .background(KinColors.surface)
            .clipShape(
                RoundedRectangle(cornerRadius: KinRadius.medium)
            )
    }
}

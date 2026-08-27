//
//  SignUpView.swift
//  KinKitchen
//
//  Created by Greg Hudler on 8/26/26.
//

import SwiftUI

struct SignUpView: View {

    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""

    var body: some View {
        ScrollView {
            VStack(spacing: KinSpacing.xLarge) {

                Text("Create Account")
                    .font(KinTypography.largeTitle)
                    .foregroundStyle(KinColors.primaryText)

                Text("Join Kin Kitchen")
                    .font(KinTypography.body)
                    .foregroundStyle(KinColors.secondaryText)

                VStack(spacing: KinSpacing.large) {

                    KinTextField(
                        title: "Email",
                        text: $email
                    )

                    KinSecureField(
                        title: "Password",
                        text: $password,
                        textContentType: .newPassword
                    )

                    KinSecureField(
                        title: "Confirm Password",
                        text: $confirmPassword,
                        textContentType: .newPassword
                    )
                }

                KinPrimaryButton(
                    title: "Create Account",
                    color: KinColors.success
                ) {
                    print("Create Account tapped")
                }

                KinSecondaryButton(
                    title: "Already have an account? Sign In",
                    color: KinColors.success
                ) {
                    print("Navigate to Sign In")
                }
            }
            .padding(KinSpacing.xLarge)
        }
        .background(KinColors.background)
    }
}

#Preview {
    SignUpView()
}

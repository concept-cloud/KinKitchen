//
//  SignInView.swift
//  KinKitchen
//
//  Created by Greg Hudler on 8/27/26.
//

import SwiftUI

struct SignInView: View {

    @State private var email = ""
    @State private var password = ""

    var body: some View {
        ScrollView {
            VStack(spacing: KinSpacing.xLarge) {

                Text("Welcome Back")
                    .font(KinTypography.largeTitle)
                    .foregroundStyle(KinColors.primaryText)

                Text("Sign in to Kin Kitchen")
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
                        textContentType: .password
                    )
                }

                KinPrimaryButton(
                    title: "Sign In",
                    color: KinColors.success
                ) {
                    print("Sign In tapped")
                }

                KinSecondaryButton(
                    title: "Don't have an account? Sign Up",
                    color: KinColors.success
                ) {
                    print("Navigate to Sign Up")
                }
            }
            .padding(KinSpacing.xLarge)
        }
        .background(KinColors.background)
    }
}

#Preview {
    SignInView()
}

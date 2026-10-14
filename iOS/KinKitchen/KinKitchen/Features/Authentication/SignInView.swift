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
    
    @State private var isSigningIn = false
    @State private var errorMessage: String?
    
    @State private var isShowingSignUp = false

    var body: some View {
        ScrollView {
            VStack(spacing: KinSpacing.xLarge) {

                // Official logo, same as the rest of the app.
                KinLogo(height: 150)
                    .padding(.top, KinSpacing.large)

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
                    
                    if let errorMessage {
                        Text(errorMessage)
                            .font(KinTypography.body)
                            .foregroundStyle(KinColors.error)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }

                KinPrimaryButton(
                    title: isSigningIn ? "Signing In..." : "Sign In"
                ) {
                    Task {
                        await signIn()
                    }
                }
                .disabled(isSigningIn)
                
                KinSecondaryButton(
                    title: "Don't have an account? Sign Up"
                ) {
                    isShowingSignUp = true
                }
            }
            .padding(KinSpacing.xLarge)
        }
        .background(KinColors.background)
        .sheet(isPresented: $isShowingSignUp) {
            SignUpView()
        }
    }
    
    @MainActor
    private func signIn() async {
        errorMessage = nil

        let cleanEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !cleanEmail.isEmpty, !password.isEmpty else {
            errorMessage = "Please enter your email and password."
            return
        }
        
        guard cleanEmail.contains("@"),
              cleanEmail.contains(".") else {
            errorMessage = "Please enter a valid email address."
            return
        }

        isSigningIn = true
        defer {
            isSigningIn = false
        }

        do {
            try await AuthService.shared.signIn(
                email: cleanEmail,
                password: password
            )
            print("Sign in successful")
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

#Preview {
    SignInView()
}

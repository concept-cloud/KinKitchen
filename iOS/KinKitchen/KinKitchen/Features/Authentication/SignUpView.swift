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
    
    @State private var isCreatingAccount = false
    @State private var errorMessage: String?
    @State private var successMessage: String?

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
                    
                    if let errorMessage {
                        Text(errorMessage)
                            .font(KinTypography.body)
                            .foregroundStyle(KinColors.error)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    if let successMessage {
                        Text(successMessage)
                            .font(KinTypography.body)
                            .foregroundStyle(KinColors.success)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }

                KinPrimaryButton(
                    title: isCreatingAccount ? "Creating Account..." : "Create Account",
                    color: KinColors.success
                ) {
                    Task {
                        await createAccount()
                    }
                }
                .disabled(isCreatingAccount)

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
    
    @MainActor
    private func createAccount() async {

        errorMessage = nil
        successMessage = nil

        guard !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              !password.isEmpty,
              !confirmPassword.isEmpty else {
            errorMessage = "Please complete all required fields."
            return
        }

        guard password == confirmPassword else {
            errorMessage = "Passwords do not match."
            return
        }

        isCreatingAccount = true
        defer {
            isCreatingAccount = false
        }

        do {
            try await AuthService.shared.signUp(
                email: email.trimmingCharacters(in: .whitespacesAndNewlines),
                password: password
            )

            successMessage = "Check your email to continue setting up your account."

        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

#Preview {
    SignUpView()
}

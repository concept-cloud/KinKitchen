//
//  EditProfileView.swift
//  KinKitchen
//
//  Created by Greg Hudler on 8/27/26.
//

import SwiftUI

struct EditProfileView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var displayName: String
    @State private var username: String
    @State private var bio: String

    init(
        displayName: String = "",
        username: String = "",
        bio: String = ""
    ) {
        _displayName = State(initialValue: displayName)
        _username = State(initialValue: username)
        _bio = State(initialValue: bio)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: KinSpacing.xLarge) {
                Text("Edit Profile")
                    .font(KinTypography.largeTitle)
                    .foregroundStyle(KinColors.primaryText)

                VStack(alignment: .leading, spacing: KinSpacing.large) {
                    KinTextField(
                        title: "Display Name",
                        text: $displayName
                    )

                    KinTextField(
                        title: "Username",
                        text: $username
                    )

                    VStack(alignment: .leading, spacing: KinSpacing.small) {
                        Text("Bio")
                            .font(KinTypography.body)
                            .foregroundStyle(KinColors.primaryText)

                        KinTextEditor(
                            text: $bio
                        )
                    }
                }

                KinPrimaryButton(
                    title: "Save",
                    color: KinColors.success
                ) {
                    print("Save profile")
                }

                KinSecondaryButton(
                    title: "Cancel"
                ) {
                    dismiss()
                }
            }
            .padding(KinSpacing.xLarge)
        }
        .background(KinColors.background)
    }
}

#Preview {
    EditProfileView(
        displayName: "Greg Hudler",
        username: "greghudler",
        bio: "Family recipes, gatherings, and entirely too much food."
    )
}

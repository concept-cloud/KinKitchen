//
//  KinSearchBar.swift
//  KinKitchen
//
//  Created by Greg Hudler on 8/26/26.
//


import SwiftUI

struct KinSearchBar: View {
    @Binding var text: String
    var placeholder: String = "Search"

    var body: some View {
        HStack(spacing: KinSpacing.small) {
            Image(systemName: KinIcons.search)
                .foregroundStyle(KinColors.secondaryText)

            TextField(placeholder, text: $text)
                .font(KinTypography.body)
                .foregroundStyle(KinColors.primaryText)

            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: KinIcons.close)
                        .foregroundStyle(KinColors.secondaryText)
                }
            }
        }
        .padding(KinSpacing.medium)
        .background(KinColors.surface)
        .clipShape(
            RoundedRectangle(cornerRadius: KinRadius.medium)
        )
    }
}

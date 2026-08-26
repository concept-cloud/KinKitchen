//
//  KinSelectionHeader.swift
//  KinKitchen
//
//  Created by Greg Hudler on 8/26/26.
//

import SwiftUI

struct KinSectionHeader: View {
    let title: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        HStack {
            Text(title)
                .font(KinTypography.sectionTitle)
                .foregroundStyle(KinColors.primaryText)

            Spacer()

            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .font(KinTypography.subheadline)
                    .foregroundStyle(KinColors.primary)
            }
        }
    }
}

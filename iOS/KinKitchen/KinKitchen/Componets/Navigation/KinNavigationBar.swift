//
//  KinNavigationBar.swift
//  KinKitchen
//
//  Created by Greg Hudler on 8/26/26.
//

import SwiftUI

struct KinNavigationBar: View {
    let title: String
    var showBackButton: Bool = false
    var actionIcon: String? = nil
    var backAction: (() -> Void)? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        HStack {
            if showBackButton {
                Button {
                    backAction?()
                } label: {
                    Image(systemName: KinIcons.back)
                        .foregroundStyle(KinColors.primary)
                }
                .frame(width: 44, height: 44)
            }

            Text(title)
                .font(KinTypography.navigationTitle)
                .foregroundStyle(KinColors.primaryText)

            Spacer()

            if let actionIcon {
                Button {
                    action?()
                } label: {
                    Image(systemName: actionIcon)
                        .foregroundStyle(KinColors.primary)
                }
                .frame(width: 44, height: 44)
            }
        }
        .padding(.horizontal, KinSpacing.large)
        .padding(.vertical, KinSpacing.small)
        .background(KinColors.background)
    }
}

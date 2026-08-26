//
//  KinIconButton.swift
//  KinKitchen
//
//  Created by Greg Hudler on 8/26/26.
//

import SwiftUI

struct KinIconButton: View {
    let icon: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(KinColors.primary)
                .frame(width: 44, height: 44)
                .background(KinColors.surface)
                .clipShape(Circle())
        }
        .accessibilityLabel(Text(icon))
    }
}

#Preview {
    HStack {
        KinIconButton(icon: KinIcons.add) {
            print("Add tapped")
        }

        KinIconButton(icon: KinIcons.edit) {
            print("Edit tapped")
        }

        KinIconButton(icon: KinIcons.favorite) {
            print("Favorite tapped")
        }
    }
    .padding()
    .background(KinColors.background)
}

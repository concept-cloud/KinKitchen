//
//  KinPhotoPicker.swift
//  KinKitchen
//
//  Created by Greg Hudler on 8/26/26.
//

import SwiftUI
import PhotosUI

struct KinPhotoPicker: View {
    @Binding var selectedItem: PhotosPickerItem?

    var body: some View {
        PhotosPicker(
            selection: $selectedItem,
            matching: .images
        ) {
            Label("Choose Photo", systemImage: KinIcons.photo)
                .font(KinTypography.button)
                .foregroundStyle(KinColors.primary)
        }
    }
}

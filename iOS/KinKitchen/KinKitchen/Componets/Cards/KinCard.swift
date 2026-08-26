//
//  KinCard.swift
//  KinKitchen
//
//  Created by Greg Hudler on 8/26/26.
//

import SwiftUI

struct KinCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(KinSpacing.large)
            .background(KinColors.surface)
            .clipShape(
                RoundedRectangle(cornerRadius: KinRadius.large)
            )
    }
}

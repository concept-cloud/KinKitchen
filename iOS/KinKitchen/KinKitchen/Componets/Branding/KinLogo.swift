//
//  KinLogo.swift
//  KinKitchen
//
//  Created by Greg Hudler on 10/13/26.
//

import SwiftUI

/// The official Kin Kitchen logo, shown as supplied: original colors and
/// proportions, never tinted or redrawn.
struct KinLogo: View {

    /// Height of the artwork. Grows a little with larger text sizes,
    /// within `maxHeight`, so it never crowds the content below it.
    @ScaledMetric
    private var scaledHeight: CGFloat

    private let maxHeight: CGFloat

    init(
        height: CGFloat = 120,
        maxHeight: CGFloat? = nil
    ) {

        _scaledHeight =
            ScaledMetric(
                wrappedValue: height,
                relativeTo: .title
            )

        self.maxHeight =
            maxHeight ?? height * 1.3
    }

    var body: some View {

        Image("Logo")
            .renderingMode(.original)
            .resizable()
            .interpolation(.high)
            .scaledToFit()
            .frame(
                height: min(
                    scaledHeight,
                    maxHeight
                )
            )
            .accessibilityLabel("Kin Kitchen")
            .accessibilityAddTraits(.isHeader)
            .accessibilityRemoveTraits(.isImage)
    }
}


#Preview {

    KinLogo()
        .padding()
        .background(KinColors.background)
}

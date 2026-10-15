//
//  DietaryBackgroundPicker.swift
//  KinKitchen
//
//  Created by Greg Hudler on 10/14/26.
//

import SwiftUI

/// Grid of header photos for the Dietary Profile. Picking one saves it
/// right away; the header behind the sheet updates live.
struct DietaryBackgroundPicker: View {

    @Environment(\.dismiss) private var dismiss

    @AppStorage(KinDietaryBackground.storageKey)
    private var selection = KinDietaryBackground.default.rawValue

    private let columns = [
        GridItem(.flexible(), spacing: KinSpacing.medium),
        GridItem(.flexible(), spacing: KinSpacing.medium),
        GridItem(.flexible(), spacing: KinSpacing.medium)
    ]

    var body: some View {

        NavigationStack {

            ScrollView {

                VStack(
                    alignment: .leading,
                    spacing: KinSpacing.large
                ) {

                    Text("Choose a background that fits your style.")
                        .font(KinTypography.callout)
                        .foregroundStyle(KinColors.secondaryText)

                    LazyVGrid(
                        columns: columns,
                        spacing: KinSpacing.large
                    ) {
                        ForEach(KinDietaryBackground.allCases) { background in
                            option(background)
                        }
                    }
                }
                .padding(KinSpacing.large)
            }
            .background(KinColors.background)
            .navigationTitle("Background")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .tint(KinColors.primary)
                }
            }
        }
        .sensoryFeedback(.selection, trigger: selection)
    }

    private func option(
        _ background: KinDietaryBackground
    ) -> some View {

        let isSelected =
            KinDietaryBackground.saved(selection) == background

        return Button {
            selection = background.rawValue
        } label: {

            VStack(
                alignment: .leading,
                spacing: KinSpacing.xSmall
            ) {

                Color.clear
                    .aspectRatio(0.75, contentMode: .fit)
                    .overlay {
                        Image(background.imageName)
                            .resizable()
                            .scaledToFill()
                    }
                    .clipShape(
                        RoundedRectangle(cornerRadius: KinRadius.medium)
                    )
                    .overlay {
                        RoundedRectangle(cornerRadius: KinRadius.medium)
                            .strokeBorder(
                                isSelected ? KinColors.primary : .clear,
                                lineWidth: 3
                            )
                    }
                    .overlay(alignment: .topTrailing) {
                        if isSelected {
                            Image(systemName: KinIcons.success)
                                .font(.system(size: 20))
                                .foregroundStyle(.white, KinColors.primary)
                                .padding(KinSpacing.small)
                        }
                    }

                Text(background.title)
                    .font(KinTypography.footnote.weight(.semibold))
                    .foregroundStyle(KinColors.primaryText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                Text(background.subtitle)
                    .font(KinTypography.caption2)
                    .foregroundStyle(KinColors.secondaryText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
        }
        .buttonStyle(.kinPressable)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(background.title), \(background.subtitle)")
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }
}

#Preview {
    DietaryBackgroundPicker()
}

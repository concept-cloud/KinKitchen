//
//  KinEventTypePicker.swift
//  KinKitchen
//
//  Created by Greg Hudler on 10/15/26.
//

import SwiftUI

/// A grid of event type tiles, used on Add Event and Edit Event.
/// The chosen type's description shows underneath.
struct KinEventTypePicker: View {

    @Binding var selection: KinEventType?

    private let columns = Array(
        repeating: GridItem(.flexible(), spacing: KinSpacing.small),
        count: 3
    )

    var body: some View {

        VStack(
            alignment: .leading,
            spacing: KinSpacing.small
        ) {

            LazyVGrid(
                columns: columns,
                spacing: KinSpacing.small
            ) {
                ForEach(KinEventType.allCases) { type in
                    tile(type)
                }
            }

            Text(
                selection?.subtitle
                    ?? "Choose what kind of event this is."
            )
            .font(KinTypography.caption)
            .foregroundStyle(KinColors.secondaryText)
            .animation(nil, value: selection)
        }
    }

    private func tile(_ type: KinEventType) -> some View {

        let isSelected = selection == type

        return Button {
            withAnimation(.snappy(duration: 0.2)) {
                selection = type
            }
        } label: {

            VStack(spacing: KinSpacing.xSmall) {

                Image(systemName: type.symbol)
                    .font(.system(size: 20, weight: .semibold))
                    .frame(height: 24)

                Text(type.title)
                    .font(KinTypography.caption)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)
            }
            .foregroundStyle(
                isSelected ? .white : KinColors.primaryText
            )
            .frame(maxWidth: .infinity, minHeight: 72)
            .padding(.horizontal, KinSpacing.xSmall)
            .background(
                isSelected ? KinColors.primary : KinColors.surface,
                in: RoundedRectangle(cornerRadius: KinRadius.medium)
            )
            .overlay {
                RoundedRectangle(cornerRadius: KinRadius.medium)
                    .strokeBorder(
                        KinColors.primary.opacity(isSelected ? 0 : 0.15)
                    )
            }
        }
        .buttonStyle(.kinPressable)
        .accessibilityLabel(type.title)
        .accessibilityHint(type.subtitle)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}


/// The event's type as a small icon and label, for cards and
/// Event Detail.
struct KinEventTypeLabel: View {

    let type: KinEventType

    var body: some View {

        Label(type.title, systemImage: type.symbol)
            .font(.system(size: 12, weight: .bold))
            .textCase(.uppercase)
            .foregroundStyle(KinColors.primary)
            .labelStyle(.titleAndIcon)
    }
}


#Preview {

    @Previewable @State var selection: KinEventType? = .backyardBBQ

    KinEventTypePicker(selection: $selection)
        .padding()
        .background(KinColors.background)
}

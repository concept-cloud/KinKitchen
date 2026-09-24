//
//  AddGatheringSuppliesView.swift
//  KinKitchen
//
//  Created by Greg Hudler on 9/23/26.
//
import SwiftUI

struct AddGatheringSuppliesView: View {

    @Environment(\.dismiss) private var dismiss

    let gatheringId: UUID

    @State private var selectedSupplies: Set<DishSupply> = []
    @State private var quantities: [DishSupply: Int] = [:]
    @State private var quantityText: [DishSupply: String] = [:]
    @State private var isSaving = false
    @State private var errorMessage: String?

    var body: some View {
        ZStack {
            KinColors.background
                .ignoresSafeArea()

            VStack(
                spacing: 0
            ) {
                navigationHeader

                ScrollView(
                    showsIndicators: false
                ) {
                    VStack(
                        alignment: .leading,
                        spacing: KinSpacing.xLarge
                    ) {
                        introSection
                        suppliesSection

                        if let errorMessage {
                            Text(errorMessage)
                                .font(
                                    KinTypography.footnote
                                )
                                .foregroundStyle(
                                    KinColors.error
                                )
                        }

                        KinPrimaryButton(
                            title:
                                isSaving
                                ? "Adding Supplies..."
                                : "Add Supplies"
                        ) {
                            Task {
                                await saveSupplies()
                            }
                        }
                        .disabled(
                            selectedSupplies.isEmpty ||
                            isSaving
                        )
                    }
                    .padding(
                        .horizontal,
                        KinSpacing.large
                    )
                    .padding(
                        .bottom,
                        KinSpacing.xxxLarge
                    )
                }
            }
        }
        .navigationBarHidden(true)
    }
}

// MARK: - Navigation

private extension AddGatheringSuppliesView {

    var navigationHeader: some View {
        ZStack {
            Text("Add Supplies")
                .font(
                    KinTypography.navigationTitle
                )
                .foregroundStyle(
                    KinColors.primaryText
                )

            HStack {
                Button {
                    dismiss()
                } label: {
                    Image(
                        systemName: "chevron.left"
                    )
                    .font(
                        .system(
                            size: 20,
                            weight: .semibold
                        )
                    )
                    .foregroundStyle(
                        KinColors.primaryText
                    )
                    .frame(
                        width: 48,
                        height: 48
                    )
                    .background(
                        KinColors.surface
                    )
                    .clipShape(
                        Circle()
                    )
                }
                .buttonStyle(.plain)

                Spacer()
            }
        }
        .padding(
            .horizontal,
            KinSpacing.large
        )
        .padding(
            .top,
            KinSpacing.small
        )
        .padding(
            .bottom,
            KinSpacing.large
        )
    }
}

// MARK: - Intro

private extension AddGatheringSuppliesView {

    var introSection: some View {
        VStack(
            alignment: .leading,
            spacing: KinSpacing.small
        ) {
            Text("What does the gathering need?")
                .font(
                    KinTypography.sectionTitle
                )
                .foregroundStyle(
                    KinColors.primaryText
                )

            Text(
                "Select supplies guests can volunteer to bring."
            )
            .font(
                KinTypography.body
            )
            .foregroundStyle(
                KinColors.secondaryText
            )
        }
    }
}

// MARK: - Supplies

private extension AddGatheringSuppliesView {

    var suppliesSection: some View {
        VStack(
            spacing: KinSpacing.medium
        ) {
            ForEach(
                DishSupply.allCases,
                id: \.self
            ) { supply in
                supplyRow(supply)
            }
        }
    }

    func supplyRow(
        _ supply: DishSupply
    ) -> some View {
        let isSelected =
            selectedSupplies.contains(supply)

        return VStack(
            spacing: KinSpacing.medium
        ) {
            Button {
                toggleSupply(supply)
            } label: {
                HStack(
                    spacing: KinSpacing.medium
                ) {
                    Image(
                        systemName:
                            isSelected
                            ? "checkmark.circle.fill"
                            : "circle"
                    )
                    .font(
                        KinTypography.headline
                    )
                    .foregroundStyle(
                        isSelected
                        ? KinColors.primary
                        : KinColors.secondaryText
                    )

                    Text(
                        supply.displayName
                    )
                    .font(
                        KinTypography.body
                    )
                    .foregroundStyle(
                        KinColors.primaryText
                    )

                    Spacer()
                }
                .contentShape(
                    Rectangle()
                )
            }
            .buttonStyle(.plain)

            if isSelected {
                quantityControls(
                    for: supply
                )
            }
        }
        .padding(
            KinSpacing.large
        )
        .background(
            KinColors.surface
        )
        .clipShape(
            RoundedRectangle(
                cornerRadius: KinRadius.large
            )
        )
    }

    func quantityControls(
        for supply: DishSupply
    ) -> some View {
        HStack(
            spacing: KinSpacing.medium
        ) {
            Text("Quantity")
                .font(
                    KinTypography.footnote
                )
                .foregroundStyle(
                    KinColors.secondaryText
                )

            Spacer()

            Button {
                decreaseQuantity(
                    for: supply
                )
            } label: {
                Image(
                    systemName: "minus"
                )
                .foregroundStyle(
                    KinColors.primary
                )
                .frame(
                    width: 36,
                    height: 36
                )
                .background(
                    KinColors.background
                )
                .clipShape(
                    Circle()
                )
            }
            .buttonStyle(.plain)

            TextField(
                "1",
                text: quantityTextBinding(
                    for: supply
                )
            )
            .keyboardType(.numberPad)
            .multilineTextAlignment(
                .center
            )
            .font(
                KinTypography.headline
            )
            .foregroundStyle(
                KinColors.primaryText
            )
            .frame(
                width: 80
            )
            .padding(
                .vertical,
                KinSpacing.small
            )
            .background(
                KinColors.background
            )
            .clipShape(
                RoundedRectangle(
                    cornerRadius:
                        KinRadius.medium
                )
            )

            Button {
                increaseQuantity(
                    for: supply
                )
            } label: {
                Image(
                    systemName: "plus"
                )
                .foregroundStyle(
                    KinColors.primary
                )
                .frame(
                    width: 36,
                    height: 36
                )
                .background(
                    KinColors.background
                )
                .clipShape(
                    Circle()
                )
            }
            .buttonStyle(.plain)
        }
    }

    func toggleSupply(
        _ supply: DishSupply
    ) {
        if selectedSupplies.contains(
            supply
        ) {
            selectedSupplies.remove(
                supply
            )

            quantities[supply] = nil
            quantityText[supply] = nil
        } else {
            selectedSupplies.insert(
                supply
            )

            quantities[supply] = 1
            quantityText[supply] = "1"
        }
    }

    func decreaseQuantity(
        for supply: DishSupply
    ) {
        let current =
            quantities[supply] ?? 1

        let newValue =
            max(
                1,
                current - 1
            )

        quantities[supply] =
            newValue

        quantityText[supply] =
            String(newValue)
    }

    func increaseQuantity(
        for supply: DishSupply
    ) {
        let current =
            quantities[supply] ?? 1

        let newValue =
            current + 1

        quantities[supply] =
            newValue

        quantityText[supply] =
            String(newValue)
    }

    func quantityTextBinding(
        for supply: DishSupply
    ) -> Binding<String> {
        Binding(
            get: {
                quantityText[supply] ??
                    String(
                        quantities[supply] ?? 1
                    )
            },
            set: { newValue in
                let digits =
                    newValue.filter {
                        $0.isNumber
                    }

                quantityText[supply] =
                    digits

                if let value = Int(digits),
                   value > 0 {
                    quantities[supply] =
                        value
                }
            }
        )
    }
}

// MARK: - Save

private extension AddGatheringSuppliesView {

    @MainActor
    func saveSupplies() async {
        guard !selectedSupplies.isEmpty else {
            return
        }

        for supply in selectedSupplies {
            let text =
                quantityText[supply]?
                    .trimmingCharacters(
                        in: .whitespacesAndNewlines
                    ) ?? ""

            guard
                let quantity = Int(text),
                quantity > 0
            else {
                errorMessage =
                    "Enter a valid quantity for \(supply.displayName)."
                return
            }

            quantities[supply] =
                quantity
        }

        isSaving = true
        errorMessage = nil

        do {
            for supply in selectedSupplies {
                try await GatheringDishService
                    .createNeed(
                        gatheringId:
                            gatheringId,
                        name:
                            supply.displayName,
                        category:
                            .other,
                        quantityNeeded:
                            quantities[supply] ?? 1,
                        supplies:
                            [supply]
                    )
            }

            dismiss()

        } catch {
            errorMessage =
                "Unable to add supplies. Please try again."
        }

        isSaving = false
    }
}

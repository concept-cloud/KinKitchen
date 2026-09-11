//
//  GatheringNeedDetailView.swift
//  KinKitchen
//
//  Created by Greg Hudler on 9/10/26.
//

import SwiftUI

struct GatheringNeedDetailView: View {
    @Environment(\.dismiss) private var dismiss

    let need: GatheringNeed

    @State private var requirements: [GatheringNeedRequirement] = []
    @State private var supplies: [GatheringNeedSupply] = []
    @State private var claims: [GatheringNeedClaim] = []
    @State private var isLoading = true
    @State private var errorMessage: String?

    var body: some View {
        ZStack {
            KinColors.background
                .ignoresSafeArea()

            if isLoading {
                ProgressView()
                    .tint(KinColors.primary)
            } else {
                ScrollView(
                    showsIndicators: false
                ) {
                    VStack(
                        alignment: .leading,
                        spacing: KinSpacing.xLarge
                    ) {
                        header
                        dishHeader
                        servingsSection

                        if !requirements.isEmpty {
                            requirementsSection
                        }

                        if !supplies.isEmpty {
                            suppliesSection
                        }

                        if let notes = need.notes,
                           !notes.isEmpty {
                            notesSection(notes)
                        }

                        if let errorMessage {
                            Text(errorMessage)
                                .font(KinTypography.footnote)
                                .foregroundStyle(KinColors.error)
                        }
                    }
                    .padding(KinSpacing.large)
                    .padding(
                        .bottom,
                        KinSpacing.xxxLarge
                    )
                }
            }
        }
        .navigationBarHidden(true)
        .task {
            await loadDetails()
        }
    }
}

// MARK: - Header

private extension GatheringNeedDetailView {
    var header: some View {
        ZStack {
            Text("Dish Details")
                .font(KinTypography.navigationTitle)
                .foregroundStyle(KinColors.primaryText)

            HStack {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(
                            .system(
                                size: 20,
                                weight: .semibold
                            )
                        )
                        .foregroundStyle(KinColors.primaryText)
                        .frame(
                            width: 48,
                            height: 48
                        )
                        .background(KinColors.surface)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)

                Spacer()
            }
        }
    }
}

// MARK: - Dish Header

private extension GatheringNeedDetailView {
    var dishHeader: some View {
        VStack(
            alignment: .leading,
            spacing: KinSpacing.medium
        ) {
            HStack(
                alignment: .center,
                spacing: KinSpacing.medium
            ) {
                ZStack {
                    Circle()
                        .fill(
                            KinColors.primary.opacity(0.10)
                        )
                        .frame(
                            width: 58,
                            height: 58
                        )

                    Image(
                        systemName: dishIcon
                    )
                    .font(
                        .system(
                            size: 24,
                            weight: .medium
                        )
                    )
                    .foregroundStyle(KinColors.primary)
                }

                VStack(
                    alignment: .leading,
                    spacing: KinSpacing.xSmall
                ) {
                    Text(need.name)
                        .font(KinTypography.title2)
                        .foregroundStyle(KinColors.primaryText)

                    Text(need.category.displayName)
                        .font(KinTypography.body)
                        .foregroundStyle(KinColors.secondaryText)
                }

                Spacer()
            }
        }
        .padding(KinSpacing.large)
        .frame(
            maxWidth: .infinity,
            alignment: .leading
        )
        .background(KinColors.surface)
        .clipShape(
            RoundedRectangle(
                cornerRadius: KinRadius.large
            )
        )
    }

    var dishIcon: String {
        switch need.category {
        case .entree:
            return "fork.knife"
        case .side:
            return "takeoutbag.and.cup.and.straw"
        case .dessert:
            return "birthday.cake"
        case .drink:
            return "cup.and.saucer"
        case .supplies:
            return "shippingbox"
        case .other:
            return "fork.knife"
        }
    }
}

// MARK: - Servings

private extension GatheringNeedDetailView {
    var servingsSection: some View {
        HStack {
            VStack(
                alignment: .leading,
                spacing: KinSpacing.xSmall
            ) {
                Text("Servings Needed")
                    .font(KinTypography.headline)
                    .foregroundStyle(KinColors.primaryText)

                Text(claimStatusText)
                    .font(KinTypography.footnote)
                    .foregroundStyle(KinColors.secondaryText)
            }

            Spacer()

            Text("\(need.quantityNeeded)")
                .font(KinTypography.title2)
                .foregroundStyle(KinColors.primary)
        }
        .padding(KinSpacing.large)
        .background(KinColors.surface)
        .clipShape(
            RoundedRectangle(
                cornerRadius: KinRadius.large
            )
        )
    }

    var claimStatusText: String {
        let claimed =
            claims.reduce(0) {
                $0 + $1.quantity
            }

        let remaining =
            max(
                need.quantityNeeded - claimed,
                0
            )

        if remaining == 0 {
            return "Fully claimed"
        }

        if claimed == 0 {
            return "Not claimed yet"
        }

        return "\(remaining) remaining"
    }
}

// MARK: - Requirements

private extension GatheringNeedDetailView {
    var requirementsSection: some View {
        VStack(
            alignment: .leading,
            spacing: KinSpacing.medium
        ) {
            Text("Dish Needs")
                .font(KinTypography.headline)
                .foregroundStyle(KinColors.primaryText)

            FlowLayout(
                spacing: KinSpacing.small
            ) {
                ForEach(
                    requirements,
                    id: \.need
                ) { requirement in
                    Text(requirement.need.displayName)
                        .font(KinTypography.footnote)
                        .foregroundStyle(KinColors.primaryText)
                        .padding(
                            .horizontal,
                            KinSpacing.medium
                        )
                        .padding(
                            .vertical,
                            KinSpacing.small
                        )
                        .background(KinColors.surface)
                        .clipShape(Capsule())
                }
            }
        }
    }
}

// MARK: - Supplies

private extension GatheringNeedDetailView {
    var suppliesSection: some View {
        VStack(
            alignment: .leading,
            spacing: KinSpacing.medium
        ) {
            Text("Dish Supplies")
                .font(KinTypography.headline)
                .foregroundStyle(KinColors.primaryText)

            VStack(
                spacing: 0
            ) {
                ForEach(
                    supplies,
                    id: \.supply
                ) { supply in
                    HStack {
                        Text(supply.supply.displayName)
                            .font(KinTypography.body)
                            .foregroundStyle(KinColors.primaryText)

                        Spacer()

                        Image(
                            systemName: "checkmark.circle.fill"
                        )
                        .foregroundStyle(KinColors.primary)
                    }
                    .padding(KinSpacing.large)

                    if supply.supply != supplies.last?.supply {
                        Divider()
                    }
                }
            }
            .background(KinColors.surface)
            .clipShape(
                RoundedRectangle(
                    cornerRadius: KinRadius.large
                )
            )
        }
    }
}

// MARK: - Notes

private extension GatheringNeedDetailView {
    func notesSection(
        _ notes: String
    ) -> some View {
        VStack(
            alignment: .leading,
            spacing: KinSpacing.medium
        ) {
            Text("Notes")
                .font(KinTypography.headline)
                .foregroundStyle(KinColors.primaryText)

            Text(notes)
                .font(KinTypography.body)
                .foregroundStyle(KinColors.primaryText)
                .frame(
                    maxWidth: .infinity,
                    alignment: .leading
                )
                .padding(KinSpacing.large)
                .background(KinColors.surface)
                .clipShape(
                    RoundedRectangle(
                        cornerRadius: KinRadius.large
                    )
                )
        }
    }
}

// MARK: - Load

private extension GatheringNeedDetailView {
    @MainActor
    func loadDetails() async {
        isLoading = true
        errorMessage = nil

        do {
            async let requirementsRequest =
                GatheringDishService
                    .fetchNeedRequirements(
                        needId: need.id
                    )

            async let suppliesRequest =
                GatheringDishService
                    .fetchNeedSupplies(
                        needId: need.id
                    )

            async let claimsRequest =
                GatheringDishService
                    .fetchClaims(
                        needId: need.id
                    )

            let (
                loadedRequirements,
                loadedSupplies,
                loadedClaims
            ) = try await (
                requirementsRequest,
                suppliesRequest,
                claimsRequest
            )

            requirements = loadedRequirements
            supplies = loadedSupplies
            claims = loadedClaims
        } catch {
            errorMessage =
                error.localizedDescription
        }

        isLoading = false
    }
}

// MARK: - Flow Layout

private struct FlowLayout: Layout {
    let spacing: CGFloat

    func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) -> CGSize {
        let width =
            proposal.width ?? 0

        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size =
                subview.sizeThatFits(
                    .unspecified
                )

            if x + size.width > width,
               x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }

            x += size.width + spacing
            rowHeight =
                max(
                    rowHeight,
                    size.height
                )
        }

        return CGSize(
            width: width,
            height: y + rowHeight
        )
    }

    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size =
                subview.sizeThatFits(
                    .unspecified
                )

            if x + size.width > bounds.maxX,
               x > bounds.minX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }

            subview.place(
                at: CGPoint(
                    x: x,
                    y: y
                ),
                proposal: ProposedViewSize(
                    size
                )
            )

            x += size.width + spacing
            rowHeight =
                max(
                    rowHeight,
                    size.height
                )
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        GatheringNeedDetailView(
            need: GatheringNeed(
                id: UUID(),
                gatheringId: UUID(),
                category: .side,
                name: "Macaroni & Cheese",
                quantityNeeded: 4,
                recipeId: nil,
                notes: "Keep warm until serving.",
                createdAt: Date(),
                updatedAt: Date()
            )
        )
    }
}

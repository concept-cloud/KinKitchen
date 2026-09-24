//
//  GatheringNeedDetailView.swift
//  KinKitchen
//
//  Created by Greg Hudler on 9/10/26.
//

import SwiftUI
import Supabase

struct GatheringNeedDetailView: View {
    @Environment(\.dismiss) private var dismiss

    let need: GatheringNeed
    let isHost: Bool
    
    @State private var currentNeed: GatheringNeed
    @State private var requirements: [GatheringNeedRequirement] = []
    @State private var supplies: [GatheringNeedSupply] = []
    @State private var claims: [GatheringNeedClaim] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var recipe: Recipe?
    @State private var showingRecipeDetail = false
    @State private var currentUserId: UUID?
    @State private var claimQuantity = 1
    @State private var claimQuantityText = "1"
    @State private var isEditingClaim = false
    @State private var isClaiming = false
    @State private var claimErrorMessage: String?
    @State private var isEditingNeed = false
    @State private var needQuantityText = ""
    @State private var isSavingNeed = false
    @State private var needEditErrorMessage: String?

    init(
        need: GatheringNeed,
        isHost: Bool
    ) {
        self.need = need
        self.isHost = isHost
        _currentNeed = State(
            initialValue: need
        )
        _needQuantityText = State(
            initialValue:
                String(currentNeed.quantityNeeded)
        )
    }

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

                        if let recipe {
                            recipeSection(recipe)
                        }

                        dishesNeededSection
                        
                        claimSection

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
        .navigationDestination(
            isPresented: $showingRecipeDetail
        ) {
            if let recipe {
                RecipeDetailView(
                    recipeId: recipe.id
                )
            }
        }
        .task {
            await loadDetails()
        }
    }
}

// MARK: - Header

private extension GatheringNeedDetailView {

    var isStandaloneSupply: Bool {
        !supplies.isEmpty &&
        requirements.isEmpty &&
        currentNeed.category == .other &&
        currentNeed.recipeId == nil &&
        supplies.contains {
            $0.supply.displayName ==
                currentNeed.name
        }
    }

    var header: some View {
        ZStack {
            Text(
                isStandaloneSupply
                ? "Supply Details"
                : "Dish Details"
            )
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

                if isHost {
                    Button {
                        needQuantityText =
                            String(
                                currentNeed
                                    .quantityNeeded
                            )

                        isEditingNeed = true
                    } label: {
                        Text("Edit")
                            .font(
                                KinTypography.callout
                            )
                            .foregroundStyle(
                                KinColors.primary
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

// MARK: - Need Header

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
                            KinColors.primary
                                .opacity(0.10)
                        )
                        .frame(
                            width: 58,
                            height: 58
                        )

                    Image(
                        systemName:
                            isStandaloneSupply
                            ? "shippingbox.fill"
                            : dishIcon
                    )
                    .font(
                        .system(
                            size: 24,
                            weight: .medium
                        )
                    )
                    .foregroundStyle(
                        KinColors.primary
                    )
                }

                VStack(
                    alignment: .leading,
                    spacing: KinSpacing.xSmall
                ) {
                    Text(
                        currentNeed.name
                    )
                    .font(
                        KinTypography.title2
                    )
                    .foregroundStyle(
                        KinColors.primaryText
                    )

                    Text(
                        isStandaloneSupply
                        ? "Gathering Supply"
                        : currentNeed
                            .category
                            .displayName
                    )
                    .font(
                        KinTypography.body
                    )
                    .foregroundStyle(
                        KinColors.secondaryText
                    )
                }

                Spacer()
            }
        }
        .padding(
            KinSpacing.large
        )
        .frame(
            maxWidth: .infinity,
            alignment: .leading
        )
        .background(
            KinColors.surface
        )
        .clipShape(
            RoundedRectangle(
                cornerRadius:
                    KinRadius.large
            )
        )
    }

    var dishIcon: String {
        switch currentNeed.category {
        case .appetizer:
            return "takeoutbag.and.cup.and.straw"
        case .entree:
            return "fork.knife"
        case .side:
            return "takeoutbag.and.cup.and.straw"
        case .salad:
            return "leaf.fill"
        case .bread:
            return "basket.fill"
        case .dessert:
            return "birthday.cake"
        case .drink:
            return "cup.and.saucer"
        case .condimentSauce:
            return "takeoutbag.and.cup.and.straw"
        case .other:
            return "fork.knife"
        }
    }
}


// MARK: - Recipe

private extension GatheringNeedDetailView {
    func recipeSection(
        _ recipe: Recipe
    ) -> some View {
        VStack(
            alignment: .leading,
            spacing: KinSpacing.medium
        ) {
            Text("Recipe")
                .font(KinTypography.headline)
                .foregroundStyle(
                    KinColors.primaryText
                )

            VStack(
                alignment: .leading,
                spacing: KinSpacing.medium
            ) {
                HStack(
                    spacing: KinSpacing.medium
                ) {
                    ZStack {
                        RoundedRectangle(
                            cornerRadius:
                                KinRadius.medium
                        )
                        .fill(
                            KinColors.primary
                                .opacity(0.10)
                        )
                        .frame(
                            width: 56,
                            height: 56
                        )

                        Image(
                            systemName:
                                "book.closed.fill"
                        )
                        .font(.title2)
                        .foregroundStyle(
                            KinColors.primary
                        )
                    }

                    VStack(
                        alignment: .leading,
                        spacing: KinSpacing.xSmall
                    ) {
                        Text(recipe.name)
                            .font(
                                KinTypography.headline
                            )
                            .foregroundStyle(
                                KinColors.primaryText
                            )

                        if let category =
                            recipe.category,
                           !category.isEmpty {
                            Text(category)
                                .font(
                                    KinTypography.footnote
                                )
                                .foregroundStyle(
                                    KinColors.secondaryText
                                )
                        }
                    }

                    Spacer()
                }

                if let description =
                    recipe.description,
                   !description.isEmpty {
                    Text(description)
                        .font(
                            KinTypography.body
                        )
                        .foregroundStyle(
                            KinColors.secondaryText
                        )
                }

                HStack(
                    spacing: KinSpacing.xLarge
                ) {
                    if let servings =
                        recipe.servings {
                        recipeStat(
                            icon: "person.2.fill",
                            value:
                                "\(servings)",
                            label: "Servings"
                        )
                    }

                    if recipe.prepTimeMinutes != nil {
                        recipeStat(
                            icon: "clock",
                            value:
                                recipe.formattedPrepTime,
                            label: "Prep"
                        )
                    }

                    if recipe.cookTimeMinutes != nil {
                        recipeStat(
                            icon: "flame.fill",
                            value:
                                recipe.formattedCookTime,
                            label: "Cook"
                        )
                    }
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
                    cornerRadius:
                        KinRadius.large
                )
            )
            .overlay(
                alignment: .trailing
            ) {
                Image(
                    systemName: "chevron.right"
                )
                .font(.caption)
                .foregroundStyle(
                    KinColors.primary
                )
                .padding(
                    .trailing,
                    KinSpacing.large
                )
            }
            .contentShape(
                RoundedRectangle(
                    cornerRadius:
                        KinRadius.large
                )
            )
            .onTapGesture {
                showingRecipeDetail = true
            }
        }
    }

    func recipeStat(
        icon: String,
        value: String,
        label: String
    ) -> some View {
        VStack(
            alignment: .leading,
            spacing: KinSpacing.xSmall
        ) {
            HStack(
                spacing: KinSpacing.xSmall
            ) {
                Image(
                    systemName: icon
                )

                Text(value)
            }
            .font(KinTypography.footnote)
            .foregroundStyle(
                KinColors.primary
            )

            Text(label)
                .font(KinTypography.footnote)
                .foregroundStyle(
                    KinColors.secondaryText
                )
        }
    }
}


// MARK: - Quantity Needed

private extension GatheringNeedDetailView {

    var dishesNeededSection: some View {
        VStack(
            alignment: .leading,
            spacing: KinSpacing.medium
        ) {
            HStack {
                VStack(
                    alignment: .leading,
                    spacing: KinSpacing.xSmall
                ) {
                    Text(
                        isStandaloneSupply
                        ? "Supplies Needed"
                        : "Dishes Needed"
                    )
                    .font(
                        KinTypography.headline
                    )
                    .foregroundStyle(
                        KinColors.primaryText
                    )

                    Text(claimStatusText)
                        .font(
                            KinTypography.footnote
                        )
                        .foregroundStyle(
                            KinColors.secondaryText
                        )
                }

                Spacer()

                Text(
                    "\(currentNeed.quantityNeeded)"
                )
                .font(
                    KinTypography.title2
                )
                .foregroundStyle(
                    KinColors.primary
                )
            }

            if isEditingNeed {
                Divider()

                HStack(
                    spacing: KinSpacing.medium
                ) {
                    Text("Quantity")
                        .font(
                            KinTypography.body
                        )
                        .foregroundStyle(
                            KinColors.primaryText
                        )

                    Spacer()

                    Button {
                        changeNeedQuantity(
                            by: -1
                        )
                    } label: {
                        Image(
                            systemName: "minus"
                        )
                        .frame(
                            width: 44,
                            height: 44
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
                        text:
                            $needQuantityText
                    )
                    .keyboardType(
                        .numberPad
                    )
                    .multilineTextAlignment(
                        .center
                    )
                    .font(
                        KinTypography.headline
                    )
                    .foregroundStyle(
                        KinColors.primaryText
                    )
                    .frame(width: 80)
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
                    .onChange(
                        of: needQuantityText
                    ) { _, newValue in
                        needQuantityText =
                            newValue.filter {
                                $0.isNumber
                            }
                    }

                    Button {
                        changeNeedQuantity(
                            by: 1
                        )
                    } label: {
                        Image(
                            systemName: "plus"
                        )
                        .frame(
                            width: 44,
                            height: 44
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

                if let needEditErrorMessage {
                    Text(
                        needEditErrorMessage
                    )
                    .font(
                        KinTypography.footnote
                    )
                    .foregroundStyle(
                        KinColors.error
                    )
                }

                HStack(
                    spacing: KinSpacing.medium
                ) {
                    Button {
                        isEditingNeed = false
                        needEditErrorMessage = nil

                        needQuantityText =
                            String(
                                currentNeed
                                    .quantityNeeded
                            )
                    } label: {
                        Text("Cancel")
                            .font(
                                KinTypography.headline
                            )
                            .foregroundStyle(
                                KinColors.primary
                            )
                            .frame(
                                maxWidth: .infinity
                            )
                            .padding(
                                .vertical,
                                KinSpacing.medium
                            )
                    }
                    .buttonStyle(.plain)

                    Button {
                        Task {
                            await saveNeedQuantity()
                        }
                    } label: {
                        Text(
                            isSavingNeed
                            ? "Saving..."
                            : "Save"
                        )
                        .font(
                            KinTypography.headline
                        )
                        .foregroundStyle(
                            Color.white
                        )
                        .frame(
                            maxWidth: .infinity
                        )
                        .padding(
                            .vertical,
                            KinSpacing.medium
                        )
                        .background(
                            KinColors.primary
                        )
                        .clipShape(
                            RoundedRectangle(
                                cornerRadius:
                                    KinRadius.medium
                            )
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(
                        isSavingNeed
                    )
                }
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
                cornerRadius:
                    KinRadius.large
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
                currentNeed.quantityNeeded -
                    claimed,
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

    func changeNeedQuantity(
        by amount: Int
    ) {
        let current =
            Int(needQuantityText) ??
            currentNeed.quantityNeeded

        needQuantityText =
            String(
                max(
                    1,
                    current + amount
                )
            )
    }

    @MainActor
    func saveNeedQuantity() async {
        guard
            let quantity =
                Int(needQuantityText),
            quantity > 0
        else {
            needEditErrorMessage =
                "Enter a valid quantity."
            return
        }

        isSavingNeed = true
        needEditErrorMessage = nil

        do {
            let updated =
                try await GatheringDishService
                    .updateNeed(
                        id: currentNeed.id,
                        name: currentNeed.name,
                        category:
                            currentNeed.category,
                        quantityNeeded:
                            quantity,
                        recipeId:
                            currentNeed.recipeId,
                        notes:
                            currentNeed.notes,
                        needs:
                            Set(
                                requirements.map {
                                    $0.need
                                }
                            ),
                        supplies:
                            Set(
                                supplies.map {
                                    $0.supply
                                }
                            )
                    )

            currentNeed = updated
            needQuantityText =
                String(
                    updated.quantityNeeded
                )

            isEditingNeed = false

        } catch {
            needEditErrorMessage =
                error.localizedDescription
        }

        isSavingNeed = false
    }
}

// MARK: - Claim Dish

private extension GatheringNeedDetailView {
    var totalClaimed: Int {
        claims.reduce(0) {
            $0 + $1.quantity
        }
    }

    var remainingQuantity: Int {
        max(
            currentNeed.quantityNeeded -
                totalClaimed,
            0
        )
    }

    var currentUserClaim: GatheringNeedClaim? {
        guard let currentUserId else {
            return nil
        }

        return claims.first {
            $0.userId == currentUserId
        }
    }

    var maximumClaimQuantity: Int {
        if let currentUserClaim {
            return currentUserClaim.quantity + remainingQuantity
        }

        return remainingQuantity
    }
    
    var claimSection: some View {
        VStack(
            alignment: .leading,
            spacing: KinSpacing.medium
        ) {
            Text("Sign Up")
                .font(KinTypography.headline)
                .foregroundStyle(
                    KinColors.primaryText
                )

            if let currentUserClaim {
                VStack(
                    spacing: KinSpacing.large
                ) {
                    HStack(
                        spacing: KinSpacing.medium
                    ) {
                        Image(
                            systemName: "checkmark.circle.fill"
                        )
                        .font(.title2)
                        .foregroundStyle(
                            KinColors.success
                        )

                        VStack(
                            alignment: .leading,
                            spacing: KinSpacing.xSmall
                        ) {
                            Text("You're bringing this")
                                .font(
                                    KinTypography.headline
                                )
                                .foregroundStyle(
                                    KinColors.primaryText
                                )

                            Text(
                                currentUserClaim.quantity == 1
                                    ? "1 dish claimed"
                                    : "\(currentUserClaim.quantity) dishes claimed"
                            )
                            .font(
                                KinTypography.footnote
                            )
                            .foregroundStyle(
                                KinColors.secondaryText
                            )
                        }

                        Spacer()
                    }

                    if isEditingClaim {
                        claimQuantityControl(
                            maximum: maximumClaimQuantity
                        )

                        Button {
                            Task {
                                await updateClaim()
                            }
                        } label: {
                            Text(
                                isClaiming
                                    ? "Saving..."
                                    : "Save Changes"
                            )
                            .font(KinTypography.headline)
                            .foregroundStyle(Color.white)
                            .frame(maxWidth: .infinity)
                            .padding(
                                .vertical,
                                KinSpacing.large
                            )
                            .background(
                                KinColors.primary
                            )
                            .clipShape(
                                RoundedRectangle(
                                    cornerRadius:
                                        KinRadius.large
                                )
                            )
                        }
                        .buttonStyle(.plain)
                        .disabled(
                            isClaiming ||
                            claimQuantity ==
                                currentUserClaim.quantity
                        )

                        Button {
                            Task {
                                await removeClaim()
                            }
                        } label: {
                            Text("Remove Claim")
                                .font(
                                    KinTypography.headline
                                )
                                .foregroundStyle(
                                    KinColors.error
                                )
                                .frame(
                                    maxWidth: .infinity
                                )
                                .padding(
                                    .vertical,
                                    KinSpacing.medium
                                )
                        }
                        .buttonStyle(.plain)
                        .disabled(isClaiming)

                        Button {
                            claimQuantity =
                                currentUserClaim.quantity

                            claimQuantityText =
                                String(
                                    currentUserClaim.quantity
                                )

                            isEditingClaim = false
                        } label: {
                            Text("Cancel")
                                .font(
                                    KinTypography.body
                                )
                                .foregroundStyle(
                                    KinColors.secondaryText
                                )
                        }
                        .buttonStyle(.plain)
                    } else {
                        Button {
                            claimQuantity =
                                currentUserClaim.quantity

                            claimQuantityText =
                                String(
                                    currentUserClaim.quantity
                                )

                            isEditingClaim = true
                        } label: {
                            Text("Edit Claim")
                                .font(
                                    KinTypography.headline
                                )
                                .foregroundStyle(
                                    KinColors.primary
                                )
                                .frame(
                                    maxWidth: .infinity
                                )
                                .padding(
                                    .vertical,
                                    KinSpacing.medium
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(KinSpacing.large)
                .background(KinColors.surface)
                .clipShape(
                    RoundedRectangle(
                        cornerRadius: KinRadius.large
                    )
                )
            } else if remainingQuantity == 0 {
                HStack(
                    spacing: KinSpacing.medium
                ) {
                    Image(
                        systemName:
                            "checkmark.circle.fill"
                    )
                    .foregroundStyle(
                        KinColors.success
                    )

                    Text("This dish is fully claimed")
                        .font(
                            KinTypography.body
                        )
                        .foregroundStyle(
                            KinColors.primaryText
                        )
                }
                .padding(KinSpacing.large)
                .frame(
                    maxWidth: .infinity,
                    alignment: .leading
                )
                .background(KinColors.surface)
                .clipShape(
                    RoundedRectangle(
                        cornerRadius:
                            KinRadius.large
                    )
                )
            } else {
                VStack(
                    spacing: KinSpacing.large
                ) {
                    if remainingQuantity > 1 {
                        VStack(
                            alignment: .leading,
                            spacing: KinSpacing.small
                        ) {
                            claimQuantityControl(
                                maximum: remainingQuantity
                            )

                            Text(
                                claimQuantity == 1
                                    ? "Bringing 1 of \(remainingQuantity) needed"
                                    : "Bringing \(claimQuantity) of \(remainingQuantity) needed"
                            )
                            .font(
                                KinTypography.footnote
                            )
                            .foregroundStyle(
                                KinColors.secondaryText
                            )
                        }
                    }

                    Button {
                        Task {
                            await claimDish()
                        }
                    } label: {
                        HStack {
                            if isClaiming {
                                ProgressView()
                                    .tint(.white)
                            }

                            Text(
                                isClaiming
                                    ? "Claiming..."
                                    : "I'll Bring This"
                            )
                        }
                        .font(KinTypography.headline)
                        .foregroundStyle(Color.white)
                        .frame(
                            maxWidth: .infinity
                        )
                        .padding(
                            .vertical,
                            KinSpacing.large
                        )
                        .background(
                            KinColors.primary
                        )
                        .clipShape(
                            RoundedRectangle(
                                cornerRadius:
                                    KinRadius.large
                            )
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(isClaiming)
                }
                .padding(KinSpacing.large)
                .background(KinColors.surface)
                .clipShape(
                    RoundedRectangle(
                        cornerRadius:
                            KinRadius.large
                    )
                )
            }

            if let claimErrorMessage {
                Text(claimErrorMessage)
                    .font(
                        KinTypography.footnote
                    )
                    .foregroundStyle(
                        KinColors.error
                    )
            }
        }
    }
    
    func claimQuantityControl(
        maximum: Int
    ) -> some View {
        HStack(
            spacing: KinSpacing.medium
        ) {
            Text(
                isStandaloneSupply
                ? "Quantity"
                : "Dishes"
            )
            .font(
                KinTypography.body
            )
            .foregroundStyle(
                KinColors.primaryText
            )

            Spacer()

            Button {
                let current =
                    validatedClaimQuantity(
                        maximum: maximum
                    )

                let newValue =
                    max(
                        1,
                        current - 1
                    )

                claimQuantity =
                    newValue

                claimQuantityText =
                    String(newValue)

            } label: {
                Image(
                    systemName: "minus"
                )
                .frame(
                    width: 44,
                    height: 44
                )
                .background(
                    KinColors.background
                )
                .clipShape(
                    Circle()
                )
            }
            .buttonStyle(.plain)
            .disabled(
                claimQuantity <= 1
            )

            TextField(
                "1",
                text: $claimQuantityText
            )
            .keyboardType(
                .numberPad
            )
            .multilineTextAlignment(
                .center
            )
            .font(
                KinTypography.headline
            )
            .foregroundStyle(
                KinColors.primaryText
            )
            .frame(width: 80)
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
            .onChange(
                of: claimQuantityText
            ) { _, newValue in
                let digits =
                    newValue.filter {
                        $0.isNumber
                    }

                claimQuantityText =
                    digits

                if let value = Int(digits) {
                    claimQuantity =
                        min(
                            max(1, value),
                            maximum
                        )
                }
            }

            Button {
                let current =
                    validatedClaimQuantity(
                        maximum: maximum
                    )

                let newValue =
                    min(
                        maximum,
                        current + 1
                    )

                claimQuantity =
                    newValue

                claimQuantityText =
                    String(newValue)

            } label: {
                Image(
                    systemName: "plus"
                )
                .frame(
                    width: 44,
                    height: 44
                )
                .background(
                    KinColors.background
                )
                .clipShape(
                    Circle()
                )
            }
            .buttonStyle(.plain)
            .disabled(
                claimQuantity >= maximum
            )
        }
    }

    func validatedClaimQuantity(
        maximum: Int
    ) -> Int {
        let typed =
            Int(claimQuantityText) ??
            claimQuantity

        return min(
            max(1, typed),
            maximum
        )
    }

    @MainActor
    func claimDish() async {
        guard currentUserClaim == nil else {
            return
        }

        guard remainingQuantity > 0 else {
            return
        }

        claimQuantity =
            validatedClaimQuantity(
                maximum:
                    currentUserClaim == nil
                    ? remainingQuantity
                    : maximumClaimQuantity
            )

        claimQuantityText =
            String(claimQuantity)
        
        isClaiming = true
        claimErrorMessage = nil

        do {
            _ =
                try await GatheringDishService
                    .claimNeed(
                        id: need.id,
                        quantity: claimQuantity
                    )

            claims =
                try await GatheringDishService
                    .fetchClaims(
                        needId: need.id
                    )

            claimQuantity = 1
            claimQuantityText = "1"
        } catch {
            claimErrorMessage =
                error.localizedDescription
        }

        isClaiming = false
    }
    
    @MainActor
    func updateClaim() async {
        guard currentUserClaim != nil else {
            return
        }

        claimQuantity =
            validatedClaimQuantity(
                maximum:
                    currentUserClaim == nil
                    ? remainingQuantity
                    : maximumClaimQuantity
            )

        claimQuantityText =
            String(claimQuantity)
        
        isClaiming = true
        claimErrorMessage = nil

        do {
            _ =
                try await GatheringDishService
                    .claimNeed(
                        id: need.id,
                        quantity: claimQuantity
                    )

            claims =
                try await GatheringDishService
                    .fetchClaims(
                        needId: need.id
                    )

            isEditingClaim = false
        } catch {
            claimErrorMessage =
                error.localizedDescription
        }

        isClaiming = false
    }
    
    @MainActor
    func removeClaim() async {
        guard currentUserClaim != nil else {
            return
        }

        isClaiming = true
        claimErrorMessage = nil

        do {
            _ =
                try await GatheringDishService
                    .unclaimNeed(
                        id: need.id
                    )

            claims =
                try await GatheringDishService
                    .fetchClaims(
                        needId: need.id
                    )
        } catch {
            claimErrorMessage =
                error.localizedDescription
        }

        isClaiming = false
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
                .foregroundStyle(
                    KinColors.primaryText
                )

            VStack(
                spacing: KinSpacing.small
            ) {
                ForEach(
                    requirements,
                    id: \.need
                ) { requirement in
                    requirementRow(requirement)
                }
            }
        }
    }

    func requirementRow(
        _ requirement: GatheringNeedRequirement
    ) -> some View {
        HStack(
            alignment: .top,
            spacing: KinSpacing.medium
        ) {
            Image(
                systemName:
                    requirement.need == .other
                    ? "wrench.and.screwdriver"
                    : "checkmark.circle.fill"
            )
            .font(KinTypography.body)
            .foregroundStyle(
                KinColors.primary
            )

            VStack(
                alignment: .leading,
                spacing: KinSpacing.xSmall
            ) {
                Text(
                    requirement.need.displayName
                )
                .font(KinTypography.body)
                .foregroundStyle(
                    KinColors.primaryText
                )

                if let description =
                    requirement.description?
                        .trimmingCharacters(
                            in: .whitespacesAndNewlines
                        ),
                   !description.isEmpty {
                    Text(description)
                        .font(
                            KinTypography.footnote
                        )
                        .foregroundStyle(
                            KinColors.secondaryText
                        )
                }
            }

            Spacer()
        }
        .padding(KinSpacing.large)
        .frame(
            maxWidth: .infinity,
            alignment: .leading
        )
        .background(
            KinColors.surface
        )
        .clipShape(
            RoundedRectangle(
                cornerRadius: KinRadius.medium
            )
        )
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
            
            async let userRequest =
                SupabaseManager.client
                    .auth
                    .session
                    .user

            let loadedRecipe: Recipe?

            if let recipeId = need.recipeId {
                loadedRecipe =
                    try? await RecipeService
                        .fetchRecipe(
                            id: recipeId
                        )
            } else {
                loadedRecipe = nil
            }

            let (
                loadedRequirements,
                loadedSupplies,
                loadedClaims,
                currentUser
            ) = try await (
                requirementsRequest,
                suppliesRequest,
                claimsRequest,
                userRequest
            )

            requirements =
                loadedRequirements

            supplies =
                loadedSupplies

            claims =
                loadedClaims
            
            currentUserId = currentUser.id

            recipe =
                loadedRecipe
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
            ),
            isHost: false
        )
    }
}

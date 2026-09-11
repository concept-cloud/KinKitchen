//
//  AddDishView.swift
//  KinKitchen
//
//  Created by Greg Hudler on 9/10/26.
//
import SwiftUI

struct AddDishView: View {
    @Environment(\.dismiss) private var dismiss

    let gatheringId: UUID

    @State private var dishName = ""
    @State private var selectedCategory: DishCategory = .side
    @State private var servings = 1
    @State private var notes = ""
    @State private var selectedNeeds: Set<DishNeed> = []
    @State private var selectedSupplies: Set<DishSupply> = []

    @State private var selectedRecipe: Recipe?
    @State private var isShowingRecipePicker = false
    @State private var isSuppliesExpanded = false
    @State private var isSaving = false
    @State private var errorMessage: String?

    var body: some View {
        ZStack {
            KinColors.background
                .ignoresSafeArea()

            ScrollView {
                VStack(
                    alignment: .leading,
                    spacing: KinSpacing.xLarge
                ) {
                    header
                    form

                    if let errorMessage {
                        Text(errorMessage)
                            .font(KinTypography.body)
                            .foregroundStyle(KinColors.error)
                    }

                    addDishButton
                }
                .padding(KinSpacing.large)
            }
        }
        .navigationBarHidden(true)
        .sheet(
            isPresented: $isShowingRecipePicker
        ) {
            RecipeSelectionView(
                selectedRecipe: $selectedRecipe
            )
        }
    }
}

// MARK: - Header

private extension AddDishView {
    var header: some View {
        ZStack {
            Text("Add Dish")
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

                Button("Cancel") {
                    dismiss()
                }
                .font(KinTypography.footnote)
                .foregroundStyle(KinColors.primaryText)
                .padding(
                    .horizontal,
                    KinSpacing.large
                )
                .frame(height: 40)
                .background(KinColors.surface)
                .clipShape(Capsule())
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - Form

private extension AddDishView {
    var form: some View {
        VStack(
            alignment: .leading,
            spacing: KinSpacing.xLarge
        ) {
            dishNameSection
            recipeSection
            categorySection
            dishNeedsSection
            dishSuppliesSection
            notesSection
            servingsSection
        }
    }
}

// MARK: - Dish Name

private extension AddDishView {
    var dishNameSection: some View {
        VStack(
            alignment: .leading,
            spacing: KinSpacing.small
        ) {
            fieldLabel("Dish Name")

            KinTextField(
                title: "Macaroni & Cheese",
                text: $dishName
            )
        }
    }
}

// MARK: - Recipe

private extension AddDishView {
    var recipeSection: some View {
        VStack(
            alignment: .leading,
            spacing: KinSpacing.small
        ) {
            fieldLabel("Recipe")

            Button {
                isShowingRecipePicker = true
            } label: {
                HStack(
                    spacing: KinSpacing.medium
                ) {
                    Image(
                        systemName:
                            "book.closed.fill"
                    )
                    .foregroundStyle(
                        KinColors.primary
                    )

                    VStack(
                        alignment: .leading,
                        spacing: KinSpacing.xSmall
                    ) {
                        Text(
                            selectedRecipe?.name
                            ?? "Select Recipe"
                        )
                        .font(
                            KinTypography.body
                        )
                        .foregroundStyle(
                            KinColors.primaryText
                        )

                        if selectedRecipe != nil {
                            Text(
                                "Recipe selected"
                            )
                            .font(
                                KinTypography.footnote
                            )
                            .foregroundStyle(
                                KinColors.secondaryText
                            )
                        }
                    }

                    Spacer()

                    Image(
                        systemName:
                            "chevron.right"
                    )
                    .font(
                        KinTypography.footnote
                    )
                    .foregroundStyle(
                        KinColors.primary
                    )
                }
                .padding(KinSpacing.large)
                .background(
                    KinColors.surface
                )
                .clipShape(
                    RoundedRectangle(
                        cornerRadius:
                            KinRadius.medium
                    )
                )
            }
            .buttonStyle(.plain)
        }
    }
}

// MARK: - Category

private extension AddDishView {
    var categorySection: some View {
        VStack(
            alignment: .leading,
            spacing: KinSpacing.small
        ) {
            fieldLabel("Category")

            Menu {
                ForEach(
                    DishCategory.allCases,
                    id: \.self
                ) { category in
                    Button {
                        selectedCategory =
                            category
                    } label: {
                        if selectedCategory ==
                            category {
                            Label(
                                category.displayName,
                                systemImage:
                                    "checkmark"
                            )
                        } else {
                            Text(
                                category.displayName
                            )
                        }
                    }
                }
            } label: {
                HStack {
                    Text(
                        selectedCategory
                            .displayName
                    )
                    .font(KinTypography.body)
                    .foregroundStyle(
                        KinColors.primaryText
                    )

                    Spacer()

                    Image(
                        systemName:
                            "chevron.down"
                    )
                    .foregroundStyle(
                        KinColors.primary
                    )
                }
                .padding(KinSpacing.large)
                .background(
                    KinColors.surface
                )
                .clipShape(
                    RoundedRectangle(
                        cornerRadius:
                            KinRadius.medium
                    )
                )
            }
            .buttonStyle(.plain)
        }
    }
}

// MARK: - Dish Needs

private extension AddDishView {
    var dishNeedsSection: some View {
        VStack(
            alignment: .leading,
            spacing: KinSpacing.medium
        ) {
            fieldLabel("Dish Needs")

            LazyVGrid(
                columns: [
                    GridItem(
                        .adaptive(
                            minimum: 105
                        )
                    )
                ],
                spacing: KinSpacing.small
            ) {
                ForEach(
                    DishNeed.allCases,
                    id: \.self
                ) { need in
                    needButton(need)
                }
            }
        }
    }

    func needButton(
        _ need: DishNeed
    ) -> some View {
        let isSelected =
            selectedNeeds.contains(need)

        return Button {
            if isSelected {
                selectedNeeds.remove(need)
            } else {
                selectedNeeds.insert(need)
            }
        } label: {
            Text(need.displayName)
                .font(
                    KinTypography.footnote
                )
                .foregroundStyle(
                    isSelected
                    ? Color.white
                    : KinColors.primaryText
                )
                .frame(
                    maxWidth: .infinity
                )
                .padding(
                    .vertical,
                    KinSpacing.medium
                )
                .background(
                    isSelected
                    ? KinColors.primary
                    : KinColors.surface
                )
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Dish Supplies

private extension AddDishView {
    var dishSuppliesSection: some View {
        VStack(
            alignment: .leading,
            spacing: KinSpacing.small
        ) {
            fieldLabel("Dish Supplies")

            Button {
                withAnimation {
                    isSuppliesExpanded
                        .toggle()
                }
            } label: {
                HStack(
                    spacing: KinSpacing.medium
                ) {
                    Image(
                        systemName:
                            "takeoutbag.and.cup.and.straw.fill"
                    )
                    .foregroundStyle(
                        KinColors.primary
                    )

                    Text(suppliesSummary)
                        .font(
                            KinTypography.body
                        )
                        .foregroundStyle(
                            KinColors.primaryText
                        )

                    Spacer()

                    Image(
                        systemName:
                            isSuppliesExpanded
                            ? "chevron.up"
                            : "chevron.right"
                    )
                    .foregroundStyle(
                        KinColors.primary
                    )
                }
                .padding(KinSpacing.large)
                .background(
                    KinColors.surface
                )
                .clipShape(
                    RoundedRectangle(
                        cornerRadius:
                            KinRadius.medium
                    )
                )
            }
            .buttonStyle(.plain)

            if isSuppliesExpanded {
                VStack(
                    spacing: 0
                ) {
                    ForEach(
                        DishSupply.allCases,
                        id: \.self
                    ) { supply in
                        supplyRow(supply)
                    }
                }
                .background(
                    KinColors.surface
                )
                .clipShape(
                    RoundedRectangle(
                        cornerRadius:
                            KinRadius.medium
                    )
                )
            }
        }
    }

    func supplyRow(
        _ supply: DishSupply
    ) -> some View {
        Button {
            if selectedSupplies
                .contains(supply) {
                selectedSupplies
                    .remove(supply)
            } else {
                selectedSupplies
                    .insert(supply)
            }
        } label: {
            HStack {
                Text(supply.displayName)
                    .font(
                        KinTypography.body
                    )
                    .foregroundStyle(
                        KinColors.primaryText
                    )

                Spacer()

                Image(
                    systemName:
                        selectedSupplies
                            .contains(supply)
                        ? "checkmark.circle.fill"
                        : "circle"
                )
                .foregroundStyle(
                    selectedSupplies
                        .contains(supply)
                    ? KinColors.primary
                    : KinColors.secondaryText
                )
            }
            .padding(KinSpacing.large)
        }
        .buttonStyle(.plain)
    }

    var suppliesSummary: String {
        if selectedSupplies.isEmpty {
            return "Select Supplies"
        }

        if selectedSupplies.count == 1,
           let supply =
            selectedSupplies.first {
            return supply.displayName
        }

        return "\(selectedSupplies.count) Supplies Selected"
    }
}

// MARK: - Notes

private extension AddDishView {
    var notesSection: some View {
        VStack(
            alignment: .leading,
            spacing: KinSpacing.small
        ) {
            fieldLabel("Notes")

            KinTextEditor(
                text: $notes
            )
        }
    }
}

// MARK: - Servings

private extension AddDishView {
    var servingsSection: some View {
        HStack {
            fieldLabel("Servings")

            Spacer()

            HStack(
                spacing: KinSpacing.large
            ) {
                Button {
                    if servings > 1 {
                        servings -= 1
                    }
                } label: {
                    Image(
                        systemName: "minus"
                    )
                    .frame(
                        width: 30,
                        height: 30
                    )
                }
                .buttonStyle(.plain)

                Text("\(servings)")
                    .font(
                        KinTypography.body
                    )
                    .foregroundStyle(
                        KinColors.primaryText
                    )
                    .frame(minWidth: 28)

                Button {
                    servings += 1
                } label: {
                    Image(
                        systemName: "plus"
                    )
                    .frame(
                        width: 30,
                        height: 30
                    )
                }
                .buttonStyle(.plain)
            }
            .foregroundStyle(
                KinColors.primaryText
            )
            .padding(KinSpacing.small)
            .background(
                KinColors.surface
            )
            .clipShape(
                RoundedRectangle(
                    cornerRadius:
                        KinRadius.medium
                )
            )
        }
    }
}

// MARK: - Label

private extension AddDishView {
    func fieldLabel(
        _ title: String
    ) -> some View {
        Text(title)
            .font(KinTypography.headline)
            .foregroundStyle(
                KinColors.primaryText
            )
    }
}

// MARK: - Add Dish Button

private extension AddDishView {
    var addDishButton: some View {
        KinPrimaryButton(
            title:
                isSaving
                ? "Adding..."
                : "Add Dish"
        ) {
            Task {
                await addDish()
            }
        }
        .disabled(isSaving)
        .opacity(
            isSaving
            ? 0.6
            : 1
        )
    }
}

// MARK: - Add Dish

private extension AddDishView {
    @MainActor
    func addDish() async {
        errorMessage = nil

        let cleanName =
            dishName.trimmingCharacters(
                in:
                    .whitespacesAndNewlines
            )

        guard !cleanName.isEmpty else {
            errorMessage =
                "Please enter a dish name."
            return
        }

        guard servings > 0 else {
            errorMessage =
                "Servings must be at least 1."
            return
        }

        isSaving = true

        defer {
            isSaving = false
        }

        do {
            _ =
                try await GatheringDishService
                    .createNeed(
                        gatheringId:
                            gatheringId,
                        name:
                            cleanName,
                        category:
                            selectedCategory,
                        quantityNeeded:
                            servings,
                        recipeId:
                            selectedRecipe?.id,
                        notes:
                            notes,
                        needs:
                            selectedNeeds,
                        supplies:
                            selectedSupplies
                    )

            dismiss()
        } catch {
            errorMessage =
                error.localizedDescription
        }
    }
}

// MARK: - Recipe Selection View

private struct RecipeSelectionView:
    View {

    @Environment(\.dismiss)
    private var dismiss

    @Binding
    var selectedRecipe: Recipe?

    @State
    private var recipes: [Recipe] = []

    @State
    private var isLoading = true

    @State
    private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ZStack {
                KinColors.background
                    .ignoresSafeArea()

                content
            }
            .navigationTitle(
                "Select Recipe"
            )
            .navigationBarTitleDisplayMode(
                .inline
            )
            .toolbar {
                ToolbarItem(
                    placement:
                        .topBarLeading
                ) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .task {
                await loadRecipes()
            }
        }
    }
}

// MARK: - Recipe Selection Content

private extension RecipeSelectionView {
    @ViewBuilder
    var content: some View {
        if isLoading {
            ProgressView()
                .tint(
                    KinColors.primary
                )
        } else if let errorMessage {
            VStack(
                spacing: KinSpacing.large
            ) {
                Image(
                    systemName:
                        "exclamationmark.triangle.fill"
                )
                .font(.largeTitle)
                .foregroundStyle(
                    KinColors.error
                )

                Text(
                    "Unable to Load Recipes"
                )
                .font(
                    KinTypography.headline
                )
                .foregroundStyle(
                    KinColors.primaryText
                )

                Text(errorMessage)
                    .font(
                        KinTypography.body
                    )
                    .foregroundStyle(
                        KinColors.secondaryText
                    )
                    .multilineTextAlignment(
                        .center
                    )

                Button("Try Again") {
                    Task {
                        await loadRecipes()
                    }
                }
                .font(
                    KinTypography.body
                )
                .foregroundStyle(
                    KinColors.primary
                )
            }
            .padding(KinSpacing.xLarge)
        } else if recipes.isEmpty {
            VStack(
                spacing: KinSpacing.large
            ) {
                Image(
                    systemName:
                        "book.closed"
                )
                .font(.largeTitle)
                .foregroundStyle(
                    KinColors.primary
                )

                Text("No Recipes Yet")
                    .font(
                        KinTypography.headline
                    )
                    .foregroundStyle(
                        KinColors.primaryText
                    )

                Text(
                    "Create a recipe first, or continue without selecting one."
                )
                .font(
                    KinTypography.body
                )
                .foregroundStyle(
                    KinColors.secondaryText
                )
                .multilineTextAlignment(
                    .center
                )
            }
            .padding(KinSpacing.xLarge)
        } else {
            recipeList
        }
    }
}

// MARK: - Recipe List

private extension RecipeSelectionView {
    var recipeList: some View {
        ScrollView {
            LazyVStack(
                spacing: KinSpacing.medium
            ) {
                if selectedRecipe != nil {
                    noRecipeButton
                }

                ForEach(recipes) { recipe in
                    recipeButton(recipe)
                }
            }
            .padding(KinSpacing.large)
        }
    }

    var noRecipeButton: some View {
        Button {
            selectedRecipe = nil
            dismiss()
        } label: {
            HStack(
                spacing: KinSpacing.medium
            ) {
                Image(
                    systemName:
                        "xmark.circle"
                )
                .foregroundStyle(
                    KinColors.secondaryText
                )

                Text("No Recipe")
                    .font(
                        KinTypography.body
                    )
                    .foregroundStyle(
                        KinColors.primaryText
                    )

                Spacer()
            }
            .padding(KinSpacing.large)
            .background(
                KinColors.surface
            )
            .clipShape(
                RoundedRectangle(
                    cornerRadius:
                        KinRadius.medium
                )
            )
        }
        .buttonStyle(.plain)
    }

    func recipeButton(
        _ recipe: Recipe
    ) -> some View {
        Button {
            selectedRecipe = recipe
            dismiss()
        } label: {
            HStack(
                spacing: KinSpacing.medium
            ) {
                Image(
                    systemName:
                        "book.closed.fill"
                )
                .font(.title3)
                .foregroundStyle(
                    KinColors.primary
                )

                VStack(
                    alignment: .leading,
                    spacing: KinSpacing.xSmall
                ) {
                    Text(recipe.name)
                        .font(
                            KinTypography.body
                        )
                        .foregroundStyle(
                            KinColors.primaryText
                        )
                        .multilineTextAlignment(
                            .leading
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

                    if let servings =
                        recipe.servings {
                        Text(
                            "\(servings) servings"
                        )
                        .font(
                            KinTypography.footnote
                        )
                        .foregroundStyle(
                            KinColors.secondaryText
                        )
                    }
                }

                Spacer()

                if selectedRecipe?.id ==
                    recipe.id {
                    Image(
                        systemName:
                            "checkmark.circle.fill"
                    )
                    .foregroundStyle(
                        KinColors.primary
                    )
                } else {
                    Image(
                        systemName:
                            "chevron.right"
                    )
                    .font(
                        KinTypography.footnote
                    )
                    .foregroundStyle(
                        KinColors.secondaryText
                    )
                }
            }
            .padding(KinSpacing.large)
            .background(
                KinColors.surface
            )
            .clipShape(
                RoundedRectangle(
                    cornerRadius:
                        KinRadius.medium
                )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Load Recipes

private extension RecipeSelectionView {
    @MainActor
    func loadRecipes() async {
        isLoading = true
        errorMessage = nil

        do {
            recipes =
                try await RecipeService
                    .fetchCurrentUserRecipes()
        } catch {
            errorMessage =
                error.localizedDescription
        }

        isLoading = false
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        AddDishView(
            gatheringId: UUID()
        )
    }
}

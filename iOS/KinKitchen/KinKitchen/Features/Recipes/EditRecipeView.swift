//
//  EditRecipeView.swift
//  KinKitchen
//
//  Created by Greg Hudler on 9/7/26.
//

import SwiftUI
import UniformTypeIdentifiers

struct EditRecipeView: View {

    // MARK: - Environment

    @Environment(\.dismiss) private var dismiss


    // MARK: - Input

    let recipeId: UUID
    let onDeleted: () -> Void
    
    init(
        recipeId: UUID,
        onDeleted: @escaping () -> Void = {}
    ) {
        self.recipeId = recipeId
        self.onDeleted = onDeleted
    }


    // MARK: - Recipe State

    @State private var recipeName = ""
    @State private var recipeDescription = ""
    @State private var category = ""

    @State private var servings = ""
    @State private var prepTime = ""
    @State private var cookTime = ""

    @State private var ingredients: [EditableIngredient] = []
    @State private var instructions: [EditableInstruction] = []
    
    // MARK: - Drag State

    @State private var draggedIngredientID: UUID?
    @State private var ingredientDropTargetID: UUID?
    @State private var ingredientDropPosition: RecipeDropPosition?
    @State private var ingredientEndDropTargeted = false
    
    @State private var draggedInstructionID: UUID?
    @State private var instructionDropTargetID: UUID?
    @State private var instructionDropPosition: RecipeDropPosition?
    @State private var instructionEndDropTargeted = false


    // MARK: - View State

    @State private var isLoading = true
    @State private var isSaving = false
    @State private var isDeleting = false

    @State private var errorMessage: String?
    @State private var showingDeleteConfirmation = false
    
    // MARK: - Body

    var body: some View {
        ZStack {
            KinColors.background
                .ignoresSafeArea()

            if isLoading {
                ProgressView("Loading recipe...")
                    .foregroundStyle(
                        KinColors.primaryText
                    )

            } else if let errorMessage {
                errorState(errorMessage)

            } else {
                editContent
            }
        }
        .navigationBarHidden(true)
        .task {
            await loadRecipe()
        }
        .confirmationDialog(
            "Delete Recipe?",
            isPresented: $showingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button(
                "Delete Recipe",
                role: .destructive
            ) {
                Task {
                    await deleteRecipe()
                }
            }

            Button(
                "Cancel",
                role: .cancel
            ) {}
        } message: {
            Text(
                "This permanently deletes this recipe. This action cannot be undone."
            )
        }
    }


    // MARK: - Edit Content

    private var editContent: some View {
        VStack(spacing: 0) {
            header

            ScrollView {
                VStack(
                    alignment: .leading,
                    spacing: KinSpacing.xLarge
                ) {
                    recipeDetailsSection

                    ingredientsSection

                    instructionsSection

                    saveButton

                    deleteButton
                }
                .padding(KinSpacing.large)
            }
            .scrollDismissesKeyboard(.interactively)
        }
    }


    // MARK: - Header

    private var header: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(
                    systemName: "chevron.left"
                )
                .font(.title2)
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
                .clipShape(Circle())
            }
            .buttonStyle(.plain)

            Spacer()

            Text("Edit Recipe")
                .font(KinTypography.title3)
                .foregroundStyle(
                    KinColors.primaryText
                )

            Spacer()

            Color.clear
                .frame(
                    width: 48,
                    height: 48
                )
        }
        .padding(
            .horizontal,
            KinSpacing.large
        )
        .padding(
            .vertical,
            KinSpacing.medium
        )
        .background(
            KinColors.background
        )
        .overlay(
            alignment: .bottom
        ) {
            Divider()
        }
    }


    // MARK: - Recipe Details

    private var recipeDetailsSection: some View {
        VStack(
            alignment: .leading,
            spacing: KinSpacing.medium
        ) {
            KinSectionHeader(
                title: "Recipe Details"
            )

            fieldCard {
                VStack(
                    alignment: .leading,
                    spacing: KinSpacing.medium
                ) {
                    fieldLabel("Recipe Name")

                    TextField(
                        "Recipe name",
                        text: $recipeName
                    )
                    .textInputAutocapitalization(
                        .words
                    )
                    .submitLabel(.next)

                    Divider()

                    fieldLabel("Description")

                    TextField(
                        "Description",
                        text: $recipeDescription,
                        axis: .vertical
                    )
                    .lineLimit(3...6)
                    .submitLabel(.next)

                    Divider()

                    fieldLabel("Category")

                    TextField(
                        "Category",
                        text: $category
                    )
                    .textInputAutocapitalization(
                        .words
                    )
                    .submitLabel(.next)
                }
            }

            HStack(
                spacing: KinSpacing.medium
            ) {
                numberField(
                    title: "Servings",
                    placeholder: "4",
                    text: $servings
                )

                numberField(
                    title: "Prep",
                    placeholder: "15",
                    text: $prepTime
                )

                numberField(
                    title: "Cook",
                    placeholder: "30",
                    text: $cookTime
                )
            }
        }
    }


    // MARK: - Ingredients

    private var ingredientsSection: some View {
        VStack(
            alignment: .leading,
            spacing: KinSpacing.medium
        ) {
            HStack {
                KinSectionHeader(
                    title: "Ingredients"
                )

                Spacer()

                Button {
                    addIngredient()
                } label: {
                    Label(
                        "Add",
                        systemImage: "plus"
                    )
                    .font(KinTypography.button)
                    .foregroundStyle(
                        KinColors.primary
                    )
                }
                .buttonStyle(.plain)
            }

            if ingredients.isEmpty {
                emptySection(
                    icon: "basket",
                    title: "No Ingredients",
                    message:
                        "Add ingredients to this recipe."
                )
            } else {
                ForEach(ingredients) { ingredient in
                    if let index = ingredients.firstIndex(
                        where: {
                            $0.id == ingredient.id
                        }
                    ) {
                        ingredientRow(
                            index: index
                        )
                        .id(ingredient.id)
                    }
                }

                // MARK: - Bottom Drop Zone
                Rectangle()
                    .fill(
                        ingredientEndDropTargeted
                            ? KinColors.error
                            : Color.clear
                    )
                    .frame(height: 6)
                    .contentShape(Rectangle())
                    .dropDestination(
                        for: IngredientDragItem.self
                    ) { items, _ in

                        guard
                            let draggedItem = items.first,
                            let sourceIndex =
                                ingredients.firstIndex(
                                    where: {
                                        $0.id == draggedItem.id
                                    }
                                )
                        else {
                            clearIngredientDragState()
                            return false
                        }

                        withAnimation {
                            let moved =
                                ingredients.remove(
                                    at: sourceIndex
                                )

                            ingredients.append(
                                moved
                            )
                        }

                        ingredientEndDropTargeted = false
                        clearIngredientDragState()

                        return true

                    } isTargeted: { targeted in
                        ingredientEndDropTargeted =
                            targeted
                    }
            }
        }
    }


    private func ingredientCardPreview(
        _ ingredient: EditableIngredient
    ) -> some View {

        HStack(
            spacing: KinSpacing.small
        ) {
            Text(
                ingredient.quantity.isEmpty
                    ? "Qty"
                    : ingredient.quantity
            )
            .frame(width: 65)

            Text(
                ingredient.unit.isEmpty
                    ? "Unit"
                    : ingredient.unit
            )
            .frame(width: 75)

            Text(
                ingredient.name.isEmpty
                    ? "Ingredient"
                    : ingredient.name
            )
            .lineLimit(1)

            Spacer()

            Image(
                systemName:
                    "line.3.horizontal"
            )
        }
        .font(KinTypography.body)
        .foregroundStyle(
            KinColors.primaryText
        )
        .padding(KinSpacing.medium)
        .frame(width: 330)
        .background(KinColors.surface)
        .clipShape(
            RoundedRectangle(
                cornerRadius:
                    KinRadius.medium
            )
        )
        .shadow(radius: 8)
    }


    private func moveIngredient(
        draggedID: UUID,
        targetID: UUID,
        position: RecipeDropPosition
    ) {
        guard
            draggedID != targetID,
            let sourceIndex =
                ingredients.firstIndex(
                    where: {
                        $0.id == draggedID
                    }
                ),
            let originalTargetIndex =
                ingredients.firstIndex(
                    where: {
                        $0.id == targetID
                    }
                )
        else {
            return
        }

        withAnimation {
            let moved =
                ingredients.remove(
                    at: sourceIndex
                )

            var destinationIndex =
                originalTargetIndex

            if sourceIndex <
                originalTargetIndex {

                destinationIndex -= 1
            }

            if position == .below {
                destinationIndex += 1
            }

            destinationIndex =
                min(
                    max(
                        destinationIndex,
                        0
                    ),
                    ingredients.count
                )

            ingredients.insert(
                moved,
                at: destinationIndex
            )
        }
    }


    private func clearIngredientDragState() {
        draggedIngredientID = nil
        ingredientDropTargetID = nil
        ingredientDropPosition = nil
    }
    
    
   // MARK: IngriedientRow
    
    private func ingredientRow(
        index: Int
    ) -> some View {

        let ingredient = ingredients[index]

        return VStack(
            spacing: KinSpacing.small
        ) {
            HStack(
                spacing: KinSpacing.small
            ) {
                TextField(
                    "Qty",
                    text: $ingredients[index].quantity
                )
                .keyboardType(.numbersAndPunctuation)
                .submitLabel(.next)
                .frame(width: 65)

                TextField(
                    "Unit",
                    text: $ingredients[index].unit
                )
                .submitLabel(.next)
                .frame(width: 75)

                TextField(
                    "Ingredient",
                    text: $ingredients[index].name
                )
                .textInputAutocapitalization(.words)
                .submitLabel(.next)

                Image(systemName: "line.3.horizontal")
                    .font(.title3)
                    .foregroundStyle(
                        KinColors.secondaryText
                    )
                    .frame(width: 40, height: 44)
            }
            .font(KinTypography.body)
            .foregroundStyle(
                KinColors.primaryText
            )

            if ingredients.count > 1 {
                HStack {
                    Spacer()

                    Button {
                        ingredients.remove(at: index)
                    } label: {
                        Label(
                            "Remove",
                            systemImage: "trash"
                        )
                        .font(KinTypography.caption)
                        .foregroundStyle(
                            KinColors.error
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(KinSpacing.medium)
        .background(KinColors.surface)
        .clipShape(
            RoundedRectangle(
                cornerRadius: KinRadius.medium
            )
        )
        .contentShape(
            Rectangle(),
            eoFill: false
        )
        .draggable(
            IngredientDragItem(
                id: ingredient.id
            )
        ) {
            ingredientCardPreview(
                ingredient
            )
            .onAppear {
                draggedIngredientID = ingredient.id
                dismissKeyboard()
            }
        }
        .overlay(
            alignment:
                ingredientDropPosition == .below
                    ? .bottom
                    : .top
        ) {
            if ingredientDropTargetID == ingredient.id,
               draggedIngredientID != ingredient.id {

                Rectangle()
                    .fill(KinColors.error)
                    .frame(height: 3)
                    .offset(
                        y:
                            ingredientDropPosition == .below
                                ? 6
                                : -6
                    )
            }
        }
        .dropDestination(
            for: IngredientDragItem.self
        ) { items, location in

            guard let draggedItem = items.first
            else {
                clearIngredientDragState()
                return false
            }

            let position: RecipeDropPosition =
                location.y > 44
                    ? .below
                    : .above

            moveIngredient(
                draggedID: draggedItem.id,
                targetID: ingredient.id,
                position: position
            )

            clearIngredientDragState()

            return true

        } isTargeted: { targeted in

            if targeted {
                ingredientDropTargetID =
                    ingredient.id

            } else if ingredientDropTargetID ==
                        ingredient.id {

                ingredientDropTargetID = nil
                ingredientDropPosition = nil
            }
        }
        .onDrop(
            of: [.kinKitchenIngredient],
            delegate:
                IngredientHoverDropDelegate(
                    targetID: ingredient.id,
                    onDragLocationChanged: { _ in },
                    draggedID: $draggedIngredientID,
                    targetIDBinding: $ingredientDropTargetID,
                    position: $ingredientDropPosition
                )
        )
    }

    // MARK: - Instructions

    private var instructionsSection: some View {
        VStack(
            alignment: .leading,
            spacing: KinSpacing.medium
        ) {
            HStack {
                KinSectionHeader(
                    title: "Instructions"
                )

                Spacer()

                Button {
                    addInstruction()
                } label: {
                    Label(
                        "Add",
                        systemImage: "plus"
                    )
                    .font(KinTypography.button)
                    .foregroundStyle(
                        KinColors.primary
                    )
                }
                .buttonStyle(.plain)
            }

            if instructions.isEmpty {
                emptySection(
                    icon: "list.number",
                    title: "No Instructions",
                    message:
                        "Add preparation steps to this recipe."
                )
            } else {

                ForEach(instructions) { instruction in
                    if let index =
                        instructions.firstIndex(
                            where: {
                                $0.id == instruction.id
                            }
                        ) {

                        instructionRow(
                            index: index
                        )
                        .id(instruction.id)
                    }
                }

                // MARK: Bottom Drop Zone
                Rectangle()
                    .fill(
                        instructionEndDropTargeted
                            ? KinColors.error
                            : Color.clear
                    )
                    .frame(height: 6)
                    .contentShape(Rectangle())
                    .dropDestination(
                        for: InstructionDragItem.self
                    ) { items, _ in

                        guard
                            let draggedItem = items.first,
                            let sourceIndex =
                                instructions.firstIndex(
                                    where: {
                                        $0.id == draggedItem.id
                                    }
                                )
                        else {
                            clearInstructionDragState()
                            return false
                        }

                        withAnimation {
                            let moved =
                                instructions.remove(
                                    at: sourceIndex
                                )

                            instructions.append(
                                moved
                            )
                        }

                        instructionEndDropTargeted = false
                        clearInstructionDragState()

                        return true

                    } isTargeted: { targeted in
                        instructionEndDropTargeted =
                            targeted
                    }
            }
        }
    }


    private func instructionCardPreview(
        instruction: EditableInstruction,
        index: Int
    ) -> some View {

        HStack(
            alignment: .top,
            spacing: KinSpacing.medium
        ) {
            Text("\(index + 1)")
                .font(
                    KinTypography.title3
                )
                .foregroundStyle(
                    KinColors.primary
                )
                .frame(width: 32)

            Text(
                instruction.text.isEmpty
                    ? "Describe this step"
                    : instruction.text
            )
            .font(KinTypography.body)
            .foregroundStyle(
                KinColors.primaryText
            )
            .lineLimit(3)

            Spacer()

            Image(
                systemName:
                    "line.3.horizontal"
            )
            .foregroundStyle(
                KinColors.secondaryText
            )
        }
        .padding(KinSpacing.medium)
        .frame(width: 330)
        .background(KinColors.surface)
        .clipShape(
            RoundedRectangle(
                cornerRadius:
                    KinRadius.medium
            )
        )
        .shadow(radius: 8)
    }


    private func moveInstruction(
        draggedID: UUID,
        targetID: UUID,
        position: RecipeDropPosition
    ) {
        guard
            draggedID != targetID,
            let sourceIndex =
                instructions.firstIndex(
                    where: {
                        $0.id == draggedID
                    }
                ),
            let originalTargetIndex =
                instructions.firstIndex(
                    where: {
                        $0.id == targetID
                    }
                )
        else {
            return
        }

        withAnimation {
            let moved =
                instructions.remove(
                    at: sourceIndex
                )

            var destinationIndex =
                originalTargetIndex

            if sourceIndex <
                originalTargetIndex {

                destinationIndex -= 1
            }

            if position == .below {
                destinationIndex += 1
            }

            destinationIndex =
                min(
                    max(
                        destinationIndex,
                        0
                    ),
                    instructions.count
                )

            instructions.insert(
                moved,
                at: destinationIndex
            )
        }
    }


    private func clearInstructionDragState() {
        draggedInstructionID = nil
        instructionDropTargetID = nil
        instructionDropPosition = nil
    }
    
    
    // MARK: InstructionRow
    
    private func instructionRow(
        index: Int
    ) -> some View {

        let instruction = instructions[index]

        return HStack(
            alignment: .top,
            spacing: KinSpacing.medium
        ) {
            Text("\(index + 1)")
                .font(KinTypography.title3)
                .foregroundStyle(KinColors.primary)
                .frame(width: 32, height: 44)

            TextField(
                "Describe this step",
                text: $instructions[index].text,
                axis: .vertical
            )
            .font(KinTypography.body)
            .foregroundStyle(
                KinColors.primaryText
            )
            .lineLimit(2...5)
            .submitLabel(.next)

            VStack(
                spacing: KinSpacing.small
            ) {
                Image(systemName: "line.3.horizontal")
                    .font(.title3)
                    .foregroundStyle(
                        KinColors.secondaryText
                    )
                    .frame(width: 40, height: 40)

                if instructions.count > 1 {
                    Button {
                        instructions.remove(at: index)
                    } label: {
                        Image(systemName: "trash")
                            .font(.caption)
                            .foregroundStyle(
                                KinColors.error
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(KinSpacing.medium)
        .background(KinColors.surface)
        .clipShape(
            RoundedRectangle(
                cornerRadius: KinRadius.medium
            )
        )
        .contentShape(
            Rectangle(),
            eoFill: false
        )
        .draggable(
            InstructionDragItem(
                id: instruction.id
            )
        ) {
            instructionCardPreview(
                instruction: instruction,
                index: index
            )
            .onAppear {
                draggedInstructionID = instruction.id
                dismissKeyboard()
            }
        }
        .overlay(
            alignment:
                instructionDropPosition == .below
                    ? .bottom
                    : .top
        ) {
            if instructionDropTargetID == instruction.id,
               draggedInstructionID != instruction.id {

                Rectangle()
                    .fill(KinColors.error)
                    .frame(height: 3)
                    .offset(
                        y:
                            instructionDropPosition == .below
                                ? 6
                                : -6
                    )
            }
        }        .dropDestination(
            for: InstructionDragItem.self
        ) { items, location in

            guard let draggedItem = items.first
            else {
                clearInstructionDragState()
                return false
            }

            let position: RecipeDropPosition =
                location.y > 44
                    ? .below
                    : .above

            moveInstruction(
                draggedID: draggedItem.id,
                targetID: instruction.id,
                position: position
            )

            clearInstructionDragState()

            return true

        } isTargeted: { targeted in

            if targeted {
                instructionDropTargetID =
                    instruction.id

            } else if instructionDropTargetID ==
                        instruction.id {

                instructionDropTargetID = nil
                instructionDropPosition = nil
            }
        }
        .onDrop(
            of: [.kinKitchenInstruction],
            delegate:
                InstructionHoverDropDelegate(
                    targetID: instruction.id,
                    onDragLocationChanged: { _ in },
                    draggedID: $draggedInstructionID,
                    targetIDBinding: $instructionDropTargetID,
                    position: $instructionDropPosition
                )
        )
    }


    // MARK: - Save Button

    private var saveButton: some View {
        Button {
            Task {
                await saveRecipe()
            }
        } label: {
            HStack {
                if isSaving {
                    ProgressView()
                        .tint(.white)
                }

                Text(
                    isSaving
                        ? "Saving..."
                        : "Save Changes"
                )
            }
            .font(KinTypography.button)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
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
            isSaving ||
            isDeleting ||
            recipeName
                .trimmingCharacters(
                    in: .whitespacesAndNewlines
                )
                .isEmpty
        )
    }


    // MARK: - Delete Button

    private var deleteButton: some View {
        Button {
            showingDeleteConfirmation = true
        } label: {
            HStack {
                if isDeleting {
                    ProgressView()
                        .tint(
                            KinColors.error
                        )
                }

                Label(
                    isDeleting
                        ? "Deleting..."
                        : "Delete Recipe",
                    systemImage: "trash"
                )
            }
            .font(KinTypography.button)
            .foregroundStyle(
                KinColors.error
            )
            .frame(maxWidth: .infinity)
            .padding(
                .vertical,
                KinSpacing.medium
            )
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
        .disabled(
            isSaving ||
            isDeleting
        )
    }


    // MARK: - Load

    @MainActor
    private func loadRecipe() async {
        isLoading = true
        errorMessage = nil

        defer {
            isLoading = false
        }

        do {
            let detail =
                try await RecipeService
                    .fetchRecipeWithIngredients(
                        id: recipeId
                    )

            let recipe =
                detail.recipe

            recipeName =
                recipe.name

            recipeDescription =
                recipe.description ?? ""

            category =
                recipe.category ?? ""

            servings =
                recipe.servings.map(
                    String.init
                ) ?? ""

            prepTime =
                recipe.prepTimeMinutes.map(
                    String.init
                ) ?? ""

            cookTime =
                recipe.cookTimeMinutes.map(
                    String.init
                ) ?? ""

            ingredients =
                detail
                    .orderedIngredients
                    .map {
                        EditableIngredient(
                            id: $0.id,
                            name: $0.name,
                            quantity:
                                $0.quantity.map {
                                    IngredientQuantityFormatter
                                        .format($0)
                                } ?? "",
                            unit:
                                $0.unit ?? ""
                        )
                    }

            instructions =
                parsedInstructions(
                    recipe.instructions
                )
                .map {
                    EditableInstruction(
                        text: $0
                    )
                }

            if instructions.isEmpty {
                instructions = [
                    EditableInstruction()
                ]
            }

        } catch {
            errorMessage =
                "The recipe could not be loaded."

            print(
                "EDIT RECIPE LOAD ERROR:",
                error.localizedDescription
            )
        }
    }


    // MARK: - Save

    @MainActor
    private func saveRecipe() async {
        guard !isSaving else {
            return
        }

        let cleanName =
            recipeName.trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        guard !cleanName.isEmpty else {
            return
        }

        isSaving = true
        errorMessage = nil

        defer {
            isSaving = false
        }

        do {
            let instructionText =
                instructions
                    .map {
                        $0.text
                            .trimmingCharacters(
                                in:
                                    .whitespacesAndNewlines
                            )
                    }
                    .filter {
                        !$0.isEmpty
                    }
                    .enumerated()
                    .map {
                        "\($0.offset + 1). \($0.element)"
                    }
                    .joined(
                        separator: "\n"
                    )

            let ingredientInputs =
                ingredients
                    .filter {
                        !$0.name
                            .trimmingCharacters(
                                in:
                                    .whitespacesAndNewlines
                            )
                            .isEmpty
                    }
                    .map {
                        RecipeIngredientInput(
                            name:
                                $0.name
                                    .trimmingCharacters(
                                        in:
                                            .whitespacesAndNewlines
                                    ),
                            quantity:
                                IngredientQuantityFormatter
                                    .parse(
                                        $0.quantity
                                    ),
                            unit:
                                cleanedOptionalString(
                                    $0.unit
                                ),
                            offProductId: nil
                        )
                    }

            _ =
                try await RecipeService.updateRecipe(
                    id: recipeId,
                    name: cleanName,
                    description: cleanedOptionalString(
                        recipeDescription
                    ),
                    instructions: cleanedOptionalString(
                        instructionText
                    ),
                    servings: Int(servings),
                    prepTimeMinutes: Int(prepTime),
                    cookTimeMinutes: Int(cookTime),
                    photoPath: nil,
                    category: cleanedOptionalString(
                        category
                    )
                )

            _ =
                try await RecipeService
                    .replaceIngredients(
                        recipeId: recipeId,
                        ingredients:
                            ingredientInputs
                    )

            dismiss()

        } catch {
            errorMessage =
                "The recipe could not be saved."

            print(
                "EDIT RECIPE SAVE ERROR:",
                error.localizedDescription
            )
        }
    }


    private func dismissKeyboard() {
        UIApplication.shared.sendAction(
            #selector(
                UIResponder.resignFirstResponder
            ),
            to: nil,
            from: nil,
            for: nil
        )
    }
    
    
    // MARK: - Delete

    @MainActor
    private func deleteRecipe() async {
        guard !isDeleting else {
            return
        }

        isDeleting = true

        defer {
            isDeleting = false
        }

        do {
            try await RecipeService
                .deleteRecipe(
                    id: recipeId
                )

            onDeleted()
            dismiss()

        } catch {
            errorMessage =
                "The recipe could not be deleted."

            print(
                "EDIT RECIPE DELETE ERROR:",
                error.localizedDescription
            )
        }
    }


    // MARK: - Add Ingredient

    private func addIngredient() {
        ingredients.append(
            EditableIngredient()
        )
    }


    // MARK: - Add Instruction

    private func addInstruction() {
        instructions.append(
            EditableInstruction()
        )
    }


    // MARK: - Field Components

    private func fieldLabel(
        _ title: String
    ) -> some View {
        Text(title)
            .font(KinTypography.caption)
            .foregroundStyle(
                KinColors.secondaryText
            )
    }


    private func numberField(
        title: String,
        placeholder: String,
        text: Binding<String>
    ) -> some View {
        VStack(
            alignment: .leading,
            spacing: KinSpacing.small
        ) {
            Text(title)
                .font(
                    KinTypography.caption
                )
                .foregroundStyle(
                    KinColors.secondaryText
                )

            TextField(
                placeholder,
                text: text
            )
            .keyboardType(.numberPad)
            .submitLabel(.next)
            .font(
                KinTypography.title3
            )
            .foregroundStyle(
                KinColors.primaryText
            )
        }
        .frame(
            maxWidth: .infinity,
            alignment: .leading
        )
        .padding(KinSpacing.medium)
        .background(KinColors.surface)
        .clipShape(
            RoundedRectangle(
                cornerRadius:
                    KinRadius.medium
            )
        )
    }


    private func fieldCard<Content: View>(
        @ViewBuilder content: () -> Content
    ) -> some View {
        content()
            .padding(KinSpacing.medium)
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


    // MARK: - Empty State

    private func emptySection(
        icon: String,
        title: String,
        message: String
    ) -> some View {
        VStack(
            spacing: KinSpacing.medium
        ) {
            Image(systemName: icon)
                .font(
                    .system(size: 36)
                )
                .foregroundStyle(
                    KinColors.primary
                )

            Text(title)
                .font(
                    KinTypography.title3
                )
                .foregroundStyle(
                    KinColors.primaryText
                )

            Text(message)
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
        .frame(maxWidth: .infinity)
        .padding(KinSpacing.xLarge)
        .background(KinColors.surface)
        .clipShape(
            RoundedRectangle(
                cornerRadius:
                    KinRadius.medium
            )
        )
    }


    // MARK: - Error State

    private func errorState(
        _ message: String
    ) -> some View {
        VStack(
            spacing: KinSpacing.large
        ) {
            Image(
                systemName:
                    "exclamationmark.triangle"
            )
            .font(
                .system(size: 42)
            )
            .foregroundStyle(
                KinColors.error
            )

            Text("Unable to Edit Recipe")
                .font(
                    KinTypography.title
                )
                .foregroundStyle(
                    KinColors.primaryText
                )

            Text(message)
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
                    await loadRecipe()
                }
            }
            .font(
                KinTypography.button
            )
            .foregroundStyle(.white)
            .padding(
                .horizontal,
                KinSpacing.xLarge
            )
            .padding(
                .vertical,
                KinSpacing.medium
            )
            .background(
                KinColors.primary
            )
            .clipShape(Capsule())
        }
        .padding(KinSpacing.large)
    }


    // MARK: - Instruction Parsing

    private func parsedInstructions(
        _ raw: String?
    ) -> [String] {
        guard let raw else {
            return []
        }

        return raw
            .components(
                separatedBy: .newlines
            )
            .map {
                $0.trimmingCharacters(
                    in:
                        .whitespacesAndNewlines
                )
            }
            .filter {
                !$0.isEmpty
            }
            .map {
                removingInstructionNumber(
                    $0
                )
            }
    }


    private func removingInstructionNumber(
        _ value: String
    ) -> String {
        value.replacingOccurrences(
            of: #"^\d+\.\s*"#,
            with: "",
            options: .regularExpression
        )
    }


    // MARK: - String Cleaning

    private func cleanedOptionalString(
        _ value: String
    ) -> String? {
        let cleaned =
            value.trimmingCharacters(
                in:
                    .whitespacesAndNewlines
            )

        return cleaned.isEmpty
            ? nil
            : cleaned
    }
}

// MARK: - Editable Ingredient

private struct EditableIngredient:
    Identifiable,
    Hashable {

    let id: UUID
    var name: String
    var quantity: String
    var unit: String

    init(
        id: UUID = UUID(),
        name: String = "",
        quantity: String = "",
        unit: String = ""
    ) {
        self.id = id
        self.name = name
        self.quantity = quantity
        self.unit = unit
    }
}


// MARK: - Editable Instruction

private struct EditableInstruction:
    Identifiable,
    Hashable {

    let id: UUID
    var text: String

    init(
        id: UUID = UUID(),
        text: String = ""
    ) {
        self.id = id
        self.text = text
    }
}


#Preview {
    NavigationStack {
        EditRecipeView(
            recipeId: UUID()
        )
    }
}

//
//  AddRecipeView.swift
//  KinKitchen
//
//  Created by Greg Hudler on 9/7/26.
//

import SwiftUI
import UniformTypeIdentifiers

struct AddRecipeView: View {
    @Environment(\.dismiss) private var dismiss
    private let onRecipeCreated: ((Recipe) -> Void)?

    @State private var recipeName = ""
    @State private var recipeDescription = ""
    @State private var servings = 4
    @State private var prepTime = ""
    @State private var cookTime = ""
    @State private var selectedCategory = "Dinner"

    @State private var ingredients: [IngredientDraft] = [IngredientDraft()]
    @State private var instructions: [InstructionDraft] = [InstructionDraft()]
    
    @State private var dragScrollTarget: UUID?

    @State private var draggedIngredientID: UUID?
    @State private var ingredientDropTargetID: UUID?
    @State private var ingredientDropPosition: DropPosition?

    @State private var draggedInstructionID: UUID?
    @State private var instructionDropTargetID: UUID?
    @State private var instructionDropPosition: DropPosition?

    @State private var isSaving = false
    @State private var errorMessage: String?
    @State private var showingError = false

    private let categories = [
        "Breakfast",
        "Lunch",
        "Dinner",
        "Side Dish",
        "Dessert",
        "Snack",
        "Drink",
        "Other"
    ]

    init(onRecipeCreated: ((Recipe) -> Void)? = nil) {
        self.onRecipeCreated = onRecipeCreated
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: 0) {
                    header
                    
                    VStack(alignment: .leading, spacing: KinSpacing.xLarge) {
                        recipePhotoPlaceholder
                        
                        fieldSection(title: "Recipe Name") {
                            TextField("Grandma's Baked Ziti", text: $recipeName)
                                .font(KinTypography.body)
                                .foregroundStyle(KinColors.primaryText)
                                .padding(KinSpacing.medium)
                                .background(KinColors.surface)
                                .clipShape(RoundedRectangle(cornerRadius: KinRadius.medium))
                        }
                        
                        fieldSection(title: "Description") {
                            TextEditor(text: $recipeDescription)
                                .font(KinTypography.body)
                                .foregroundStyle(KinColors.primaryText)
                                .frame(minHeight: 120)
                                .padding(KinSpacing.small)
                                .scrollContentBackground(.hidden)
                                .background(KinColors.surface)
                                .clipShape(RoundedRectangle(cornerRadius: KinRadius.medium))
                        }
                        
                        servingsSection
                        timesSection
                        categorySection
                        ingredientsSection
                        instructionsSection
                        
                        if let errorMessage {
                            Text(errorMessage)
                                .font(KinTypography.caption)
                                .foregroundStyle(KinColors.error)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        
                        Button {
                            Task { await saveRecipe() }
                        } label: {
                            Group {
                                if isSaving {
                                    ProgressView().tint(.white)
                                } else {
                                    Text("Save Recipe")
                                        .font(KinTypography.button)
                                }
                            }
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                        }
                        .padding(.vertical, KinSpacing.medium)
                        .background(KinColors.primary)
                        .clipShape(RoundedRectangle(cornerRadius: KinRadius.medium))
                        .buttonStyle(.plain)
                        .disabled(isSaving)
                    }
                    .padding(KinSpacing.large)
                }
            }
            .background(KinColors.background.ignoresSafeArea())
            .navigationBarHidden(true)
            .alert("Unable to Save Recipe", isPresented: $showingError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage ?? "Please try again.")
            }
        }
    }

    private var header: some View {
        HStack(spacing: KinSpacing.medium) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.title2)
                    .foregroundStyle(KinColors.primaryText)
                    .frame(width: 48, height: 48)
                    .background(KinColors.surface)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)

            Spacer()

            Text("Add Recipe")
                .font(KinTypography.title3)
                .foregroundStyle(KinColors.primaryText)

            Spacer()

            Button {
                Task { await saveRecipe() }
            } label: {
                Group {
                    if isSaving {
                        ProgressView().tint(KinColors.primary)
                    } else {
                        Text("Save")
                            .font(KinTypography.button)
                            .foregroundStyle(KinColors.primary)
                    }
                }
            }
            .frame(minWidth: 70, minHeight: 48)
            .background(KinColors.surface)
            .clipShape(Capsule())
            .buttonStyle(.plain)
            .disabled(isSaving)
        }
        .padding(.horizontal, KinSpacing.large)
        .padding(.vertical, KinSpacing.medium)
        .background(KinColors.background)
        .overlay(alignment: .bottom) { Divider() }
    }

    private var recipePhotoPlaceholder: some View {
        RoundedRectangle(cornerRadius: KinRadius.large)
            .fill(KinColors.surface)
            .frame(height: 210)
            .overlay {
                VStack(spacing: KinSpacing.medium) {
                    Image(systemName: "photo.badge.plus")
                        .font(.system(size: 38))
                        .foregroundStyle(KinColors.primary)

                    Text("Add Recipe Photo")
                        .font(KinTypography.body)
                        .foregroundStyle(KinColors.primary)

                    Text("Photo upload will be connected when recipe media support is added.")
                        .font(KinTypography.caption)
                        .foregroundStyle(KinColors.secondaryText)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, KinSpacing.xLarge)
                }
            }
    }

    private var servingsSection: some View {
        HStack {
            Text("Servings")
                .font(KinTypography.title)
                .foregroundStyle(KinColors.primaryText)

            Spacer()

            HStack(spacing: 0) {
                Button {
                    if servings > 1 { servings -= 1 }
                } label: {
                    Image(systemName: "minus")
                        .frame(width: 48, height: 44)
                }

                Text("\(servings)")
                    .font(KinTypography.body)
                    .frame(width: 52, height: 44)

                Button {
                    servings += 1
                } label: {
                    Image(systemName: "plus")
                        .frame(width: 48, height: 44)
                }
            }
            .foregroundStyle(KinColors.primaryText)
            .background(KinColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: KinRadius.medium))
        }
    }

    private var timesSection: some View {
        HStack(alignment: .top, spacing: KinSpacing.medium) {
            fieldSection(title: "Prep Time") {
                timeField(placeholder: "15", text: $prepTime)
            }

            fieldSection(title: "Cook Time") {
                timeField(placeholder: "30", text: $cookTime)
            }
        }
    }

    private func timeField(placeholder: String, text: Binding<String>) -> some View {
        HStack {
            TextField(placeholder, text: text)
                .keyboardType(.numberPad)

            Text("min")
                .foregroundStyle(KinColors.secondaryText)
        }
        .font(KinTypography.body)
        .padding(KinSpacing.medium)
        .background(KinColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: KinRadius.medium))
    }

    private var categorySection: some View {
        VStack(alignment: .leading, spacing: KinSpacing.small) {
            Text("Category")
                .font(KinTypography.title)
                .foregroundStyle(KinColors.primaryText)

            Menu {
                ForEach(categories, id: \.self) { category in
                    Button(category) { selectedCategory = category }
                }
            } label: {
                HStack {
                    Text(selectedCategory)
                        .font(KinTypography.body)
                        .foregroundStyle(KinColors.primaryText)

                    Spacer()

                    Image(systemName: "chevron.down")
                        .foregroundStyle(KinColors.primary)
                }
                .padding(KinSpacing.medium)
                .background(KinColors.surface)
                .clipShape(RoundedRectangle(cornerRadius: KinRadius.medium))
            }
        }
    }

    private var ingredientsSection: some View {
        VStack(alignment: .leading, spacing: KinSpacing.medium) {
            Text("Ingredients")
                .font(KinTypography.title)
                .foregroundStyle(KinColors.primaryText)

            ForEach(ingredients) { ingredient in
                if let index = ingredients.firstIndex(
                    where: { $0.id == ingredient.id }
                ) {
                    ingredientRow(index: index)
                        .id(ingredient.id)
                }
            }

            Button {
                ingredients.append(IngredientDraft())
            } label: {
                Label("Add Ingredient", systemImage: "plus")
                    .font(KinTypography.button)
                    .foregroundStyle(KinColors.primary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, KinSpacing.medium)
                    .overlay {
                        RoundedRectangle(cornerRadius: KinRadius.medium)
                            .stroke(KinColors.primary, lineWidth: 1)
                    }
            }
            .buttonStyle(.plain)
        }
    }

    private func ingredientRow(index: Int) -> some View {
        let ingredient = ingredients[index]

        return VStack(spacing: KinSpacing.small) {
            HStack(spacing: KinSpacing.small) {
                TextField(
                    "Qty",
                    text: $ingredients[index].quantity
                )
                .keyboardType(.numbersAndPunctuation)
                .frame(width: 65)

                TextField(
                    "Unit",
                    text: $ingredients[index].unit
                )
                .frame(width: 75)

                TextField(
                    "Ingredient",
                    text: $ingredients[index].name
                )

                Image(systemName: "line.3.horizontal")
                    .font(.title3)
                    .foregroundStyle(KinColors.secondaryText)
                    .frame(width: 40, height: 44)
            }
            .font(KinTypography.body)
            .foregroundStyle(KinColors.primaryText)

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
                        .foregroundStyle(KinColors.error)
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
        .contentShape(Rectangle())
        .draggable(
            IngredientDragItem(
                id: ingredient.id
            )
        ){
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
                    .fill(KinColors.primary)
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
            guard let draggedItem = items.first else {
                clearIngredientDragState()
                return false
            }

            let draggedID = draggedItem.id

            let position: DropPosition =
                location.y > 44
                    ? .below
                    : .above

            moveIngredient(
                draggedID: draggedID,
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

    private func ingredientCardPreview(_ ingredient: IngredientDraft) -> some View {
        HStack(spacing: KinSpacing.small) {
            Text(ingredient.quantity.isEmpty ? "Qty" : ingredient.quantity)
                .frame(width: 65)

            Text(ingredient.unit.isEmpty ? "Unit" : ingredient.unit)
                .frame(width: 75)

            Text(ingredient.name.isEmpty ? "Ingredient" : ingredient.name)
                .lineLimit(1)

            Spacer()

            Image(systemName: "line.3.horizontal")
        }
        .font(KinTypography.body)
        .foregroundStyle(KinColors.primaryText)
        .padding(KinSpacing.medium)
        .frame(width: 330)
        .background(KinColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: KinRadius.medium))
        .shadow(radius: 8)
    }

    private func moveIngredient(
        draggedID: UUID,
        targetID: UUID,
        position: DropPosition
    ) {
        guard
            draggedID != targetID,
            let sourceIndex = ingredients.firstIndex(where: { $0.id == draggedID }),
            let originalTargetIndex = ingredients.firstIndex(where: { $0.id == targetID })
        else {
            return
        }

        withAnimation {
            let moved = ingredients.remove(at: sourceIndex)
            var destinationIndex = originalTargetIndex

            if sourceIndex < originalTargetIndex {
                destinationIndex -= 1
            }

            if position == .below {
                destinationIndex += 1
            }

            destinationIndex = min(max(destinationIndex, 0), ingredients.count)
            ingredients.insert(moved, at: destinationIndex)
        }
    }

    private func clearIngredientDragState() {
        draggedIngredientID = nil
        ingredientDropTargetID = nil
        ingredientDropPosition = nil
    }

    private var instructionsSection: some View {
        VStack(alignment: .leading, spacing: KinSpacing.medium) {
            Text("Instructions")
                .font(KinTypography.title)
                .foregroundStyle(KinColors.primaryText)

            ForEach(instructions) { instruction in
                if let index = instructions.firstIndex(
                    where: { $0.id == instruction.id }
                ) {
                    instructionRow(index: index)
                        .id(instruction.id)
                }
            }

            Button {
                instructions.append(InstructionDraft())
            } label: {
                Label("Add Instruction", systemImage: "plus")
                    .font(KinTypography.button)
                    .foregroundStyle(KinColors.primary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, KinSpacing.medium)
                    .overlay {
                        RoundedRectangle(cornerRadius: KinRadius.medium)
                            .stroke(KinColors.primary, lineWidth: 1)
                    }
            }
            .buttonStyle(.plain)
        }
    }

    private func instructionRow(index: Int) -> some View {
        let instruction = instructions[index]

        return HStack(alignment: .top, spacing: KinSpacing.medium) {
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
            .foregroundStyle(KinColors.primaryText)
            .lineLimit(2...5)

            VStack(spacing: KinSpacing.small) {
                Image(systemName: "line.3.horizontal")
                    .font(.title3)
                    .foregroundStyle(KinColors.secondaryText)
                    .frame(width: 40, height: 40)
                    .contentShape(Rectangle())

                if instructions.count > 1 {
                    Button {
                        instructions.remove(at: index)
                    } label: {
                        Image(systemName: "trash")
                            .font(.caption)
                            .foregroundStyle(KinColors.error)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(KinSpacing.medium)
        .background(KinColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: KinRadius.medium))
        .contentShape(Rectangle())
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
        .overlay(alignment: instructionDropPosition == .below ? .bottom : .top) {
            if instructionDropTargetID == instruction.id &&
                draggedInstructionID != instruction.id {
                Rectangle()
                    .fill(KinColors.primary)
                    .frame(height: 3)
                    .offset(y: instructionDropPosition == .below ? 6 : -6)
            }
        }
        .dropDestination(
            for: InstructionDragItem.self
        ) { items, location in
            guard let draggedItem = items.first else {
                clearInstructionDragState()
                return false
            }

            let draggedID = draggedItem.id

            let position: DropPosition =
                location.y > 44
                    ? .below
                    : .above

            moveInstruction(
                draggedID: draggedID,
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

    private func instructionCardPreview(
        instruction: InstructionDraft,
        index: Int
    ) -> some View {
        HStack(alignment: .top, spacing: KinSpacing.medium) {
            Text("\(index + 1)")
                .font(KinTypography.title3)
                .foregroundStyle(KinColors.primary)
                .frame(width: 32)

            Text(
                instruction.text.isEmpty
                    ? "Describe this step"
                    : instruction.text
            )
            .font(KinTypography.body)
            .foregroundStyle(KinColors.primaryText)
            .lineLimit(3)

            Spacer()

            Image(systemName: "line.3.horizontal")
                .foregroundStyle(KinColors.secondaryText)
        }
        .padding(KinSpacing.medium)
        .frame(width: 330)
        .background(KinColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: KinRadius.medium))
        .shadow(radius: 8)
    }

    private func moveInstruction(
        draggedID: UUID,
        targetID: UUID,
        position: DropPosition
    ) {
        guard
            draggedID != targetID,
            let sourceIndex = instructions.firstIndex(where: { $0.id == draggedID }),
            let originalTargetIndex = instructions.firstIndex(where: { $0.id == targetID })
        else {
            return
        }

        withAnimation {
            let moved = instructions.remove(at: sourceIndex)
            var destinationIndex = originalTargetIndex

            if sourceIndex < originalTargetIndex {
                destinationIndex -= 1
            }

            if position == .below {
                destinationIndex += 1
            }

            destinationIndex = min(max(destinationIndex, 0), instructions.count)
            instructions.insert(moved, at: destinationIndex)
        }
    }

    private func clearInstructionDragState() {
        draggedInstructionID = nil
        instructionDropTargetID = nil
        instructionDropPosition = nil
    }

    private func fieldSection<Content: View>(
        title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: KinSpacing.small) {
            Text(title)
                .font(KinTypography.caption)
                .foregroundStyle(KinColors.secondaryText)

            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func validateForm() -> String? {
        let cleanName = recipeName.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !cleanName.isEmpty else {
            return "Please enter a recipe name."
        }

        guard servings > 0 else {
            return "Servings must be greater than zero."
        }

        if !prepTime.isEmpty {
            guard let prep = Int(prepTime), prep >= 0 else {
                return "Prep time must be entered as minutes."
            }
        }

        if !cookTime.isEmpty {
            guard let cook = Int(cookTime), cook >= 0 else {
                return "Cook time must be entered as minutes."
            }
        }

        let validIngredients = cleanedIngredients

        guard !validIngredients.isEmpty else {
            return "Please add at least one ingredient."
        }

        for ingredient in validIngredients {
            if !ingredient.quantity.isEmpty &&
                IngredientQuantityFormatter.parse(
                    ingredient.quantity
                ) == nil {
                return "One or more ingredient quantities are invalid."
            }
        }

        guard !cleanedInstructions.isEmpty else {
            return "Please add at least one instruction."
        }

        return nil
    }

    @MainActor
    private func saveRecipe() async {
        guard !isSaving else { return }

        errorMessage = nil

        if let validationError = validateForm() {
            errorMessage = validationError
            showingError = true
            return
        }

        isSaving = true
        defer { isSaving = false }

        var createdRecipe: Recipe?

        do {
            let recipe = try await RecipeService.createRecipe(
                name: recipeName,
                description: cleanedOptionalString(recipeDescription),
                instructions: instructionText,
                servings: servings,
                prepTimeMinutes: Int(prepTime),
                cookTimeMinutes: Int(cookTime),
                photoPath: nil,
                category: selectedCategory
            )

            createdRecipe = recipe

            let ingredientInputs = cleanedIngredients.map { ingredient in
                RecipeIngredientInput(
                    name: ingredient.name,
                    quantity: IngredientQuantityFormatter.parse(
                        ingredient.quantity
                    ),
                    unit: cleanedOptionalString(ingredient.unit)
                )
            }

            _ = try await RecipeService.createIngredients(
                recipeId: recipe.id,
                ingredients: ingredientInputs
            )

            onRecipeCreated?(recipe)
            dismiss()

        } catch {
            if let createdRecipe {
                try? await RecipeService.deleteRecipe(id: createdRecipe.id)
            }

            errorMessage =
                "Kin Kitchen was unable to save this recipe. Please try again."
            showingError = true

            print(
                "ADD RECIPE ERROR:",
                error.localizedDescription
            )
        }
    }

    private var cleanedIngredients: [IngredientDraft] {
        ingredients.compactMap { ingredient in
            let cleanName =
                ingredient.name.trimmingCharacters(in: .whitespacesAndNewlines)

            guard !cleanName.isEmpty else {
                return nil
            }

            return IngredientDraft(
                id: ingredient.id,
                quantity: ingredient.quantity.trimmingCharacters(in: .whitespacesAndNewlines),
                unit: ingredient.unit.trimmingCharacters(in: .whitespacesAndNewlines),
                name: cleanName
            )
        }
    }

    private var cleanedInstructions: [InstructionDraft] {
        instructions.compactMap { instruction in
            let cleanText =
                instruction.text.trimmingCharacters(in: .whitespacesAndNewlines)

            guard !cleanText.isEmpty else {
                return nil
            }

            return InstructionDraft(
                id: instruction.id,
                text: cleanText
            )
        }
    }

    private var instructionText: String {
        cleanedInstructions
            .enumerated()
            .map { index, instruction in
                "\(index + 1). \(instruction.text)"
            }
            .joined(separator: "\n")
    }


    private func cleanedOptionalString(_ value: String) -> String? {
        let cleaned =
            value.trimmingCharacters(in: .whitespacesAndNewlines)

        return cleaned.isEmpty ? nil : cleaned
    }
    
    private func dismissKeyboard() {
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil,
            from: nil,
            for: nil
        )
    }
    
}

private enum DropPosition {
    case above
    case below
}

private struct IngredientDraft: Identifiable {
    let id: UUID
    var quantity: String
    var unit: String
    var name: String

    init(
        id: UUID = UUID(),
        quantity: String = "",
        unit: String = "",
        name: String = ""
    ) {
        self.id = id
        self.quantity = quantity
        self.unit = unit
        self.name = name
    }
}

private struct InstructionDraft: Identifiable {
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

private struct IngredientHoverDropDelegate: DropDelegate {
    let targetID: UUID
    let onDragLocationChanged: (CGPoint) -> Void
    @Binding var draggedID: UUID?
    @Binding var targetIDBinding: UUID?
    @Binding var position: DropPosition?

    func dropEntered(info: DropInfo) {
        guard draggedID != nil, draggedID != targetID else { return }
        targetIDBinding = targetID
        position = info.location.y > 44 ? .below : .above
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        position = info.location.y > 44 ? .below : .above

        onDragLocationChanged(info.location)

        return DropProposal(operation: .move)
    }

    func performDrop(info: DropInfo) -> Bool {
        false
    }

    func dropExited(info: DropInfo) {
        if targetIDBinding == targetID {
            targetIDBinding = nil
            position = nil
        }
    }
}

private struct InstructionHoverDropDelegate: DropDelegate {
    let targetID: UUID
    let onDragLocationChanged: (CGPoint) -> Void
    @Binding var draggedID: UUID?
    @Binding var targetIDBinding: UUID?
    @Binding var position: DropPosition?

    func dropEntered(info: DropInfo) {
        guard draggedID != nil, draggedID != targetID else { return }
        targetIDBinding = targetID
        position = info.location.y > 44 ? .below : .above
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        position = info.location.y > 44 ? .below : .above

        onDragLocationChanged(info.location)

        return DropProposal(operation: .move)
    }

    func performDrop(info: DropInfo) -> Bool {
        false
    }

    func dropExited(info: DropInfo) {
        if targetIDBinding == targetID {
            targetIDBinding = nil
            position = nil
        }
    }
}

#Preview {
    NavigationStack {
        AddRecipeView()
    }
}


private struct IngredientDragItem: Codable, Transferable {
    let id: UUID

    static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(
            contentType: .kinKitchenIngredient
        )
    }
}

private struct InstructionDragItem: Codable, Transferable {
    let id: UUID

    static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(
            contentType: .kinKitchenInstruction
        )
    }
}

private extension UTType {
    static let kinKitchenIngredient =
        UTType(
            exportedAs: "com.kinkitchen.ingredient"
        )

    static let kinKitchenInstruction =
        UTType(
            exportedAs: "com.kinkitchen.instruction"
        )
}

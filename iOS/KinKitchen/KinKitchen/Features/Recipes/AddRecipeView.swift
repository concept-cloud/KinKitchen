//
//  AddRecipeView.swift
//  KinKitchen
//
//  Created by Greg Hudler on 9/7/26.
//

import SwiftUI
import PhotosUI

/// Add Recipe, laid out like Add Event: the photo across the top with
/// the name typed right on it, then simple cards in the order people
/// write a recipe down: kind of dish, ingredients, steps, details,
/// dietary, and the optional story. Save stays pinned at the bottom.
struct AddRecipeView: View {
    @Environment(\.dismiss) private var dismiss
    /// The ingredient whose name gets the cursor after picking a unit.
    @FocusState private var focusedIngredientNameId: UUID?
    /// The step being typed, so Return can move to the next one.
    @FocusState private var focusedStepId: UUID?
    @FocusState private var isNameFocused: Bool
    private let onRecipeCreated: ((Recipe) -> Void)?
    private let onCancel: (() -> Void)?

    @State private var recipeName = ""
    @State private var recipeDescription = ""
    @State private var recipeStory = ""
    @State private var originalContributor = ""
    
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var selectedPhotoData: Data?
    
    @State private var servings = 4
    @State private var prepTime = ""
    @State private var cookTime = ""
    @State private var selectedCategory: RecipeCategory = .dinner
    @State private var selectedRestrictionIds: Set<UUID> = []

    @State private var ingredients: [IngredientDraft] = [IngredientDraft()]
    @State private var instructions: [InstructionDraft] = [InstructionDraft()]

    @State private var draggedIngredientID: UUID?
    @State private var ingredientDropTargetID: UUID?
    @State private var ingredientDropPosition: RecipeDropPosition?
    @State private var ingredientEndDropTargeted = false

    @State private var draggedInstructionID: UUID?
    @State private var instructionDropTargetID: UUID?
    @State private var instructionDropPosition: RecipeDropPosition?
    @State private var instructionEndDropTargeted = false

    @State private var pasteMode: PasteListSheet.Mode?
    @State private var isStoryShown = false
    
    @State private var isSaving = false
    @State private var errorMessage: String?
    @State private var showingError = false

    private static let heroHeight: CGFloat = 300

    init(
        onRecipeCreated: ((Recipe) -> Void)? = nil,
        onCancel: (() -> Void)? = nil
    ) {
        self.onRecipeCreated = onRecipeCreated
        self.onCancel = onCancel
    }

    /// What's still needed before Save, or nil when ready.
    private var missingText: String? {
        var missing: [String] = []
        if recipeName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            missing.append("a name")
        }
        if cleanedIngredients.isEmpty {
            missing.append("an ingredient")
        }
        if cleanedInstructions.isEmpty {
            missing.append("a step")
        }
        guard !missing.isEmpty else {
            return nil
        }
        return "Add " + ListFormatter.localizedString(byJoining: missing)
    }

    var body: some View {

        GeometryReader { geometry in

            ScrollView {

                VStack(spacing: 0) {

                    hero(topInset: geometry.safeAreaInsets.top)

                    VStack(spacing: KinSpacing.medium) {
                        categoryCard
                        ingredientsCard
                        stepsCard
                        detailsCard
                        dietaryCard
                        aboutCard
                    }
                    .padding(KinSpacing.large)
                    .padding(.top, KinSpacing.small)
                    .padding(.bottom, KinSpacing.large)
                    .frame(maxWidth: .infinity)
                    .background(
                        UnevenRoundedRectangle(
                            topLeadingRadius: KinRadius.xLarge,
                            topTrailingRadius: KinRadius.xLarge
                        )
                        .fill(KinColors.paper)
                        .shadow(color: .black.opacity(0.12), radius: 10, y: -2)
                    )
                    // Tucks up over the bottom of the photo.
                    .padding(.top, -KinSpacing.xLarge)
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .scrollEdgeEffectHidden(true, for: .top)
            .ignoresSafeArea(edges: .top)
            .background(KinColors.paper.ignoresSafeArea())
            .safeAreaInset(edge: .bottom) {
                saveBar
            }
        }
        .navigationBarHidden(true)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                if let id = focusedIngredientNameId {
                    ingredientKeyBar(for: id)
                }
            }
        }
        .sensoryFeedback(.selection, trigger: selectedCategory)
        .sensoryFeedback(.selection, trigger: servings)
        .sensoryFeedback(.selection, trigger: ingredients.count)
        .sensoryFeedback(.selection, trigger: instructions.count)
        .sheet(item: $pasteMode) { mode in
            PasteListSheet(mode: mode) { text in
                addPasted(text, mode: mode)
            }
        }
        .onChange(of: selectedPhotoItem) { _, newItem in
            guard let newItem else {
                return
            }
            Task {
                do {
                    if let picked = try await newItem.loadTransferable(type: Data.self),
                       let data = await KinPhotoResizer.prepared(picked, for: .print) {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            selectedPhotoData = data
                        }
                    }
                } catch {
                    errorMessage = "Kin Kitchen was unable to load that photo."
                    showingError = true
                }
            }
        }
        .alert("Unable to Save Recipe", isPresented: $showingError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage ?? "Please try again.")
        }
    }


    // MARK: - Hero

    private func hero(topInset: CGFloat) -> some View {

        VStack(alignment: .leading, spacing: KinSpacing.small) {

            HStack {
                Button("Cancel") {
                    if let onCancel {
                        onCancel()
                    } else {
                        dismiss()
                    }
                }
                .font(KinTypography.callout)
                .foregroundStyle(.white)
                .padding(.horizontal, KinSpacing.medium)
                .padding(.vertical, KinSpacing.small)
                .background(.black.opacity(0.35), in: Capsule())
                .buttonStyle(.kinPressable)

                Spacer()

                PhotosPicker(
                    selection: $selectedPhotoItem,
                    matching: .images
                ) {
                    Label(
                        selectedPhotoData == nil ? "Add Photo" : "Change Photo",
                        systemImage: KinIcons.camera
                    )
                    .font(KinTypography.footnote.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, KinSpacing.medium)
                    .padding(.vertical, KinSpacing.small)
                    .background(.black.opacity(0.35), in: Capsule())
                }
                .buttonStyle(.kinPressable)
            }

            Spacer(minLength: KinSpacing.medium)

            Label(selectedCategory.rawValue, systemImage: selectedCategory.symbol)
                .font(.system(size: 12, weight: .bold))
                .textCase(.uppercase)
                .foregroundStyle(.white.opacity(0.9))
                .contentTransition(.opacity)
                .animation(.snappy, value: selectedCategory)

            // The name is typed right on the photo.
            TextField(
                "Recipe Name",
                text: $recipeName,
                prompt: Text("Name your recipe")
                    .foregroundStyle(.white.opacity(0.6)),
                axis: .vertical
            )
            .font(KinTypography.title)
            .foregroundStyle(.white)
            .tint(.white)
            .lineLimit(1...2)
            .submitLabel(.done)
            .textInputAutocapitalization(.words)
            .focused($isNameFocused)
            .onChange(of: recipeName) { _, newValue in
                // Return closes the keyboard instead of a new line.
                if newValue.contains("\n") {
                    recipeName = newValue.replacingOccurrences(of: "\n", with: "")
                    isNameFocused = false
                }
            }
            .accessibilityLabel("Recipe Name")

            Rectangle()
                .fill(.white.opacity(isNameFocused ? 0.9 : 0.4))
                .frame(height: 1.5)
                .animation(.easeOut(duration: 0.2), value: isNameFocused)

            Label(heroSummary, systemImage: KinIcons.servings)
                .font(KinTypography.footnote.weight(.semibold))
                .foregroundStyle(.white.opacity(0.9))
                .lineLimit(1)
                .padding(.top, KinSpacing.xxSmall)
        }
        .kinTextOnPhoto()
        .padding(.horizontal, KinSpacing.large)
        .padding(.top, topInset + KinSpacing.small)
        .padding(.bottom, KinSpacing.xLarge + KinSpacing.large)
        .frame(height: Self.heroHeight + topInset)
        .background {
            heroBackground
                .accessibilityHidden(true)
        }
        .clipped()
    }

    private var heroSummary: String {
        var parts = ["Serves \(servings)"]
        if let prep = Int(prepTime), prep > 0 {
            parts.append("Prep \(RecipeTimeChoices.text(prep))")
        }
        if let cook = Int(cookTime), cook > 0 {
            parts.append("Cook \(RecipeTimeChoices.text(cook))")
        }
        return parts.joined(separator: " · ")
    }

    private var heroBackground: some View {

        Color.clear
            .overlay {
                if let selectedPhotoData,
                   let image = UIImage(data: selectedPhotoData) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .transition(.opacity)
                } else {
                    // Warm placeholder with the category's icon.
                    LinearGradient(
                        colors: [
                            KinColors.success.opacity(0.9),
                            KinColors.accent.opacity(0.85)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .overlay(alignment: .topTrailing) {
                        Image(systemName: selectedCategory.symbol)
                            .font(.system(size: 150, weight: .bold))
                            .foregroundStyle(.white.opacity(0.14))
                            .rotationEffect(.degrees(-12))
                            .offset(x: 30, y: 50)
                            .contentTransition(.symbolEffect(.replace))
                            .animation(.snappy, value: selectedCategory)
                    }
                }
            }
            .overlay {
                LinearGradient(
                    stops: [
                        .init(color: .black.opacity(0.35), location: 0),
                        .init(color: .clear, location: 0.3),
                        .init(color: .clear, location: 0.45),
                        .init(color: .black.opacity(0.6), location: 1)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
            .clipped()
    }


    // MARK: - Category

    private var categoryCard: some View {

        KinFormCard(
            title: "What kind of dish?",
            systemImage: "fork.knife",
            tint: KinColors.primary
        ) {
            LazyVGrid(
                columns: Array(
                    repeating: GridItem(.flexible(), spacing: KinSpacing.small),
                    count: 4
                ),
                spacing: KinSpacing.small
            ) {
                ForEach(RecipeCategory.allCases) { category in
                    categoryTile(category)
                }
            }
        }
    }

    private func categoryTile(_ category: RecipeCategory) -> some View {

        let isSelected = selectedCategory == category

        return Button {
            withAnimation(.snappy(duration: 0.2)) {
                selectedCategory = category
            }
        } label: {
            VStack(spacing: KinSpacing.xSmall) {
                Image(systemName: category.symbol)
                    .font(.system(size: 18, weight: .semibold))
                    .frame(height: 22)
                Text(category.rawValue)
                    .font(KinTypography.caption)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .foregroundStyle(isSelected ? .white : KinColors.primaryText)
            .frame(maxWidth: .infinity, minHeight: 62)
            .padding(.horizontal, KinSpacing.xxSmall)
            .background(
                isSelected ? KinColors.primary : KinColors.background,
                in: RoundedRectangle(cornerRadius: KinRadius.medium)
            )
        }
        .buttonStyle(.kinPressable)
        .accessibilityLabel(category.rawValue)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }


    // MARK: - Ingredients

    private var ingredientsCard: some View {

        KinFormCard(
            title: "Ingredients",
            systemImage: KinIcons.ingredients,
            tint: KinColors.success,
            subtitle: "Type each one like \"2 cups flour\". Return adds the next. Drag ≡ to reorder."
        ) {

            VStack(spacing: KinSpacing.small) {

                ForEach(ingredients) { ingredient in
                    if let index = ingredients.firstIndex(where: { $0.id == ingredient.id }) {
                        ingredientRow(index: index)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }

                // Drop here to move an ingredient to the end.
                Rectangle()
                    .fill(ingredientEndDropTargeted ? KinColors.primary : Color.clear)
                    .frame(height: 4)
                    .contentShape(Rectangle())
                    .dropDestination(for: IngredientDragItem.self) { items, _ in
                        guard
                            let draggedItem = items.first,
                            let sourceIndex = ingredients.firstIndex(where: { $0.id == draggedItem.id })
                        else {
                            clearIngredientDragState()
                            return false
                        }
                        withAnimation {
                            let moved = ingredients.remove(at: sourceIndex)
                            ingredients.append(moved)
                        }
                        ingredientEndDropTargeted = false
                        clearIngredientDragState()
                        return true
                    } isTargeted: { targeted in
                        ingredientEndDropTargeted = targeted
                    }

                addRowButtons(
                    addTitle: "Add Ingredient",
                    add: { addIngredient(after: nil) },
                    paste: { pasteMode = .ingredients }
                )
            }
        }
    }

    private func ingredientRow(index: Int) -> some View {
        let ingredient = ingredients[index]

        return HStack(alignment: .top, spacing: KinSpacing.small) {

            // Typed as one line, e.g. "2 cups flour". The amount,
            // unit and ingredient are worked out for you.
            VStack(alignment: .leading, spacing: KinSpacing.xxSmall) {

                TextField(
                    index == 0 ? "e.g. 2 cups flour" : "Next ingredient",
                    text: $ingredients[index].line,
                    axis: .vertical
                )
                .lineLimit(1...3)
                .focused($focusedIngredientNameId, equals: ingredient.id)
                .onChange(of: ingredients[index].line) { _, newValue in
                    splitIngredient(id: ingredient.id, text: newValue)
                }

                if let understood = IngredientLinePreview.text(for: ingredient.line) {
                    Label(understood, systemImage: "checkmark")
                        .font(KinTypography.caption)
                        .foregroundStyle(KinColors.success)
                        .labelStyle(.titleAndIcon)
                        .transition(.opacity)
                        .accessibilityLabel("Reads as \(understood)")
                }
            }
            .padding(.vertical, 8)
            .animation(.easeOut(duration: 0.15), value: ingredient.line)

            if ingredients.count > 1 {
                Button {
                    withAnimation(.snappy) {
                        ingredients.removeAll { $0.id == ingredient.id }
                    }
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .foregroundStyle(KinColors.secondaryText.opacity(0.5))
                }
                .buttonStyle(.plain)
                .padding(.top, 10)
                .accessibilityLabel("Remove \(ingredient.line.isEmpty ? "ingredient" : ingredient.line)")
            }

            Image(systemName: "line.3.horizontal")
                .foregroundStyle(KinColors.secondaryText.opacity(0.6))
                .frame(width: 24, height: 40)
                .accessibilityHidden(true)
        }
        .font(KinTypography.body)
        .foregroundStyle(KinColors.primaryText)
        .padding(.horizontal, KinSpacing.small)
        .padding(.vertical, KinSpacing.xSmall)
        .background(
            KinColors.background,
            in: RoundedRectangle(cornerRadius: KinRadius.medium)
        )
        .contentShape(Rectangle())
        .draggable(IngredientDragItem(id: ingredient.id)) {
            ingredientCardPreview(ingredient)
                .onAppear {
                    draggedIngredientID = ingredient.id
                    dismissKeyboard()
                }
        }
        .overlay(alignment: ingredientDropPosition == .below ? .bottom : .top) {
            if ingredientDropTargetID == ingredient.id,
               draggedIngredientID != ingredient.id {
                Rectangle()
                    .fill(KinColors.primary)
                    .frame(height: 3)
                    .offset(y: ingredientDropPosition == .below ? 5 : -5)
            }
        }
        .dropDestination(for: IngredientDragItem.self) { items, location in
            guard let draggedItem = items.first else {
                clearIngredientDragState()
                return false
            }
            moveIngredient(
                draggedID: draggedItem.id,
                targetID: ingredient.id,
                position: location.y > 24 ? .below : .above
            )
            clearIngredientDragState()
            return true
        } isTargeted: { targeted in
            if targeted {
                ingredientDropTargetID = ingredient.id
            } else if ingredientDropTargetID == ingredient.id {
                ingredientDropTargetID = nil
                ingredientDropPosition = nil
            }
        }
        .onDrop(
            of: [.kinKitchenIngredient],
            delegate: IngredientHoverDropDelegate(
                targetID: ingredient.id,
                onDragLocationChanged: { _ in },
                draggedID: $draggedIngredientID,
                targetIDBinding: $ingredientDropTargetID,
                position: $ingredientDropPosition
            )
        )
    }

    /// Adds an empty ingredient after `id` (or at the end) and puts
    /// the cursor in it. Moves to the next one if it's already empty.
    private func addIngredient(after id: UUID?) {
        let index = id.flatMap { id in ingredients.firstIndex { $0.id == id } }
            ?? ingredients.count - 1

        if index + 1 < ingredients.count {
            focusedIngredientNameId = ingredients[index + 1].id
            return
        }

        if let last = ingredients.last, last.isEmpty, id == nil {
            focusedIngredientNameId = last.id
            return
        }

        let draft = IngredientDraft()
        withAnimation(.snappy) {
            ingredients.append(draft)
        }
        focusedIngredientNameId = draft.id
    }


    /// Return moves to the next ingredient; pasting several lines
    /// makes one ingredient per line.
    private func splitIngredient(id: UUID, text: String) {

        guard
            text.contains(where: \.isNewline),
            let index = ingredients.firstIndex(where: { $0.id == id })
        else {
            return
        }

        let lines = text.components(separatedBy: .newlines)
        let rest = IngredientLineParser.lines(from: lines.dropFirst().joined(separator: "\n"))

        ingredients[index].line = IngredientLineParser.strippingListMarker(lines[0])

        guard !rest.isEmpty else {
            addIngredient(after: id)
            return
        }

        let newRows = rest.map { IngredientDraft(line: $0) }
        withAnimation(.snappy) {
            ingredients.insert(contentsOf: newRows, at: index + 1)
        }
        focusedIngredientNameId = newRows.last?.id
    }


    // MARK: - Steps

    private var stepsCard: some View {

        KinFormCard(
            title: "Steps",
            systemImage: KinIcons.instructions,
            tint: KinColors.warning,
            subtitle: "Return starts the next step. Drag ≡ to reorder."
        ) {

            VStack(spacing: KinSpacing.small) {

                ForEach(instructions) { instruction in
                    if let index = instructions.firstIndex(where: { $0.id == instruction.id }) {
                        instructionRow(index: index)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }

                // Drop here to move a step to the end.
                Rectangle()
                    .fill(instructionEndDropTargeted ? KinColors.primary : Color.clear)
                    .frame(height: 4)
                    .contentShape(Rectangle())
                    .dropDestination(for: InstructionDragItem.self) { items, _ in
                        guard
                            let draggedItem = items.first,
                            let sourceIndex = instructions.firstIndex(where: { $0.id == draggedItem.id })
                        else {
                            clearInstructionDragState()
                            return false
                        }
                        withAnimation {
                            let moved = instructions.remove(at: sourceIndex)
                            instructions.append(moved)
                        }
                        instructionEndDropTargeted = false
                        clearInstructionDragState()
                        return true
                    } isTargeted: { targeted in
                        instructionEndDropTargeted = targeted
                    }

                addRowButtons(
                    addTitle: "Add Step",
                    add: { addStep() },
                    paste: { pasteMode = .steps }
                )
            }
        }
    }

    private func instructionRow(index: Int) -> some View {
        let instruction = instructions[index]

        return HStack(alignment: .top, spacing: KinSpacing.small) {

            Text("\(index + 1)")
                .font(KinTypography.headline)
                .foregroundStyle(.white)
                .frame(width: 28, height: 28)
                .background(KinColors.warning, in: Circle())
                .padding(.top, 6)

            TextField(
                "Describe this step",
                text: $instructions[index].text,
                axis: .vertical
            )
            .font(KinTypography.body)
            .foregroundStyle(KinColors.primaryText)
            .lineLimit(1...8)
            .padding(.vertical, 8)
            .focused($focusedStepId, equals: instruction.id)
            .onChange(of: instructions[index].text) { _, newValue in
                splitStep(id: instruction.id, text: newValue)
            }

            if instructions.count > 1 {
                Button {
                    withAnimation(.snappy) {
                        instructions.removeAll { $0.id == instruction.id }
                    }
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .foregroundStyle(KinColors.secondaryText.opacity(0.5))
                }
                .buttonStyle(.plain)
                .padding(.top, 10)
                .accessibilityLabel("Remove step \(index + 1)")
            }

            Image(systemName: "line.3.horizontal")
                .foregroundStyle(KinColors.secondaryText.opacity(0.6))
                .frame(width: 24, height: 40)
                .accessibilityHidden(true)
        }
        .padding(.horizontal, KinSpacing.small)
        .padding(.vertical, KinSpacing.xxSmall)
        .background(
            KinColors.background,
            in: RoundedRectangle(cornerRadius: KinRadius.medium)
        )
        .contentShape(Rectangle())
        .draggable(InstructionDragItem(id: instruction.id)) {
            instructionCardPreview(instruction: instruction, index: index)
                .onAppear {
                    draggedInstructionID = instruction.id
                    dismissKeyboard()
                }
        }
        .overlay(alignment: instructionDropPosition == .below ? .bottom : .top) {
            if instructionDropTargetID == instruction.id,
               draggedInstructionID != instruction.id {
                Rectangle()
                    .fill(KinColors.primary)
                    .frame(height: 3)
                    .offset(y: instructionDropPosition == .below ? 5 : -5)
            }
        }
        .dropDestination(for: InstructionDragItem.self) { items, location in
            guard let draggedItem = items.first else {
                clearInstructionDragState()
                return false
            }
            moveInstruction(
                draggedID: draggedItem.id,
                targetID: instruction.id,
                position: location.y > 24 ? .below : .above
            )
            clearInstructionDragState()
            return true
        } isTargeted: { targeted in
            if targeted {
                instructionDropTargetID = instruction.id
            } else if instructionDropTargetID == instruction.id {
                instructionDropTargetID = nil
                instructionDropPosition = nil
            }
        }
        .onDrop(
            of: [.kinKitchenInstruction],
            delegate: InstructionHoverDropDelegate(
                targetID: instruction.id,
                onDragLocationChanged: { _ in },
                draggedID: $draggedInstructionID,
                targetIDBinding: $instructionDropTargetID,
                position: $instructionDropPosition
            )
        )
    }

    /// Return in a step starts the next one; pasting several lines
    /// makes one step per line.
    private func splitStep(id: UUID, text: String) {

        guard
            text.contains(where: \.isNewline),
            let index = instructions.firstIndex(where: { $0.id == id })
        else {
            return
        }

        let lines = text.components(separatedBy: .newlines)
        let first = IngredientLineParser.strippingListMarker(lines[0])
        let rest = IngredientLineParser.steps(from: lines.dropFirst().joined(separator: "\n"))

        instructions[index].text = first

        let newSteps = rest.isEmpty
            ? [InstructionDraft()]
            : rest.map { InstructionDraft(text: $0) }

        // Typing Return on a step that's followed by an empty one
        // just moves there.
        if rest.isEmpty,
           index + 1 < instructions.count,
           instructions[index + 1].text.isEmpty {
            focusedStepId = instructions[index + 1].id
            return
        }

        withAnimation(.snappy) {
            instructions.insert(contentsOf: newSteps, at: index + 1)
        }
        focusedStepId = newSteps.last?.id
    }

    private func addStep() {
        if let last = instructions.last, last.text.isEmpty {
            focusedStepId = last.id
            return
        }
        let draft = InstructionDraft()
        withAnimation(.snappy) {
            instructions.append(draft)
        }
        focusedStepId = draft.id
    }


    /// Above the keyboard while typing an ingredient: fractions and
    /// common units, added to the end of the line.
    private func ingredientKeyBar(for id: UUID) -> some View {

        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: KinSpacing.xSmall) {
                ForEach(IngredientLinePreview.quickKeys, id: \.self) { key in
                    Button(key) {
                        guard let index = ingredients.firstIndex(where: { $0.id == id }) else {
                            return
                        }
                        ingredients[index].line =
                            IngredientLinePreview.appending(key, to: ingredients[index].line)
                    }
                    .font(KinTypography.callout.weight(.semibold))
                    .foregroundStyle(KinColors.primaryText)
                    .padding(.horizontal, KinSpacing.small)
                    .padding(.vertical, KinSpacing.xSmall)
                    .background(KinColors.surface, in: Capsule())
                    .buttonStyle(.plain)
                    .accessibilityLabel(MeasureKeyboardText.spokenName(for: key))
                }
            }
        }
    }

    /// "Add" and "Paste a List" side by side under a list.
    private func addRowButtons(
        addTitle: String,
        add: @escaping () -> Void,
        paste: @escaping () -> Void
    ) -> some View {

        HStack(spacing: KinSpacing.small) {

            Button(action: add) {
                Label(addTitle, systemImage: KinIcons.add)
                    .font(KinTypography.callout.weight(.semibold))
                    .foregroundStyle(KinColors.primary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, KinSpacing.medium)
                    .background(
                        KinColors.primary.opacity(0.1),
                        in: RoundedRectangle(cornerRadius: KinRadius.medium)
                    )
            }
            .buttonStyle(.kinPressable)

            Button(action: paste) {
                Label("Paste a List", systemImage: "doc.on.clipboard")
                    .font(KinTypography.callout.weight(.semibold))
                    .foregroundStyle(KinColors.primaryText)
                    .padding(.vertical, KinSpacing.medium)
                    .padding(.horizontal, KinSpacing.medium)
                    .background(
                        KinColors.background,
                        in: RoundedRectangle(cornerRadius: KinRadius.medium)
                    )
            }
            .buttonStyle(.kinPressable)
        }
    }

    /// Adds pasted lines, replacing the empty row left at the end.
    private func addPasted(_ text: String, mode: PasteListSheet.Mode) {
        switch mode {
        case .ingredients:
            let parsed = IngredientLineParser.lines(from: text).map {
                IngredientDraft(line: $0)
            }
            guard !parsed.isEmpty else { return }
            withAnimation(.snappy) {
                ingredients.removeAll(where: \.isEmpty)
                ingredients.append(contentsOf: parsed)
            }
        case .steps:
            let parsed = IngredientLineParser.steps(from: text).map {
                InstructionDraft(text: $0)
            }
            guard !parsed.isEmpty else { return }
            withAnimation(.snappy) {
                instructions.removeAll { $0.text.trimmingCharacters(in: .whitespaces).isEmpty }
                instructions.append(contentsOf: parsed)
            }
        }
    }


    // MARK: - Details

    private var detailsCard: some View {

        KinFormCard(
            title: "Servings & Time",
            systemImage: "clock.fill",
            tint: KinColors.primary
        ) {

            VStack(alignment: .leading, spacing: KinSpacing.medium) {

                HStack(spacing: KinSpacing.medium) {
                    Text("Serves \(servings)")
                        .font(KinTypography.body)
                        .foregroundStyle(KinColors.primaryText)
                        .contentTransition(.numericText())

                    Spacer()

                    stepperButton("minus", label: "Fewer servings", isEnabled: servings > 1) {
                        servings -= 1
                    }
                    stepperButton("plus", label: "More servings", isEnabled: servings < 100) {
                        servings += 1
                    }
                }

                Divider()
                    .overlay(KinColors.secondaryText.opacity(0.15))

                timeRow("Prep Time", minutes: $prepTime, choices: RecipeTimeChoices.prep)

                timeRow("Cook Time", minutes: $cookTime, choices: RecipeTimeChoices.cook)
            }
        }
    }

    private func timeRow(
        _ title: String,
        minutes: Binding<String>,
        choices: [Int]
    ) -> some View {

        VStack(alignment: .leading, spacing: KinSpacing.small) {

            HStack {
                Text(title)
                    .font(KinTypography.caption.weight(.semibold))
                    .textCase(.uppercase)
                    .foregroundStyle(KinColors.secondaryText)

                Spacer()

                // Any other time, in minutes.
                HStack(spacing: KinSpacing.xSmall) {
                    TextField("–", text: minutes)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 44)
                    Text("min")
                        .foregroundStyle(KinColors.secondaryText)
                }
                .font(KinTypography.callout)
                .padding(.horizontal, KinSpacing.small)
                .padding(.vertical, KinSpacing.xSmall)
                .background(
                    KinColors.background,
                    in: RoundedRectangle(cornerRadius: KinRadius.small)
                )
                .accessibilityLabel("\(title) in minutes")
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: KinSpacing.small) {
                    ForEach(choices, id: \.self) { choice in
                        KinChoiceChip(
                            title: RecipeTimeChoices.text(choice),
                            isSelected: Int(minutes.wrappedValue) == choice
                        ) {
                            withAnimation(.snappy) {
                                // Tapping the chosen time clears it.
                                minutes.wrappedValue =
                                    Int(minutes.wrappedValue) == choice ? "" : String(choice)
                            }
                        }
                    }
                }
                .padding(.vertical, 2)
            }
            .scrollClipDisabled()
        }
    }

    private func stepperButton(
        _ systemImage: String,
        label: String,
        isEnabled: Bool,
        action: @escaping () -> Void
    ) -> some View {

        Button {
            withAnimation(.snappy) {
                action()
            }
        } label: {
            Image(systemName: systemImage)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(isEnabled ? KinColors.primary : KinColors.secondaryText.opacity(0.4))
                .frame(width: 40, height: 40)
                .background(KinColors.primary.opacity(isEnabled ? 0.12 : 0.05), in: Circle())
        }
        .buttonStyle(.kinPressable)
        .disabled(!isEnabled)
        .accessibilityLabel(label)
    }


    // MARK: - Dietary

    private var dietaryCard: some View {

        KinFormCard(
            title: "Dietary",
            systemImage: KinIcons.dietary,
            tint: KinColors.success,
            subtitle: "Optional. Tag what this recipe fits, like Vegetarian."
        ) {
            RecipeDietaryTagPicker(
                selection: $selectedRestrictionIds
            )
        }
    }


    // MARK: - About and Story

    private var aboutCard: some View {

        KinFormCard(
            title: "About This Recipe",
            systemImage: "text.alignleft",
            tint: KinColors.secondary,
            subtitle: "Optional"
        ) {

            VStack(alignment: .leading, spacing: KinSpacing.medium) {

                noteEditor(
                    text: $recipeDescription,
                    placeholder: "A short description: what it is, when you make it...",
                    minHeight: 90
                )

                Button {
                    withAnimation(.snappy) {
                        isStoryShown.toggle()
                    }
                } label: {
                    HStack {
                        Label("Story & Legacy", systemImage: "book.closed.fill")
                            .font(KinTypography.callout.weight(.semibold))
                            .foregroundStyle(KinColors.primaryText)
                        Spacer()
                        Image(systemName: "chevron.down")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(KinColors.secondaryText)
                            .rotationEffect(.degrees(showsStory ? 180 : 0))
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityHint("Who it came from and the story behind it")

                if showsStory {

                    VStack(alignment: .leading, spacing: KinSpacing.small) {

                        TextField("Who it came from, e.g. Grandma Rose", text: $originalContributor)
                            .font(KinTypography.body)
                            .foregroundStyle(KinColors.primaryText)
                            .textInputAutocapitalization(.words)
                            .padding(KinSpacing.medium)
                            .background(
                                KinColors.background,
                                in: RoundedRectangle(cornerRadius: KinRadius.medium)
                            )

                        noteEditor(
                            text: $recipeStory,
                            placeholder: "The story behind it: the first time you had it, who made it best...",
                            minHeight: 120
                        )
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
        }
    }

    /// Open when asked, or once anything's been written there.
    private var showsStory: Bool {
        isStoryShown || !originalContributor.isEmpty || !recipeStory.isEmpty
    }

    private func noteEditor(
        text: Binding<String>,
        placeholder: String,
        minHeight: CGFloat
    ) -> some View {

        ZStack(alignment: .topLeading) {

            if text.wrappedValue.isEmpty {
                Text(placeholder)
                    .font(KinTypography.callout)
                    .foregroundStyle(KinColors.secondaryText.opacity(0.7))
                    .padding(.horizontal, KinSpacing.medium + 5)
                    .padding(.vertical, KinSpacing.medium + 8)
                    .allowsHitTesting(false)
            }

            TextEditor(text: text)
                .font(KinTypography.callout)
                .foregroundStyle(KinColors.primaryText)
                .scrollContentBackground(.hidden)
                .padding(.horizontal, KinSpacing.medium)
                .padding(.vertical, KinSpacing.small)
                .frame(minHeight: minHeight)
        }
        .background(
            KinColors.background,
            in: RoundedRectangle(cornerRadius: KinRadius.medium)
        )
    }


    // MARK: - Save Bar

    /// Pinned at the bottom so Save is always in reach.
    private var saveBar: some View {

        VStack(spacing: KinSpacing.small) {

            if let missingText {
                Text(missingText)
                    .font(KinTypography.caption)
                    .foregroundStyle(KinColors.secondaryText)
                    .contentTransition(.opacity)
            }

            KinPrimaryButton(
                title: isSaving ? "Saving..." : "Save Recipe"
            ) {
                focusedIngredientNameId = nil
                focusedStepId = nil
                Task {
                    await saveRecipe()
                }
            }
            .disabled(isSaving || missingText != nil)
            .opacity(isSaving || missingText != nil ? 0.5 : 1)
            .animation(.easeOut(duration: 0.2), value: missingText)
        }
        .padding(.horizontal, KinSpacing.large)
        .padding(.vertical, KinSpacing.small)
        .background {
            KinColors.paper
                .ignoresSafeArea()
                .shadow(color: .black.opacity(0.08), radius: 8, y: -2)
        }
    }


    // MARK: - Drag and Drop

    private func ingredientCardPreview(_ ingredient: IngredientDraft) -> some View {
        HStack(spacing: KinSpacing.small) {
            Text(ingredient.line.isEmpty ? "Ingredient" : ingredient.line)
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
        position: RecipeDropPosition
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
        position: RecipeDropPosition
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

        guard !isSaving else {
            return
        }

        errorMessage = nil

        if let validationError = validateForm() {
            errorMessage = validationError
            showingError = true
            return
        }

        isSaving = true

        defer {
            isSaving = false
        }

        var createdRecipe: Recipe?

        do {

            // 1. Create the recipe first
            let recipe = try await RecipeService.createRecipe(
                name: recipeName,
                description: cleanedOptionalString(
                    recipeDescription
                ),
                story: cleanedOptionalString(
                    recipeStory
                ),
                originalContributor:
                    cleanedOptionalString(
                        originalContributor
                    ),
                instructions: instructionText,
                servings: servings,
                prepTimeMinutes: Int(prepTime),
                cookTimeMinutes: Int(cookTime),
                photoPath: nil,
                category: selectedCategory.rawValue
            )

            createdRecipe = recipe

            // 2. Save ingredients
            let ingredientInputs =
                cleanedIngredients.map { ingredient in

                    RecipeIngredientInput(
                        name: ingredient.name,
                        quantity:
                            IngredientQuantityFormatter.parse(
                                ingredient.quantity
                            ),
                        unit:
                            cleanedOptionalString(
                                ingredient.unit
                            )
                    )
                }

            let savedIngredients =
                try await RecipeService.createIngredients(
                    recipeId: recipe.id,
                    ingredients: ingredientInputs
                )

            let allergenInputs =
                savedIngredients.map { ingredient in
                    IngredientAllergenInput(
                        id: ingredient.id,
                        name: ingredient.name,
                        offProductId: ingredient.offProductId
                    )
                }

            _ = try await IngredientAllergenService
                .classifyAndStore(
                    ingredients: allergenInputs
                )

            // Dietary tags are supplemental. The recipe already
            // exists, so a failure here shouldn't fail the save.
            if !selectedRestrictionIds.isEmpty {
                do {
                    try await RecipeService
                        .replaceDietaryRestrictionTags(
                            recipeId: recipe.id,
                            restrictionIds:
                                selectedRestrictionIds
                        )
                } catch {
                    print(
                        "RECIPE DIETARY TAG SAVE ERROR:",
                        error.localizedDescription
                    )
                }
            }

            // 3. Upload photo if one was selected
            var finalRecipe = recipe

            if let selectedPhotoData {

                do {

                    let photoPath =
                        try await RecipeService.uploadRecipePhoto(
                            recipeId: recipe.id,
                            imageData: selectedPhotoData
                        )

                    finalRecipe =
                        try await RecipeService.updateRecipe(
                            id: recipe.id,
                            name: recipe.name,
                            description: recipe.description,
                            story: recipe.story,
                            originalContributor:
                                recipe.originalContributor,
                            instructions: recipe.instructions,
                            servings: recipe.servings,
                            prepTimeMinutes:
                                recipe.prepTimeMinutes,
                            cookTimeMinutes:
                                recipe.cookTimeMinutes,
                            photoPath: photoPath,
                            category: recipe.category
                        )

                } catch {

                    print(
                        "RECIPE PHOTO UPLOAD ERROR:",
                        error.localizedDescription
                    )

                    errorMessage =
                        "The recipe was saved, but the photo could not be uploaded. You can add the photo later by editing the recipe."

                    showingError = true

                    onRecipeCreated?(recipe)

                    return
                }
            }

            // 4. Notify parent with final saved recipe
            onRecipeCreated?(finalRecipe)

            dismiss()

        } catch {

            // Only delete the recipe if the actual recipe/ingredient
            // creation failed.
            if let createdRecipe {
                _ = try? await RecipeService.deleteRecipe(
                    id: createdRecipe.id
                )
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

    /// Each typed line split into amount, unit and name for saving.
    private var cleanedIngredients: [IngredientDraft] {
        ingredients.compactMap { ingredient in
            let parsed = IngredientLineParser.ingredient(
                from: ingredient.line.trimmingCharacters(in: .whitespacesAndNewlines)
            )

            let cleanName =
                parsed.name.trimmingCharacters(in: .whitespacesAndNewlines)

            guard !cleanName.isEmpty else {
                return nil
            }

            return IngredientDraft(
                id: ingredient.id,
                line: ingredient.line,
                quantity: parsed.quantity,
                unit: parsed.unit,
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


// MARK: - Times

/// Prep and cook time chips.
nonisolated enum RecipeTimeChoices {

    static let prep = [5, 10, 15, 20, 30, 45, 60]
    static let cook = [10, 15, 20, 30, 45, 60, 90, 120]

    /// "15 min", "1 hr", "1 hr 30 min".
    static func text(_ minutes: Int) -> String {
        guard minutes >= 60 else {
            return "\(minutes) min"
        }
        let hours = minutes / 60
        let rest = minutes % 60
        return rest == 0 ? "\(hours) hr" : "\(hours) hr \(rest) min"
    }
}


// MARK: - Paste a List

/// Paste a list copied from a website or a note. Each line becomes an
/// ingredient (with the amount and unit read off the front) or a step.
private struct PasteListSheet: View {

    enum Mode: String, Identifiable {
        case ingredients
        case steps

        var id: String { rawValue }
    }

    let mode: Mode
    let onAdd: (String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var text = ""
    @FocusState private var isFocused: Bool

    private var count: Int {
        IngredientLineParser.lines(from: text).count
    }

    private var preview: [IngredientLineParser.Ingredient] {
        Array(IngredientLineParser.ingredients(from: text).prefix(6))
    }

    var body: some View {

        NavigationStack {

            ScrollView {

                VStack(alignment: .leading, spacing: KinSpacing.medium) {

                    Text(
                        mode == .ingredients
                            ? "One ingredient per line, like \"2 cups flour\". Amounts and units are filled in for you."
                            : "One step per line. Numbers and bullets are removed."
                    )
                    .font(KinTypography.footnote)
                    .foregroundStyle(KinColors.secondaryText)

                    TextEditor(text: $text)
                        .font(KinTypography.callout)
                        .scrollContentBackground(.hidden)
                        .focused($isFocused)
                        .padding(KinSpacing.small)
                        .frame(minHeight: 220)
                        .background(
                            KinColors.surface,
                            in: RoundedRectangle(cornerRadius: KinRadius.medium)
                        )

                    if UIPasteboard.general.hasStrings, text.isEmpty {
                        Button {
                            text = UIPasteboard.general.string ?? ""
                        } label: {
                            Label("Paste from Clipboard", systemImage: "doc.on.clipboard")
                                .font(KinTypography.callout.weight(.semibold))
                        }
                        .tint(KinColors.primary)
                    }

                    if mode == .ingredients, !preview.isEmpty {
                        VStack(alignment: .leading, spacing: KinSpacing.xSmall) {
                            Text("Preview")
                                .font(KinTypography.caption.weight(.semibold))
                                .textCase(.uppercase)
                                .foregroundStyle(KinColors.secondaryText)

                            ForEach(Array(preview.enumerated()), id: \.offset) { _, item in
                                HStack(spacing: KinSpacing.small) {
                                    Text([item.quantity, item.unit].filter { !$0.isEmpty }.joined(separator: " "))
                                        .foregroundStyle(KinColors.primary)
                                        .frame(width: 90, alignment: .leading)
                                    Text(item.name)
                                        .foregroundStyle(KinColors.primaryText)
                                }
                                .font(KinTypography.callout)
                            }
                        }
                    }
                }
                .padding(KinSpacing.large)
            }
            .background(KinColors.background)
            .navigationTitle(mode == .ingredients ? "Paste Ingredients" : "Paste Steps")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(count == 0 ? "Add" : "Add \(count)") {
                        onAdd(text)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(count == 0)
                }
            }
            .onAppear {
                isFocused = true
            }
        }
    }
}


private struct IngredientDraft: Identifiable {
    let id: UUID
    /// What was typed, e.g. "2 cups flour".
    var line: String
    /// Worked out from `line` when saving.
    var quantity: String
    var unit: String
    var name: String

    init(
        id: UUID = UUID(),
        line: String = "",
        quantity: String = "",
        unit: String = "",
        name: String = ""
    ) {
        self.id = id
        self.line = line
        self.quantity = quantity
        self.unit = unit
        self.name = name
    }

    var isEmpty: Bool {
        line.trimmingCharacters(in: .whitespaces).isEmpty
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

#Preview {
    NavigationStack {
        AddRecipeView()
    }
}

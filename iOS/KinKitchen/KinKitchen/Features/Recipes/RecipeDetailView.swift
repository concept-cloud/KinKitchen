//
//  RecipeDetailView.swift
//  KinKitchen
//
//  Created by Greg Hudler on 9/7/26.
//

import SwiftUI
import Supabase

struct RecipeDetailView: View {

    enum DetailTab: String, CaseIterable {
        case ingredients = "Ingredients"
        case instructions = "Instructions"
        case notes = "Notes"
    }

    @Environment(\.dismiss) private var dismiss

    let recipeId: UUID

    @State private var detail: RecipeWithIngredients?
    @State private var ratingSummary: RecipeRatingSummary?

    @State private var selectedTab: DetailTab = .ingredients
    @State private var isLoading = true
    @State private var isSavingRating = false
    @State private var errorMessage: String?

    @State private var stories: [RecipeStory] = []
    @State private var showingAddNote = false
    @State private var newNoteText = ""
    @State private var isSavingNote = false
    
    @State private var versions: [Recipe] = []
    @State private var showingVersions = false
    @State private var selectedVersionId: UUID?
    @State private var showingSelectedVersion = false

    @State private var originalRecipe: Recipe?
    @State private var showingOriginal = false

    @State private var currentUserId: UUID?
    @State private var isCreatingVersion = false
    @State private var createdVersionId: UUID?
    @State private var showingCreatedVersion = false
    
    @State private var showingEditRecipe = false
    @State private var recipeWasDeleted = false
    
    var body: some View {
        ZStack {
            KinColors.background
                .ignoresSafeArea()

            if isLoading {
                ProgressView("Loading recipe...")
                    .foregroundStyle(KinColors.primaryText)

            } else if let errorMessage {
                errorState(errorMessage)

            } else if let detail {
                recipeContent(detail)

            } else {
                errorState("Recipe information could not be loaded.")
            }
        }
        .navigationBarHidden(true)
        .task {
            await loadRecipe()
        }
        .sheet(
            isPresented: $showingAddNote
        ) {
            addNoteSheet
        }
        .sheet(
            isPresented: $showingVersions
        ) {
            versionsSheet
        }

        .navigationDestination(
            isPresented: $showingOriginal
        ) {
            if let originalRecipe {
                RecipeDetailView(
                    recipeId: originalRecipe.id
                )
            }
        }

        .navigationDestination(
            isPresented: $showingSelectedVersion
        ) {
            if let selectedVersionId {
                RecipeDetailView(
                    recipeId: selectedVersionId
                )
            }
        }

        .navigationDestination(
            isPresented: $showingCreatedVersion
        ) {
            if let createdVersionId {
                RecipeDetailView(
                    recipeId: createdVersionId
                )
            }
        }
        
        .navigationDestination(
            isPresented: $showingEditRecipe
        ) {
            EditRecipeView(
                recipeId: recipeId,
                onDeleted: {
                    recipeWasDeleted = true
                }
            )
        }
        .onChange(of: showingEditRecipe) { _, isShowing in
            guard !isShowing else {
                return
            }

            if recipeWasDeleted {
                dismiss()
            } else {
                Task {
                    await loadRecipe()
                }
            }
        }
    }

    // MARK: - Recipe Content

    private func recipeContent(
        _ detail: RecipeWithIngredients
    ) -> some View {
        ScrollView {
            VStack(spacing: 0) {
                header

                VStack(
                    alignment: .leading,
                    spacing: KinSpacing.large
                ) {
                    hero(detail.recipe)

                    recipeInformation(detail.recipe)

                    tabs

                    tabContent(detail)

                    addToCookbookButton
                }
                .padding(KinSpacing.large)
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
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

            Text("Recipe")
                .font(KinTypography.title3)
                .foregroundStyle(KinColors.primaryText)

            Spacer()

            // Keeps title visually centered.
            Color.clear
                .frame(width: 48, height: 48)
        }
        .padding(.horizontal, KinSpacing.large)
        .padding(.vertical, KinSpacing.medium)
        .background(KinColors.background)
        .overlay(alignment: .bottom) {
            Divider()
        }
    }

    // MARK: - Hero

    private func hero(
        _ recipe: Recipe
    ) -> some View {
        RoundedRectangle(
            cornerRadius: KinRadius.large
        )
        .fill(KinColors.surface)
        .frame(height: 220)
        .overlay {
            if recipe.photoPath != nil {
                Image(systemName: "photo")
                    .font(.system(size: 46))
                    .foregroundStyle(KinColors.primary)
            } else {
                Image(systemName: "fork.knife")
                    .font(.system(size: 52))
                    .foregroundStyle(KinColors.primary)
            }
        }
    }

    // MARK: - Recipe Information

    private func recipeInformation(
        _ recipe: Recipe
    ) -> some View {
        VStack(
            alignment: .leading,
            spacing: KinSpacing.medium
        ) {
            HStack(alignment: .center, spacing: KinSpacing.medium) {
                Text(recipe.name)
                    .font(KinTypography.largeTitle)
                    .foregroundStyle(KinColors.primaryText)

                Spacer()

                if currentUserId == recipe.ownerId {
                    Button {
                        showingEditRecipe = true
                    } label: {
                        Image(systemName: "pencil")
                            .font(.title3)
                            .foregroundStyle(KinColors.primary)
                            .frame(width: 44, height: 44)
                            .background(KinColors.surface)
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Edit Recipe")
                }
            }

            if let description = cleaned(recipe.description) {
                Text(description)
                    .font(KinTypography.body)
                    .foregroundStyle(KinColors.secondaryText)
            }

            HStack(spacing: KinSpacing.medium) {
                if let category = cleaned(recipe.category) {
                    metadataChip(
                        icon: "tag",
                        text: category
                    )
                }

                if recipe.totalTimeMinutes > 0 {
                    metadataChip(
                        icon: "clock",
                        text: recipe.formattedTotalTime
                    )
                }

                if let servings = recipe.servings {
                    metadataChip(
                        icon: "person.2",
                        text: "\(servings)"
                    )
                }
            }

            timeDetails(recipe)

            ratingSection

            lineageActions(recipe)

        }
    }
    // MARK: - Prep / Cook Time

    private func timeDetails(
        _ recipe: Recipe
    ) -> some View {
        HStack(spacing: KinSpacing.medium) {
            timeCard(
                title: "Prep",
                value: recipe.formattedPrepTime
            )

            timeCard(
                title: "Cook",
                value: recipe.formattedCookTime
            )
        }
    }

    private func timeCard(
        title: String,
        value: String
    ) -> some View {
        VStack(
            alignment: .leading,
            spacing: KinSpacing.small
        ) {
            Text(title)
                .font(KinTypography.caption)
                .foregroundStyle(KinColors.secondaryText)

            Text(value)
                .font(KinTypography.title3)
                .foregroundStyle(KinColors.primaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(KinSpacing.medium)
        .background(KinColors.surface)
        .clipShape(
            RoundedRectangle(
                cornerRadius: KinRadius.medium
            )
        )
    }

    // MARK: - Rating / Versions

    private var ratingSection: some View {
        VStack(
            alignment: .leading,
            spacing: KinSpacing.medium
        ) {
            HStack(
                alignment: .top,
                spacing: KinSpacing.large
            ) {
                VStack(
                    alignment: .leading,
                    spacing: 2
                ) {
                    Text("Overall Rating")
                        .font(KinTypography.caption)
                        .foregroundStyle(
                            KinColors.secondaryText
                        )

                    if let average =
                        ratingSummary?.averageRating {

                        HStack(spacing: KinSpacing.small) {
                            Image(systemName: "star.fill")
                                .foregroundStyle(
                                    KinColors.primary
                                )

                            Text(
                                String(
                                    format: "%.1f",
                                    average
                                )
                            )
                            .font(KinTypography.title3)
                            .foregroundStyle(
                                KinColors.primaryText
                            )

                            Text(
                                "(\(ratingSummary?.ratingCount ?? 0))"
                            )
                            .font(KinTypography.caption)
                            .foregroundStyle(
                                KinColors.secondaryText
                            )
                        }

                    } else {
                        Text("Not rated yet")
                            .font(KinTypography.body)
                            .foregroundStyle(
                                KinColors.secondaryText
                            )
                    }
                }

                Spacer()

                Button {
                    showingVersions = true
                } label: {
                    VStack(
                        alignment: .trailing,
                        spacing: 2
                    ) {
                        Text("Versions")
                            .font(KinTypography.caption)
                            .foregroundStyle(
                                KinColors.secondaryText
                            )

                        HStack(spacing: KinSpacing.small) {
                            Text(
                                "\(versions.count) \(versions.count == 1 ? "Version" : "Versions")"
                            )
                            .font(KinTypography.title3)
                            .foregroundStyle(
                                KinColors.primaryText
                            )

                            Image(
                                systemName: "chevron.right"
                            )
                            .font(.caption)
                            .foregroundStyle(
                                KinColors.primary
                            )
                        }
                    }
                }
                .buttonStyle(.plain)
            }

            Divider()

            VStack(
                alignment: .leading,
                spacing: KinSpacing.small
            ) {
                Text("Your Rating")
                    .font(KinTypography.caption)
                    .foregroundStyle(
                        KinColors.secondaryText
                    )

                HStack(spacing: KinSpacing.small) {
                    ForEach(1...5, id: \.self) { rating in
                        Button {
                            Task {
                                await saveRating(rating)
                            }
                        } label: {
                            Image(
                                systemName:
                                    rating <=
                                    (ratingSummary?
                                        .currentUserRating ?? 0)
                                        ? "star.fill"
                                        : "star"
                            )
                            .font(.title2)
                            .foregroundStyle(
                                KinColors.primary
                            )
                        }
                        .buttonStyle(.plain)
                        .disabled(isSavingRating)
                    }

                    if isSavingRating {
                        ProgressView()
                            .controlSize(.small)
                    }
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
    }


    // MARK: - Recipe Lineage Actions

    @ViewBuilder
    private func lineageActions(
        _ recipe: Recipe
    ) -> some View {
        if recipe.originalRecipeId != nil {
            Button {
                showingOriginal = true
            } label: {
                Label(
                    "Show Original",
                    systemImage: "arrow.uturn.backward"
                )
                .font(KinTypography.button)
                .foregroundStyle(KinColors.primary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, KinSpacing.medium)
                .background(KinColors.surface)
                .clipShape(
                    RoundedRectangle(
                        cornerRadius: KinRadius.medium
                    )
                )
            }
            .buttonStyle(.plain)
        }
    }
    // MARK: - Metadata Chip

    private func metadataChip(
        icon: String,
        text: String
    ) -> some View {
        HStack(spacing: KinSpacing.small) {
            Image(systemName: icon)

            Text(text)
        }
        .font(KinTypography.caption)
        .foregroundStyle(KinColors.primaryText)
        .padding(.horizontal, KinSpacing.medium)
        .padding(.vertical, KinSpacing.small)
        .background(KinColors.surface)
        .clipShape(Capsule())
    }

    // MARK: - Tabs

    private var tabs: some View {
        HStack(spacing: 0) {
            ForEach(
                DetailTab.allCases,
                id: \.self
            ) { tab in
                Button {
                    selectedTab = tab
                } label: {
                    VStack(spacing: KinSpacing.small) {
                        Text(tab.rawValue)
                            .font(KinTypography.button)
                            .foregroundStyle(
                                selectedTab == tab
                                    ? KinColors.primary
                                    : KinColors.secondaryText
                            )

                        Rectangle()
                            .fill(
                                selectedTab == tab
                                    ? KinColors.primary
                                    : .clear
                            )
                            .frame(height: 2)
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Tab Content

    @ViewBuilder
    private func tabContent(
        _ detail: RecipeWithIngredients
    ) -> some View {
        switch selectedTab {
        case .ingredients:
            ingredientsView(detail.orderedIngredients)

        case .instructions:
            instructionsView(detail.recipe.instructions)

        case .notes:
            notesView
        }
    }

    // MARK: - Ingredients

    private func ingredientsView(
        _ ingredients: [RecipeIngredient]
    ) -> some View {
        VStack(
            alignment: .leading,
            spacing: KinSpacing.medium
        ) {
            if ingredients.isEmpty {
                emptySection(
                    icon: "basket",
                    title: "No Ingredients",
                    message:
                        "No ingredients have been added to this recipe."
                )

            } else {
                ForEach(ingredients) { ingredient in
                    KinCard {
                        HStack(spacing: KinSpacing.medium) {
                            Text(
                                ingredientQuantity(
                                    ingredient
                                )
                            )
                            .font(KinTypography.title3)
                            .foregroundStyle(KinColors.primary)
                            .frame(
                                minWidth: 75,
                                alignment: .leading
                            )

                            Text(ingredient.name)
                                .font(KinTypography.body)
                                .foregroundStyle(KinColors.primaryText)

                            Spacer()
                        }
                    }
                }
            }
        }
    }

    // MARK: - Instructions

    private func instructionsView(
        _ rawInstructions: String?
    ) -> some View {
        let steps =
            parsedInstructions(
                rawInstructions
            )

        return VStack(
            alignment: .leading,
            spacing: KinSpacing.medium
        ) {
            if steps.isEmpty {
                emptySection(
                    icon: "list.number",
                    title: "No Instructions",
                    message:
                        "No instructions have been added to this recipe."
                )

            } else {
                ForEach(
                    Array(steps.enumerated()),
                    id: \.offset
                ) { index, step in
                    KinCard {
                        HStack(
                            alignment: .top,
                            spacing: KinSpacing.medium
                        ) {
                            Text("\(index + 1)")
                                .font(KinTypography.title3)
                                .foregroundStyle(.white)
                                .frame(
                                    width: 34,
                                    height: 34
                                )
                                .background(KinColors.primary)
                                .clipShape(Circle())

                            Text(step)
                                .font(KinTypography.body)
                                .foregroundStyle(KinColors.primaryText)
                                .frame(
                                    maxWidth: .infinity,
                                    alignment: .leading
                                )
                        }
                    }
                }
            }
        }
    }

    // MARK: - Notes

    private var notesView: some View {
        VStack(
            alignment: .leading,
            spacing: KinSpacing.medium
        ) {
            if stories.isEmpty {
                emptySection(
                    icon: "note.text",
                    title: "No Family Notes Yet",
                    message:
                        "Add notes, memories, or family context for this recipe."
                )
            } else {
                ForEach(stories) { story in
                    if let text = cleaned(story.story) {
                        KinCard {
                            VStack(
                                alignment: .leading,
                                spacing: KinSpacing.small
                            ) {
                                Text(text)
                                    .font(KinTypography.body)
                                    .foregroundStyle(
                                        KinColors.primaryText
                                    )

                                Text(
                                    formattedStoryDate(
                                        story.createdAt
                                    )
                                )
                                .font(KinTypography.caption)
                                .foregroundStyle(
                                    KinColors.secondaryText
                                )
                            }
                        }
                    }
                }
            }

            Button {
                showingAddNote = true
            } label: {
                Label(
                    "Add Note",
                    systemImage: "plus"
                )
                .font(KinTypography.button)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, KinSpacing.medium)
                .background(KinColors.primary)
                .clipShape(
                    RoundedRectangle(
                        cornerRadius: KinRadius.medium
                    )
                )
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Add to Cookbook

    private var addToCookbookButton: some View {
        Button {
            print("Add recipe to cookbook tapped")
        } label: {
            Label(
                "Add to Cookbook",
                systemImage: "book.closed"
            )
            .font(KinTypography.button)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, KinSpacing.medium)
            .background(KinColors.primary)
            .clipShape(
                RoundedRectangle(
                    cornerRadius: KinRadius.medium
                )
            )
        }
        .buttonStyle(.plain)
        .padding(.top, KinSpacing.medium)
    }

    // MARK: - Empty Section

    private func emptySection(
        icon: String,
        title: String,
        message: String
    ) -> some View {
        VStack(spacing: KinSpacing.medium) {
            Image(systemName: icon)
                .font(.system(size: 36))
                .foregroundStyle(KinColors.primary)

            Text(title)
                .font(KinTypography.title3)
                .foregroundStyle(KinColors.primaryText)

            Text(message)
                .font(KinTypography.body)
                .foregroundStyle(KinColors.secondaryText)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(KinSpacing.xLarge)
        .background(KinColors.surface)
        .clipShape(
            RoundedRectangle(
                cornerRadius: KinRadius.medium
            )
        )
    }

    // MARK: - Error

    private func errorState(
        _ message: String
    ) -> some View {
        VStack(spacing: KinSpacing.large) {
            Image(
                systemName:
                    "exclamationmark.triangle"
            )
            .font(.system(size: 42))
            .foregroundStyle(KinColors.error)

            Text("Unable to Load Recipe")
                .font(KinTypography.title)
                .foregroundStyle(KinColors.primaryText)

            Text(message)
                .font(KinTypography.body)
                .foregroundStyle(KinColors.secondaryText)
                .multilineTextAlignment(.center)

            Button("Try Again") {
                Task {
                    await loadRecipe()
                }
            }
            .font(KinTypography.button)
            .foregroundStyle(.white)
            .padding(.horizontal, KinSpacing.xLarge)
            .padding(.vertical, KinSpacing.medium)
            .background(KinColors.primary)
            .clipShape(Capsule())
        }
        .padding(KinSpacing.large)
    }

    // MARK: - Load Recipe

    @MainActor
    private func loadRecipe() async {
        isLoading = true
        errorMessage = nil

        defer {
            isLoading = false
        }

        do {
            let loadedDetail =
                try await RecipeService
                    .fetchRecipeWithIngredients(
                        id: recipeId
                    )

            detail = loadedDetail

            let recipe =
                loadedDetail.recipe

            async let ratingResult =
                RecipeService
                    .fetchRecipeRatingSummary(
                        recipeId: recipeId
                    )

            async let storyResult =
                RecipeService
                    .fetchRecipeStories(
                        recipeId: recipeId
                    )

            async let versionResult =
                RecipeService
                    .fetchRecipeVersions(
                        for: recipe
                    )

            ratingSummary =
                try await ratingResult

            stories =
                try await storyResult

            versions =
                try await versionResult

            currentUserId =
                try await SupabaseManager.client
                    .auth
                    .session
                    .user
                    .id

            if recipe.originalRecipeId != nil {
                originalRecipe =
                    try await RecipeService
                        .fetchOriginalRecipe(
                            for: recipe
                        )
            } else {
                originalRecipe = nil
            }

        } catch {
            errorMessage =
                "Please check your connection and try again."

            print(
                "RECIPE DETAIL LOAD ERROR:",
                error.localizedDescription
            )
        }
    }

    // MARK: - Save Rating

    @MainActor
    private func saveRating(
        _ rating: Int
    ) async {
        guard !isSavingRating else {
            return
        }

        isSavingRating = true

        defer {
            isSavingRating = false
        }

        do {
            _ =
                try await RecipeService
                    .setCurrentUserRating(
                        recipeId: recipeId,
                        rating: rating
                    )

            ratingSummary =
                try await RecipeService
                    .fetchRecipeRatingSummary(
                        recipeId: recipeId
                    )

        } catch {
            print(
                "RECIPE RATING ERROR:",
                error.localizedDescription
            )
        }
    }
    
    // MARK: - Make My Version

    @MainActor
    private func makeMyVersion(
        from recipe: Recipe
    ) async {
        guard !isCreatingVersion else {
            return
        }

        guard currentUserId != recipe.ownerId else {
            return
        }

        isCreatingVersion = true

        defer {
            isCreatingVersion = false
        }

        do {
            let created =
                try await RecipeService
                    .createVersion(
                        from: recipe
                    )

            createdVersionId =
                created.id

            versions =
                try await RecipeService
                    .fetchRecipeVersions(
                        for: recipe
                    )

            showingCreatedVersion =
                true

        } catch {
            print(
                "CREATE RECIPE VERSION ERROR:",
                error.localizedDescription
            )
        }
    }

    // MARK: - Ingredients Formatting

    private func ingredientQuantity(
        _ ingredient: RecipeIngredient
    ) -> String {
        IngredientQuantityFormatter.formattedMeasurement(
            quantity: ingredient.quantity,
            unit: ingredient.unit
        )
    }


    // MARK: - Instruction Parsing

    private func parsedInstructions(
        _ raw: String?
    ) -> [String] {
        guard let raw else {
            return []
        }

        return raw
            .components(separatedBy: .newlines)
            .map {
                $0.trimmingCharacters(
                    in: .whitespacesAndNewlines
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

    private func cleaned(
        _ value: String?
    ) -> String? {
        guard let value else {
            return nil
        }

        let cleaned =
            value.trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        return cleaned.isEmpty
            ? nil
            : cleaned
    }
    
    private var addNoteSheet: some View {
        NavigationStack {
            VStack(
                alignment: .leading,
                spacing: KinSpacing.large
            ) {
                Text("Add a note about this recipe.")
                    .font(KinTypography.body)
                    .foregroundStyle(
                        KinColors.secondaryText
                    )

                TextEditor(
                    text: $newNoteText
                )
                .font(KinTypography.body)
                .frame(minHeight: 180)
                .padding(KinSpacing.small)
                .scrollContentBackground(.hidden)
                .background(KinColors.surface)
                .clipShape(
                    RoundedRectangle(
                        cornerRadius: KinRadius.medium
                    )
                )

                Spacer()
            }
            .padding(KinSpacing.large)
            .background(
                KinColors.background
                    .ignoresSafeArea()
            )
            .navigationTitle("Add Note")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(
                    placement: .cancellationAction
                ) {
                    Button("Cancel") {
                        newNoteText = ""
                        showingAddNote = false
                    }
                }

                ToolbarItem(
                    placement: .confirmationAction
                ) {
                    Button(
                        isSavingNote
                            ? "Saving..."
                            : "Save"
                    ) {
                        Task {
                            await saveNote()
                        }
                    }
                    .disabled(
                        isSavingNote ||
                        newNoteText
                            .trimmingCharacters(
                                in: .whitespacesAndNewlines
                            )
                            .isEmpty
                    )
                }
            }
        }
    }
    
    // MARK: - Versions Sheet

    private var versionsSheet: some View {
        NavigationStack {
            ZStack {
                KinColors.background
                    .ignoresSafeArea()

                if versions.isEmpty {
                    emptySection(
                        icon: "square.stack.3d.up",
                        title: "No Versions Yet",
                        message:
                            "When someone creates their own version of this recipe, it will appear here."
                    )
                    .padding(KinSpacing.large)

                } else {
                    ScrollView {
                        VStack(
                            alignment: .leading,
                            spacing: KinSpacing.medium
                        ) {
                            ForEach(versions) { version in
                                Button {
                                    selectedVersionId =
                                        version.id

                                    showingVersions = false

                                    DispatchQueue.main.async {
                                        showingSelectedVersion =
                                            true
                                    }
                                } label: {
                                    KinCard {
                                        HStack(
                                            spacing:
                                                KinSpacing.medium
                                        ) {
                                            VStack(
                                                alignment: .leading,
                                                spacing:
                                                    KinSpacing.small
                                            ) {
                                                Text(version.name)
                                                    .font(
                                                        KinTypography.title3
                                                    )
                                                    .foregroundStyle(
                                                        KinColors.primaryText
                                                    )

                                                Text("View Version")
                                                    .font(
                                                        KinTypography.caption
                                                    )
                                                    .foregroundStyle(
                                                        KinColors.secondaryText
                                                    )
                                            }

                                            Spacer()

                                            Image(
                                                systemName:
                                                    "chevron.right"
                                            )
                                            .foregroundStyle(
                                                KinColors.primary
                                            )
                                        }
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(KinSpacing.large)
                    }
                }
            }
            .navigationTitle("Versions")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(
                    placement: .cancellationAction
                ) {
                    Button("Done") {
                        showingVersions = false
                    }
                }
            }
        }
    }
    
    @MainActor
    private func saveNote() async {
        guard !isSavingNote else {
            return
        }

        let cleanText =
            newNoteText.trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        guard !cleanText.isEmpty else {
            return
        }

        isSavingNote = true

        defer {
            isSavingNote = false
        }

        do {
            let created =
                try await RecipeService
                    .createRecipeStory(
                        recipeId: recipeId,
                        story: cleanText
                    )

            stories.insert(
                created,
                at: 0
            )

            newNoteText = ""
            showingAddNote = false

        } catch {
            print(
                "RECIPE NOTE SAVE ERROR:",
                error.localizedDescription
            )
        }
    }
    
    private func formattedStoryDate(
        _ rawDate: String
    ) -> String {
        let formatter =
            ISO8601DateFormatter()

        guard
            let date =
                formatter.date(
                    from: rawDate
                )
        else {
            return ""
        }

        return date.formatted(
            date: .abbreviated,
            time: .omitted
        )
    }
}

#Preview {
    NavigationStack {
        RecipeDetailView(
            recipeId: UUID()
        )
    }
}

//
//  CookbookDetailView.swift
//  KinKitchen
//
//  Created by Greg Hudler on 9/23/26.
//

import SwiftUI
import PhotosUI
import UIKit

struct CookbookDetailView: View {

    let cookbookId: UUID

    @Environment(\.dismiss) private var dismiss

    @State private var cookbook: Cookbook?
    @State private var coverImage: UIImage?
    @State private var selectedCoverItem: PhotosPickerItem?
    @State private var isUpdatingCover = false
    
    
    @State private var recipes: [Recipe] = []
    @State private var relationships: [CookbookRecipe] = []
    @State private var sections: [CookbookSection] = []

    @State private var isShowingNewSection = false
    @State private var sectionNameDraft = ""
    @State private var sectionToRename: CookbookSection?
    @State private var sectionToDelete: CookbookSection?
    @State private var isSavingSection = false
    @State private var sectionErrorMessage: String?
    @State private var selectedRecipeId: UUID?
    @State private var recipeToRemove: Recipe?

    @State private var isLoading = true
    @State private var errorMessage: String?

    @State private var isShowingRecipePicker = false
    @State private var isShowingCoverPicker = false
    @State private var isRemovingRecipe = false
    @State private var isShowingEditCookbook = false
    @State private var isShowingDeleteConfirmation = false
    @State private var isDeletingCookbook = false

    var body: some View {
        ZStack {
            KinColors.background
                .ignoresSafeArea()

            content
        }
        .navigationBarHidden(true)
        .task {
            await loadCookbook()
        }
        .refreshable {
            await loadCookbook()
        }
        .photosPicker(
            isPresented: $isShowingCoverPicker,
            selection: $selectedCoverItem,
            matching: .images
        )
        .onChange(of: selectedCoverItem) {

            guard selectedCoverItem != nil else {
                return
            }

            Task {
                await updateCookbookCover()
            }
        }
        .sheet(
            isPresented: $isShowingRecipePicker
        ) {
            AddCookbookRecipesView(
                cookbookId: cookbookId,
                existingRecipeIds: Set(
                    recipes.map(\.id)
                ),
                onRecipesAdded: {
                    await loadCookbook(
                        showLoadingState: false
                    )
                }
            )
        }
        .sheet(
            isPresented: $isShowingEditCookbook
        ) {
            if let cookbook {
                EditCookbookView(
                    cookbook: cookbook,
                    onUpdated: { updatedCookbook in
                        self.cookbook = updatedCookbook
                    }
                )
            }
        }
        .confirmationDialog(
            "Delete Cookbook?",
            isPresented: $isShowingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button(
                "Delete Cookbook",
                role: .destructive
            ) {
                Task {
                    await deleteCookbook()
                }
            }

            Button(
                "Cancel",
                role: .cancel
            ) {
            }
        } message: {
            Text(
                "This permanently deletes the cookbook and removes its recipe organization. Your original recipes will not be deleted."
            )
        }
        .confirmationDialog(
            "Remove Recipe?",
            isPresented: Binding(
                get: {
                    recipeToRemove != nil
                },
                set: {
                    if !$0 {
                        recipeToRemove = nil
                    }
                }
            ),
            titleVisibility: .visible
        ) {
            if let recipeToRemove {
                Button(
                    "Remove \(recipeToRemove.name)",
                    role: .destructive
                ) {
                    Task {
                        await removeRecipe(
                            recipeToRemove
                        )
                    }
                }

                Button(
                    "Cancel",
                    role: .cancel
                ) {
                    self.recipeToRemove = nil
                }
            }
        } message: {
            Text(
                "This removes the recipe from this cookbook. The original recipe will not be deleted."
            )
        }
        // MARK: - Section Dialogs
        .alert(
            "New Section",
            isPresented: $isShowingNewSection
        ) {
            TextField(
                "e.g. Desserts",
                text: $sectionNameDraft
            )
            .textInputAutocapitalization(.words)

            Button("Add") {
                Task {
                    await createSection()
                }
            }

            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Group recipes in this cookbook, like Appetizers or Family Favorites.")
        }
        .alert(
            "Rename Section",
            isPresented: Binding(
                get: { sectionToRename != nil },
                set: { if !$0 { sectionToRename = nil } }
            )
        ) {
            TextField(
                "Section name",
                text: $sectionNameDraft
            )
            .textInputAutocapitalization(.words)

            Button("Save") {
                if let section = sectionToRename {
                    Task {
                        await renameSection(section)
                    }
                }
            }

            Button("Cancel", role: .cancel) {}
        }
        .confirmationDialog(
            "Delete Section?",
            isPresented: Binding(
                get: { sectionToDelete != nil },
                set: { if !$0 { sectionToDelete = nil } }
            ),
            titleVisibility: .visible
        ) {
            if let section = sectionToDelete {
                Button(
                    "Delete \(section.name)",
                    role: .destructive
                ) {
                    Task {
                        await deleteSection(section)
                    }
                }
            }

            Button("Cancel", role: .cancel) {}
        } message: {
            Text(
                "Its recipes move to Unsorted. No recipes are deleted."
            )
        }
        .navigationDestination(
            isPresented: Binding(
                get: {
                    selectedRecipeId != nil
                },
                set: {
                    if !$0 {
                        selectedRecipeId = nil
                    }
                }
            )
        ) {
            if let selectedRecipeId {
                RecipeDetailView(
                    recipeId: selectedRecipeId,
                    onBack: {
                        self.selectedRecipeId = nil
                    }
                )
            }
        }
    }
}

// MARK: - Content

private extension CookbookDetailView {

    @ViewBuilder
    var content: some View {
        if isLoading {
            loadingState
        } else if let errorMessage {
            errorState(errorMessage)
        } else if let cookbook {
            cookbookContent(cookbook)
        }
    }
}

// MARK: - Cookbook Content

private extension CookbookDetailView {

    func cookbookContent(
        _ cookbook: Cookbook
    ) -> some View {
        ScrollView {
            VStack(
                alignment: .leading,
                spacing: KinSpacing.xLarge
            ) {
                header(cookbook)

                cookbookInformation(cookbook)

                recipesSection
            }
            .padding(
                .horizontal,
                KinSpacing.large
            )
            .padding(
                .bottom,
                KinSpacing.xxLarge
            )
        }
    }
}

// MARK: - Header

private extension CookbookDetailView {

    func header(
        _ cookbook: Cookbook
    ) -> some View {
        VStack(
            alignment: .leading,
            spacing: KinSpacing.large
        ) {
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
                        width: 44,
                        height: 44
                    )
                    .background(
                        KinColors.surface
                    )
                    .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Back")

                Spacer()

                Menu {
                    Button {
                        isShowingRecipePicker = true
                    } label: {
                        Label(
                            "Add Recipes",
                            systemImage: "plus"
                        )
                    }
                    
                    Button {
                        isShowingCoverPicker = true
                    } label: {
                        Label(
                            cookbook.coverPath == nil
                                ? "Add Cover Image"
                                : "Change Cover Image",
                            systemImage: "photo"
                        )
                    }

                    Divider()

                    Button {
                        isShowingEditCookbook = true
                    } label: {
                        Label(
                            "Edit Cookbook",
                            systemImage: "pencil"
                        )
                    }

                    Button(
                        role: .destructive
                    ) {
                        isShowingDeleteConfirmation = true
                    } label: {
                        Label(
                            "Delete Cookbook",
                            systemImage: "trash"
                        )
                    }
                } label: {
                    Image(
                        systemName: "ellipsis"
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
                        width: 44,
                        height: 44
                    )
                    .background(
                        KinColors.surface
                    )
                    .clipShape(Circle())
                }
            }

            cookbookCover(cookbook)

            Text(cookbook.name)
                .font(
                    KinTypography.largeTitle
                )
                .foregroundStyle(
                    KinColors.primaryText
                )
        }
        .padding(
            .top,
            KinSpacing.large
        )
    }
}

// MARK: - Cookbook Cover

private extension CookbookDetailView {

    func cookbookCover(
        _ cookbook: Cookbook
    ) -> some View {

        ZStack {

            RoundedRectangle(
                cornerRadius: KinRadius.medium
            )
            .fill(
                KinColors.primary.opacity(0.12)
            )

            if let coverImage {

                Image(
                    uiImage: coverImage
                )
                .resizable()
                .scaledToFill()

            } else if isUpdatingCover {

                ProgressView()
                    .tint(
                        KinColors.primary
                    )

            } else {

                Image(
                    systemName: KinIcons.cookbooks
                )
                .font(
                    .system(
                        size: 54,
                        weight: .semibold
                    )
                )
                .foregroundStyle(
                    KinColors.primary
                )
            }
        }
        .frame(
            maxWidth: .infinity
        )
        .frame(
            height: 190
        )
        .clipShape(
            RoundedRectangle(
                cornerRadius: KinRadius.medium
            )
        )
    }
}

// MARK: - Cookbook Information

private extension CookbookDetailView {

    @ViewBuilder
    func cookbookInformation(
        _ cookbook: Cookbook
    ) -> some View {
        if let description = cookbook.description,
           !description.isEmpty {
            Text(description)
                .font(
                    KinTypography.body
                )
                .foregroundStyle(
                    KinColors.secondaryText
                )
        }
    }
}

// MARK: - Recipes

private extension CookbookDetailView {

    var recipesSection: some View {
        VStack(
            alignment: .leading,
            spacing: KinSpacing.medium
        ) {
            HStack {
                Text("Recipes")
                    .font(
                        KinTypography.title
                    )
                    .foregroundStyle(
                        KinColors.primaryText
                    )

                Spacer()

                Text("\(recipes.count)")
                    .font(
                        KinTypography.headline
                    )
                    .foregroundStyle(
                        KinColors.secondaryText
                    )

                Button {
                    isShowingRecipePicker = true
                } label: {
                    Image(
                        systemName: "plus"
                    )
                    .font(
                        .system(
                            size: 16,
                            weight: .bold
                        )
                    )
                    .foregroundStyle(.white)
                    .frame(
                        width: 34,
                        height: 34
                    )
                    .background(
                        KinColors.primary
                    )
                    .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(
                    "Add Recipes"
                )
            }

            if let sectionErrorMessage {
                Text(sectionErrorMessage)
                    .font(KinTypography.caption)
                    .foregroundStyle(KinColors.error)
            }

            if recipes.isEmpty && sections.isEmpty {
                emptyRecipesState
            } else {
                LazyVStack(
                    alignment: .leading,
                    spacing: KinSpacing.large
                ) {
                    ForEach(sections) { section in
                        sectionBlock(section)
                    }

                    // Recipes not in any section. Only labeled once
                    // there are sections to tell them apart from.
                    let unsorted = unsortedRecipes
                    if !unsorted.isEmpty || sections.isEmpty {
                        VStack(
                            alignment: .leading,
                            spacing: KinSpacing.medium
                        ) {
                            if !sections.isEmpty {
                                sectionHeading(
                                    "Unsorted",
                                    count: unsorted.count
                                )
                            }

                            ForEach(unsorted) { recipe in
                                recipeRow(recipe)
                            }
                        }
                    }
                }
            }

            Button {
                sectionNameDraft = ""
                isShowingNewSection = true
            } label: {
                Label(
                    "New Section",
                    systemImage: "folder.badge.plus"
                )
                .font(KinTypography.headline)
                .foregroundStyle(KinColors.primary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, KinSpacing.medium)
                .background(
                    KinColors.primary.opacity(0.10)
                )
                .clipShape(
                    RoundedRectangle(
                        cornerRadius: KinRadius.medium
                    )
                )
            }
            .buttonStyle(.plain)
            .disabled(isSavingSection)
        }
    }

    // MARK: - Sections

    /// Recipes in a section, in saved order.
    func recipes(
        in section: CookbookSection
    ) -> [Recipe] {
        let recipeIds =
            relationships
                .filter { $0.sectionId == section.id }
                .map(\.recipeId)

        return recipes.filter {
            recipeIds.contains($0.id)
        }
        .sorted { first, second in
            (recipeIds.firstIndex(of: first.id) ?? 0)
                < (recipeIds.firstIndex(of: second.id) ?? 0)
        }
    }

    /// Recipes without a section, or whose section no longer exists.
    var unsortedRecipes: [Recipe] {
        let sectionIds =
            Set(sections.map(\.id))

        let sectionedRecipeIds =
            Set(
                relationships
                    .filter {
                        guard let sectionId = $0.sectionId else {
                            return false
                        }
                        return sectionIds.contains(sectionId)
                    }
                    .map(\.recipeId)
            )

        return recipes.filter {
            !sectionedRecipeIds.contains($0.id)
        }
    }

    func sectionBlock(
        _ section: CookbookSection
    ) -> some View {
        let sectionRecipes =
            recipes(in: section)

        return VStack(
            alignment: .leading,
            spacing: KinSpacing.medium
        ) {
            HStack(
                alignment: .firstTextBaseline
            ) {
                sectionHeading(
                    section.name,
                    count: sectionRecipes.count
                )

                Menu {
                    Button {
                        sectionNameDraft = section.name
                        sectionToRename = section
                    } label: {
                        Label("Rename Section", systemImage: "pencil")
                    }

                    Button(role: .destructive) {
                        sectionToDelete = section
                    } label: {
                        Label("Delete Section", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.title3)
                        .foregroundStyle(KinColors.secondaryText)
                        .frame(width: 44, height: 32)
                }
                .accessibilityLabel("\(section.name) options")
            }

            if sectionRecipes.isEmpty {
                Text("No recipes in this section yet.")
                    .font(KinTypography.footnote)
                    .foregroundStyle(KinColors.secondaryText)
                    .frame(
                        maxWidth: .infinity,
                        alignment: .leading
                    )
                    .padding(KinSpacing.medium)
                    .background(KinColors.surface.opacity(0.6))
                    .clipShape(
                        RoundedRectangle(
                            cornerRadius: KinRadius.medium
                        )
                    )
            } else {
                ForEach(sectionRecipes) { recipe in
                    recipeRow(recipe)
                }
            }
        }
    }

    func sectionHeading(
        _ title: String,
        count: Int
    ) -> some View {
        HStack(
            alignment: .firstTextBaseline,
            spacing: KinSpacing.small
        ) {
            Text(title)
                .font(KinTypography.title3)
                .foregroundStyle(KinColors.primaryText)
                .lineLimit(2)

            Text("\(count)")
                .font(KinTypography.caption)
                .foregroundStyle(KinColors.secondaryText)

            Spacer(minLength: 0)
        }
    }

    @MainActor
    func createSection() async {
        guard !isSavingSection else {
            return
        }

        isSavingSection = true
        sectionErrorMessage = nil

        defer {
            isSavingSection = false
        }

        do {
            let section =
                try await CookbookService.createSection(
                    name: sectionNameDraft,
                    in: cookbookId,
                    after: sections
                )

            sections.append(section)

        } catch {
            sectionErrorMessage =
                error.localizedDescription
        }
    }

    @MainActor
    func renameSection(
        _ section: CookbookSection
    ) async {
        guard !isSavingSection else {
            return
        }

        isSavingSection = true
        sectionErrorMessage = nil

        defer {
            isSavingSection = false
        }

        do {
            let updated =
                try await CookbookService.renameSection(
                    section,
                    to: sectionNameDraft
                )

            if let index =
                sections.firstIndex(where: {
                    $0.id == section.id
                }) {
                sections[index] = updated
            }

        } catch {
            sectionErrorMessage =
                error.localizedDescription
        }
    }

    @MainActor
    func deleteSection(
        _ section: CookbookSection
    ) async {
        guard !isSavingSection else {
            return
        }

        isSavingSection = true
        sectionErrorMessage = nil

        defer {
            isSavingSection = false
        }

        do {
            try await CookbookService.deleteSection(
                section
            )

            // Reload so its recipes show under Unsorted, as stored.
            await loadCookbook(
                showLoadingState: false
            )

        } catch {
            sectionErrorMessage =
                error.localizedDescription
        }
    }

    var emptyRecipesState: some View {
        VStack(
            spacing: KinSpacing.medium
        ) {
            Image(
                systemName: "fork.knife"
            )
            .font(
                .system(size: 36)
            )
            .foregroundStyle(
                KinColors.primary
            )

            Text("No Recipes Yet")
                .font(
                    KinTypography.title3
                )
                .foregroundStyle(
                    KinColors.primaryText
                )

            Text(
                "Add recipes to start building this cookbook."
            )
            .font(
                KinTypography.body
            )
            .foregroundStyle(
                KinColors.secondaryText
            )
            .multilineTextAlignment(.center)

            Button {
                isShowingRecipePicker = true
            } label: {
                Label(
                    "Add Recipes",
                    systemImage: "plus"
                )
                .font(
                    KinTypography.headline
                )
                .foregroundStyle(.white)
                .padding(
                    .horizontal,
                    KinSpacing.large
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
        }
        .frame(
            maxWidth: .infinity
        )
        .padding(
            .vertical,
            KinSpacing.xxLarge
        )
        .padding(
            .horizontal,
            KinSpacing.large
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

    func recipeRow(
        _ recipe: Recipe
    ) -> some View {
        HStack(
            spacing: KinSpacing.small
        ) {
            Button {
                selectedRecipeId = recipe.id
            } label: {
                recipeCard(recipe)
            }
            .buttonStyle(.plain)

            Button {
                recipeToRemove = recipe
            } label: {
                Image(
                    systemName: "minus.circle.fill"
                )
                .font(
                    .system(size: 24)
                )
                .foregroundStyle(
                    KinColors.error
                )
                .frame(
                    width: 36,
                    height: 44
                )
            }
            .buttonStyle(.plain)
            .disabled(isRemovingRecipe)
            .accessibilityLabel(
                "Remove \(recipe.name)"
            )
        }
    }

    func recipeCard(
        _ recipe: Recipe
    ) -> some View {
        HStack(
            spacing: KinSpacing.medium
        ) {
            ZStack {
                RoundedRectangle(
                    cornerRadius: KinRadius.medium
                )
                .fill(
                    KinColors.primary.opacity(0.12)
                )

                Image(
                    systemName: "fork.knife"
                )
                .font(
                    .system(
                        size: 24,
                        weight: .semibold
                    )
                )
                .foregroundStyle(
                    KinColors.primary
                )
            }
            .frame(
                width: 64,
                height: 64
            )

            Text(recipe.name)
                .font(
                    KinTypography.headline
                )
                .foregroundStyle(
                    KinColors.primaryText
                )
                .multilineTextAlignment(
                    .leading
                )
                .lineLimit(2)

            Spacer()

            Image(
                systemName: "chevron.right"
            )
            .font(
                .system(
                    size: 14,
                    weight: .semibold
                )
            )
            .foregroundStyle(
                KinColors.secondaryText
            )
        }
        .padding(
            KinSpacing.medium
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
                cornerRadius: KinRadius.medium
            )
        )
    }
}

// MARK: - Loading State

private extension CookbookDetailView {

    var loadingState: some View {
        VStack(
            spacing: KinSpacing.medium
        ) {
            ProgressView()
                .tint(
                    KinColors.primary
                )

            Text("Loading cookbook...")
                .font(
                    KinTypography.body
                )
                .foregroundStyle(
                    KinColors.secondaryText
                )
        }
        .frame(
            maxWidth: .infinity,
            maxHeight: .infinity
        )
    }
}

// MARK: - Error State

private extension CookbookDetailView {

    func errorState(
        _ message: String
    ) -> some View {
        VStack(
            spacing: KinSpacing.medium
        ) {
            Spacer()

            Image(
                systemName:
                    "exclamationmark.triangle.fill"
            )
            .font(
                .system(size: 42)
            )
            .foregroundStyle(
                KinColors.error
            )

            Text("Unable to Load Cookbook")
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
                .padding(
                    .horizontal,
                    KinSpacing.xxLarge
                )

            Button {
                Task {
                    await loadCookbook()
                }
            } label: {
                Text("Try Again")
                    .font(
                        KinTypography.headline
                    )
                    .foregroundStyle(.white)
                    .padding(
                        .horizontal,
                        KinSpacing.large
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

            Spacer()
        }
        .frame(
            maxWidth: .infinity,
            maxHeight: .infinity
        )
    }
}

// MARK: - Load Cookbook

private extension CookbookDetailView {

    @MainActor
    func loadCookbook(
        showLoadingState: Bool = true
    ) async {
        if showLoadingState {
            isLoading = true
        }

        errorMessage = nil

        do {
            async let cookbookRequest =
                CookbookService.fetchCookbook(
                    id: cookbookId
                )

            async let contentsRequest =
                CookbookService.fetchContents(
                    cookbookId: cookbookId
                )

            let (
                loadedCookbook,
                contents
            ) = try await (
                cookbookRequest,
                contentsRequest
            )

            cookbook = loadedCookbook
            relationships = contents.relationships

            // Saved order; recipes that no longer exist are skipped.
            recipes =
                contents.relationships.compactMap {
                    contents.recipesById[$0.recipeId]
                }

            // Sections are supplemental: if they can't load, the
            // cookbook still shows every recipe as Unsorted.
            sections =
                (try? await CookbookService
                    .fetchSections(
                        cookbookId: cookbookId
                    )) ?? []

            await loadCookbookCover(
                path: loadedCookbook.coverPath
            )
            isLoading = false
        } catch is CancellationError {
            isLoading = false
        } catch {
            errorMessage =
                error.localizedDescription

            isLoading = false
        }
    }
}


// MARK: - Cookbook Cover Loading

private extension CookbookDetailView {

    @MainActor
    func loadCookbookCover(
        path: String?
    ) async {

        guard let path,
              !path.isEmpty else {

            coverImage = nil
            return
        }

        do {

            let data =
                try await CookbookService
                    .fetchCookbookCover(
                        path: path
                    )

            coverImage =
                UIImage(data: data)

        } catch is CancellationError {

        } catch {

            coverImage = nil
        }
    }

    @MainActor
    func updateCookbookCover() async {

        guard let selectedCoverItem,
              let cookbook,
              !isUpdatingCover else {
            return
        }

        isUpdatingCover = true
        errorMessage = nil

        do {

            guard let data =
                try await selectedCoverItem
                    .loadTransferable(
                        type: Data.self
                    ),
                  let image =
                    UIImage(data: data),
                  let jpegData =
                    image.jpegData(
                        compressionQuality: 0.85
                    )
            else {

                isUpdatingCover = false
                return
            }

            let updatedCookbook =
                try await CookbookService
                    .replaceCookbookCover(
                        cookbook: cookbook,
                        imageData: jpegData
                    )

            self.cookbook =
                updatedCookbook

            coverImage =
                image

            self.selectedCoverItem = nil

            isUpdatingCover = false

        } catch is CancellationError {

            isUpdatingCover = false

        } catch {

            errorMessage =
                error.localizedDescription

            isUpdatingCover = false
        }
    }
}

// MARK: - Delete Cookbook

private extension CookbookDetailView {

    @MainActor
    func deleteCookbook() async {

        guard !isDeletingCookbook else {
            return
        }

        isDeletingCookbook = true
        errorMessage = nil

        do {

            try await CookbookService
                .deleteCookbook(
                    id: cookbookId
                )

            dismiss()

        } catch is CancellationError {

            isDeletingCookbook = false

        } catch {

            errorMessage =
                error.localizedDescription

            isDeletingCookbook = false
        }
    }
}

// MARK: - Remove Recipe

private extension CookbookDetailView {

    @MainActor
    func removeRecipe(
        _ recipe: Recipe
    ) async {
        guard !isRemovingRecipe else {
            return
        }

        isRemovingRecipe = true

        do {
            try await CookbookService.removeRecipe(
                recipeId: recipe.id,
                from: cookbookId
            )

            recipeToRemove = nil

            recipes.removeAll {
                $0.id == recipe.id
            }
        } catch is CancellationError {
            recipeToRemove = nil
        } catch {
            errorMessage =
                error.localizedDescription

            recipeToRemove = nil
        }

        isRemovingRecipe = false
    }
}

// MARK: - Edit Cookbook View

private struct EditCookbookView: View {

    let cookbook: Cookbook
    let onUpdated: (Cookbook) -> Void

    @Environment(\.dismiss)
    private var dismiss

    @State private var name: String
    @State private var description: String

    @State private var isSaving = false
    @State private var errorMessage: String?

    init(
        cookbook: Cookbook,
        onUpdated: @escaping (Cookbook) -> Void
    ) {
        self.cookbook = cookbook
        self.onUpdated = onUpdated

        _name =
            State(
                initialValue: cookbook.name
            )

        _description =
            State(
                initialValue:
                    cookbook.description ?? ""
            )
    }

    var body: some View {

        NavigationStack {

            ZStack {

                KinColors.background
                    .ignoresSafeArea()

                ScrollView {

                    VStack(
                        alignment: .leading,
                        spacing: KinSpacing.xLarge
                    ) {

                        cookbookInformation

                        if let errorMessage {
                            errorCard(
                                errorMessage
                            )
                        }
                    }
                    .padding(
                        KinSpacing.large
                    )
                }
            }
            .navigationTitle(
                "Edit Cookbook"
            )
            .navigationBarTitleDisplayMode(
                .inline
            )
            .toolbar {

                ToolbarItem(
                    placement:
                        .cancellationAction
                ) {

                    Button("Cancel") {
                        dismiss()
                    }
                    .disabled(isSaving)
                }

                ToolbarItem(
                    placement:
                        .confirmationAction
                ) {

                    Button("Save") {

                        Task {
                            await saveCookbook()
                        }
                    }
                    .fontWeight(.semibold)
                    .disabled(
                        !canSave ||
                        isSaving
                    )
                }
            }
            .interactiveDismissDisabled(
                isSaving
            )
        }
    }
}

// MARK: - Edit Cookbook Information

private extension EditCookbookView {

    var cookbookInformation: some View {

        VStack(
            alignment: .leading,
            spacing: KinSpacing.medium
        ) {

            Text("Cookbook Information")
                .font(
                    KinTypography.headline
                )
                .foregroundStyle(
                    KinColors.primaryText
                )

            VStack(
                alignment: .leading,
                spacing: KinSpacing.small
            ) {

                Text("Name")
                    .font(
                        KinTypography.body
                    )
                    .foregroundStyle(
                        KinColors.primaryText
                    )

                TextField(
                    "Cookbook Name",
                    text: $name
                )
                .textInputAutocapitalization(
                    .words
                )
                .submitLabel(.done)
                .padding(
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

            VStack(
                alignment: .leading,
                spacing: KinSpacing.small
            ) {

                Text("Description")
                    .font(
                        KinTypography.body
                    )
                    .foregroundStyle(
                        KinColors.primaryText
                    )

                TextField(
                    "Add a description...",
                    text: $description,
                    axis: .vertical
                )
                .lineLimit(4...8)
                .padding(
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

                Text("Optional")
                    .font(
                        KinTypography.caption
                    )
                    .foregroundStyle(
                        KinColors.secondaryText
                    )
            }
        }
    }
}

// MARK: - Edit Cookbook Error

private extension EditCookbookView {

    func errorCard(
        _ message: String
    ) -> some View {

        HStack(
            alignment: .top,
            spacing: KinSpacing.medium
        ) {

            Image(
                systemName:
                    "exclamationmark.triangle.fill"
            )
            .foregroundStyle(
                KinColors.error
            )

            VStack(
                alignment: .leading,
                spacing: KinSpacing.xSmall
            ) {

                Text(
                    "Unable to Update Cookbook"
                )
                .font(
                    KinTypography.headline
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
            }

            Spacer()
        }
        .padding(
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
}

// MARK: - Edit Cookbook Validation

private extension EditCookbookView {

    var cleanName: String {

        name.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
    }

    var canSave: Bool {
        !cleanName.isEmpty
    }
}

// MARK: - Save Cookbook Changes

private extension EditCookbookView {

    @MainActor
    func saveCookbook() async {

        guard canSave,
              !isSaving else {
            return
        }

        isSaving = true
        errorMessage = nil

        do {

            let updatedCookbook =
                try await CookbookService
                    .updateCookbook(
                        id: cookbook.id,
                        name: cleanName,
                        description:
                            description,
                        coverPath:
                            cookbook.coverPath
                    )

            onUpdated(
                updatedCookbook
            )

            isSaving = false

            dismiss()

        } catch is CancellationError {

            isSaving = false

        } catch {

            errorMessage =
                error.localizedDescription

            isSaving = false
        }
    }
}


// MARK: - Add Cookbook Recipes View

private struct AddCookbookRecipesView: View {

    let cookbookId: UUID
    let existingRecipeIds: Set<UUID>
    let onRecipesAdded: () async -> Void

    @Environment(\.dismiss)
    private var dismiss

    @State private var recipes: [Recipe] = []
    @State private var selectedRecipeIds:
        Set<UUID> = []

    @State private var isLoading = true
    @State private var isSaving = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ZStack {
                KinColors.background
                    .ignoresSafeArea()

                content
            }
            .navigationTitle("Add Recipes")
            .navigationBarTitleDisplayMode(
                .inline
            )
            .toolbar {
                ToolbarItem(
                    placement: .cancellationAction
                ) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .disabled(isSaving)
                }

                ToolbarItem(
                    placement: .confirmationAction
                ) {
                    Button("Add") {
                        Task {
                            await addSelectedRecipes()
                        }
                    }
                    .disabled(
                        selectedRecipeIds.isEmpty ||
                        isSaving
                    )
                }
            }
            .task {
                await loadRecipes()
            }
        }
    }
}

// MARK: - Add Recipes Content

private extension AddCookbookRecipesView {

    @ViewBuilder
    var content: some View {
        if isLoading {
            ProgressView()
                .tint(
                    KinColors.primary
                )
        } else if let errorMessage {
            VStack(
                spacing: KinSpacing.medium
            ) {
                Image(
                    systemName:
                        "exclamationmark.triangle.fill"
                )
                .font(
                    .system(size: 36)
                )
                .foregroundStyle(
                    KinColors.error
                )

                Text("Unable to Load Recipes")
                    .font(
                        KinTypography.title3
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
                    KinTypography.headline
                )
                .foregroundStyle(
                    KinColors.primary
                )
            }
            .padding(
                KinSpacing.xLarge
            )
        } else if availableRecipes.isEmpty {
            VStack(
                spacing: KinSpacing.medium
            ) {
                Image(
                    systemName: "checkmark.circle"
                )
                .font(
                    .system(size: 42)
                )
                .foregroundStyle(
                    KinColors.primary
                )

                Text("All Recipes Added")
                    .font(
                        KinTypography.title3
                    )
                    .foregroundStyle(
                        KinColors.primaryText
                    )

                Text(
                    "All of your recipes are already in this cookbook."
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
            .padding(
                KinSpacing.xLarge
            )
        } else {
            recipeList
        }
    }

    var availableRecipes: [Recipe] {
        recipes.filter {
            !existingRecipeIds.contains(
                $0.id
            )
        }
    }
}

// MARK: - Add Recipes List

private extension AddCookbookRecipesView {

    var recipeList: some View {
        ScrollView {
            LazyVStack(
                spacing: KinSpacing.medium
            ) {
                ForEach(
                    availableRecipes
                ) { recipe in
                    Button {
                        toggleRecipe(recipe)
                    } label: {
                        recipeSelectionCard(
                            recipe
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(isSaving)
                }
            }
            .padding(
                KinSpacing.large
            )
        }
    }

    func recipeSelectionCard(
        _ recipe: Recipe
    ) -> some View {
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
                        .opacity(0.12)
                )

                Image(
                    systemName:
                        "fork.knife"
                )
                .font(
                    .system(
                        size: 22,
                        weight: .semibold
                    )
                )
                .foregroundStyle(
                    KinColors.primary
                )
            }
            .frame(
                width: 56,
                height: 56
            )

            Text(recipe.name)
                .font(
                    KinTypography.headline
                )
                .foregroundStyle(
                    KinColors.primaryText
                )
                .multilineTextAlignment(
                    .leading
                )

            Spacer()

            Image(
                systemName:
                    selectedRecipeIds
                        .contains(recipe.id)
                    ? "checkmark.circle.fill"
                    : "circle"
            )
            .font(
                .system(size: 24)
            )
            .foregroundStyle(
                selectedRecipeIds
                    .contains(recipe.id)
                ? KinColors.primary
                : KinColors.secondaryText
            )
        }
        .padding(
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
}

// MARK: - Recipe Selection

private extension AddCookbookRecipesView {

    func toggleRecipe(
        _ recipe: Recipe
    ) {
        if selectedRecipeIds.contains(
            recipe.id
        ) {
            selectedRecipeIds.remove(
                recipe.id
            )
        } else {
            selectedRecipeIds.insert(
                recipe.id
            )
        }
    }
}

// MARK: - Load Available Recipes

private extension AddCookbookRecipesView {

    @MainActor
    func loadRecipes() async {
        isLoading = true
        errorMessage = nil

        do {
            recipes =
                try await RecipeService
                    .fetchCurrentUserRecipes()

            isLoading = false
        } catch is CancellationError {
            isLoading = false
        } catch {
            errorMessage =
                error.localizedDescription

            isLoading = false
        }
    }
}

// MARK: - Add Selected Recipes

private extension AddCookbookRecipesView {

    @MainActor
    func addSelectedRecipes() async {
        guard !selectedRecipeIds.isEmpty,
              !isSaving else {
            return
        }

        isSaving = true
        errorMessage = nil

        do {
            for recipeId in selectedRecipeIds {
                _ =
                    try await CookbookService
                        .addRecipe(
                            recipeId: recipeId,
                            to: cookbookId
                        )
            }

            await onRecipesAdded()

            dismiss()
        } catch is CancellationError {
            isSaving = false
        } catch {
            errorMessage =
                error.localizedDescription

            isSaving = false
        }
    }
}

#Preview {
    NavigationStack {
        CookbookDetailView(
            cookbookId: UUID()
        )
    }
}

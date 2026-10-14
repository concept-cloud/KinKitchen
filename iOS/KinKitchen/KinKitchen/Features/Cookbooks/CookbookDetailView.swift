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
    @State private var recipesById: [UUID: Recipe] = [:]
    @State private var sections: [CookbookSection] = []

    @State private var selectedPage: CookbookPage?
    @State private var pageMovesForward = true
    @State private var isShowingEditSections = false
    @State private var pendingEditAction: EditCookbookAction?
    @State private var isShowingPreview = false
    /// The page currently in drag-to-reorder mode, if any.
    @State private var editingPage: CookbookPage?

    @State private var isShowingNewSection = false
    @State private var sectionNameDraft = ""
    @State private var isSavingSection = false
    @State private var sectionErrorMessage: String?
    @State private var isMovingRecipe = false
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
    @State private var deleteErrorMessage: String?

    var body: some View {
        ZStack {
            KinColors.background
                .ignoresSafeArea()

            content
        }
        .deletingOverlay(isDeletingCookbook)
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
            isPresented: $isShowingEditCookbook,
            onDismiss: {
                // Cover and delete open once the sheet has closed.
                switch pendingEditAction {
                case .changeCover:
                    isShowingCoverPicker = true
                case .delete:
                    isShowingDeleteConfirmation = true
                case nil:
                    break
                }
                pendingEditAction = nil
            }
        ) {
            if let cookbook {
                EditCookbookView(
                    cookbook: cookbook,
                    onUpdated: { updatedCookbook in
                        self.cookbook = updatedCookbook
                    },
                    onAction: { action in
                        pendingEditAction = action
                    }
                )
            }
        }
        .deleteConfirmation(
            "Delete \"\(cookbook?.name ?? "Cookbook")\"?",
            isPresented: $isShowingDeleteConfirmation,
            message: "This permanently deletes the cookbook, its sections, and its cover. Your recipes will not be deleted. This can't be undone."
        ) {
            Task {
                await deleteCookbook()
            }
        }
        .deleteFailedAlert($deleteErrorMessage)
        .alert(
            "Remove \"\(recipeToRemove?.name ?? "Recipe")\"?",
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
            presenting: recipeToRemove
        ) { recipe in
            Button(
                "Cancel",
                role: .cancel
            ) {}

            Button(
                "Remove",
                role: .destructive
            ) {
                Task {
                    await removeRecipe(recipe)
                }
            }
        } message: { _ in
            Text(
                "This removes the recipe from this cookbook. The original recipe will not be deleted."
            )
        }
        // MARK: - Preview
        .fullScreenCover(
            isPresented: $isShowingPreview
        ) {
            if let cookbook {
                CookbookPreviewView(
                    cookbook: cookbook,
                    coverImage: coverImage,
                    chapters: previewChapters
                )
            }
        }
        // MARK: - Section Dialogs
        .sheet(
            isPresented: $isShowingEditSections,
            onDismiss: {
                // Pick up every change made in the sheet, as stored.
                Task {
                    await loadCookbook(showLoadingState: false)
                }
            }
        ) {
            EditCookbookSectionsView(
                cookbookId: cookbookId,
                sections: sections
            )
        }
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

// MARK: - Cookbook Page

/// A swipeable page in Cookbook Detail: one section, or Unsorted.
enum CookbookPage: Hashable {
    case section(UUID)
    case unsorted
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

    /// Cover and title stay put at the top; below them, each section
    /// is its own page that scrolls on its own.
    func cookbookContent(
        _ cookbook: Cookbook
    ) -> some View {
        ScrollView {
            LazyVStack(
                alignment: .leading,
                spacing: KinSpacing.medium,
                pinnedViews: [.sectionHeaders]
            ) {
                cookbookHero(cookbook)

                VStack(
                    alignment: .leading,
                    spacing: KinSpacing.medium
                ) {
                    if let sectionErrorMessage {
                        Text(sectionErrorMessage)
                            .font(KinTypography.caption)
                            .foregroundStyle(KinColors.error)
                            .padding(.horizontal, KinSpacing.large)
                    }

                    if recipes.isEmpty && sections.isEmpty {
                        VStack(spacing: KinSpacing.medium) {
                            emptyRecipesState
                            newSectionButton
                        }
                        .padding(.horizontal, KinSpacing.large)
                    } else {
                        ZStack(alignment: .top) {
                            pageView(currentPage)
                                .id(currentPage)
                                .transition(pageTransition)
                        }
                        .clipped()
                        .contentShape(Rectangle())
                        .simultaneousGesture(pageSwipe)
                    }
                }
                // Leave room for the section tabs on the right.
                .padding(
                    .trailing,
                    showsSectionRail ? CookbookSectionRail.width : 0
                )
            }
            .padding(
                .bottom,
                KinSpacing.xxLarge
            )
        }
        .ignoresSafeArea(edges: .top)
        // Back and menu float over the cover.
        .overlay(
            alignment: .top
        ) {
            header(cookbook)
                .padding(.horizontal, KinSpacing.large)
        }
        // The thumb index stays put while the page scrolls under
        // the header, so it's always within reach.
        .overlay(
            alignment: .topTrailing
        ) {
            if showsSectionRail {
                CookbookSectionRail(
                    tabs: railTabs,
                    selectedId: pageSelection.wrappedValue,
                    onSelect: { page in
                        pageSelection.wrappedValue = page
                    }
                )
                .padding(.top, 72)
                .padding(.bottom, KinSpacing.large)
                .ignoresSafeArea(edges: .trailing)
            }
        }
    }

    /// Tabs appear once the cookbook has sections of its own.
    var showsSectionRail: Bool {
        !sections.isEmpty
    }

    var railTabs: [CookbookSectionRail.Tab] {
        pages.map { page in
            CookbookSectionRail.Tab(
                id: page,
                title: title(for: page),
                recipeCount: recipes(on: page).count
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
                        isShowingPreview = true
                    } label: {
                        Label(
                            "Preview Cookbook",
                            systemImage: "book.pages"
                        )
                    }

                    Divider()

                    Button {
                        isShowingRecipePicker = true
                    } label: {
                        Label(
                            "Add Recipes",
                            systemImage: "plus"
                        )
                    }

                    Button {
                        isShowingEditSections = true
                    } label: {
                        Label(
                            "Edit Sections",
                            systemImage: "folder"
                        )
                    }

                    Button {
                        isShowingEditCookbook = true
                    } label: {
                        Label(
                            "Edit Cookbook",
                            systemImage: "pencil"
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

        }
    }
}

// MARK: - Cookbook Cover

private extension CookbookDetailView {

    static let heroHeight: CGFloat = 330

    /// The cover fills the top of the screen, edge to edge, with the
    /// title, description and recipe count over a dark fade. The
    /// section tabs sit on top of it.
    func cookbookHero(
        _ cookbook: Cookbook
    ) -> some View {

        ZStack {

            if let coverImage {

                Color.clear
                    .overlay {
                        Image(uiImage: coverImage)
                            .resizable()
                            .scaledToFill()
                    }
                    .clipped()

            } else {

                LinearGradient(
                    colors: [
                        KinColors.accent.opacity(0.55),
                        KinColors.primary.opacity(0.55)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .overlay {
                    Image(systemName: KinIcons.cookbooks)
                        .font(.system(size: 64, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.5))
                }
            }

            if isUpdatingCover {
                ProgressView()
                    .tint(.white)
            }

            // Top: keeps the clock and buttons readable.
            // Bottom: keeps the title readable.
            LinearGradient(
                stops: [
                    .init(color: KinColors.background.opacity(0.75), location: 0),
                    .init(color: KinColors.background.opacity(0), location: 0.3),
                    .init(color: .black.opacity(0), location: 0.45),
                    .init(color: .black.opacity(0.7), location: 1)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
        .frame(height: Self.heroHeight)
        .frame(maxWidth: .infinity)
        .overlay(
            alignment: .bottomLeading
        ) {
            VStack(
                alignment: .leading,
                spacing: KinSpacing.xSmall
            ) {
                Text(cookbook.name)
                    .font(KinTypography.largeTitle)
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)

                if let description = cookbook.description,
                   !description.isEmpty {
                    Text(description)
                        .font(KinTypography.callout)
                        .opacity(0.9)
                        .lineLimit(2)
                }

                if let count =
                    KinCookbookCoverCard.recipeCountText(recipes.count) {
                    Text(count)
                        .font(KinTypography.subheadline)
                        .opacity(0.9)
                }
            }
            .foregroundStyle(.white)
            .shadow(color: .black.opacity(0.5), radius: 4, y: 1)
            .padding(.leading, KinSpacing.large)
            .padding(
                .trailing,
                KinSpacing.large
                    + (showsSectionRail ? CookbookSectionRail.width : 0)
            )
            .padding(.bottom, KinSpacing.large)
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
    }
}

// MARK: - Recipes

private extension CookbookDetailView {

    /// The cookbook as the preview presents it: sections in saved
    /// order (empty ones included), then Unsorted recipes last.
    /// Built fresh from the current data each time it opens.
    var previewChapters: [CookbookPreviewChapter] {
        let featuredIds =
            Set(
                relationships
                    .filter(\.isFeatured)
                    .map(\.recipeId)
            )

        var chapters =
            sections.map { section in
                CookbookPreviewChapter(
                    id: section.id.uuidString,
                    title: section.name,
                    recipes: recipes(inSection: section.id),
                    featuredRecipeIds: featuredIds
                )
            }

        let unsorted = unsortedRecipes

        if !unsorted.isEmpty {
            chapters.append(
                CookbookPreviewChapter(
                    id: "unsorted",
                    title: sections.isEmpty
                        ? "Recipes"
                        : "More Recipes",
                    recipes: unsorted,
                    featuredRecipeIds: featuredIds
                )
            )
        }

        return chapters
    }

    var currentPage: CookbookPage {
        pageSelection.wrappedValue
    }

    /// The page slides in from the side you're heading toward.
    var pageTransition: AnyTransition {
        .asymmetric(
            insertion:
                .move(
                    edge: pageMovesForward
                        ? .trailing
                        : .leading
                )
                .combined(with: .opacity),
            removal:
                .move(
                    edge: pageMovesForward
                        ? .leading
                        : .trailing
                )
                .combined(with: .opacity)
        )
    }

    /// Swipe left for the next section, right for the previous one.
    /// Mostly-vertical drags are left to the scroll view.
    var pageSwipe: some Gesture {
        DragGesture(minimumDistance: 25)
            .onEnded { value in
                let horizontal = value.translation.width
                let vertical = value.translation.height

                guard
                    abs(horizontal) > 60,
                    abs(horizontal) > abs(vertical) * 1.5,
                    let index = pages.firstIndex(of: currentPage)
                else {
                    return
                }

                let nextIndex =
                    horizontal < 0 ? index + 1 : index - 1

                guard pages.indices.contains(nextIndex) else {
                    return
                }

                pageSelection.wrappedValue =
                    pages[nextIndex]
            }
    }

    var newSectionButton: some View {
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

    // MARK: - Pages

    /// One page per section in saved order, then Unsorted when it
    /// has recipes (or when there are no sections at all).
    var pages: [CookbookPage] {
        let sectionPages =
            sections.map {
                CookbookPage.section($0.id)
            }

        let showUnsorted =
            sections.isEmpty || !unsortedRecipes.isEmpty

        return sectionPages
            + (showUnsorted ? [.unsorted] : [])
    }

    /// The selected page, falling back to the first one if the
    /// selected section was deleted.
    var pageSelection: Binding<CookbookPage> {
        Binding(
            get: {
                if let selectedPage,
                   pages.contains(selectedPage) {
                    return selectedPage
                }
                return pages.first ?? .unsorted
            },
            set: { newPage in
                let current =
                    pages.firstIndex(of: currentPage) ?? 0
                let next =
                    pages.firstIndex(of: newPage) ?? 0

                guard current != next else {
                    return
                }

                pageMovesForward = next > current

                withAnimation(.easeInOut(duration: 0.25)) {
                    selectedPage = newPage
                }
                // Leaving a page ends its reordering.
                if editingPage != newPage {
                    editingPage = nil
                }
            }
        )
    }

    func title(
        for page: CookbookPage
    ) -> String {
        switch page {
        case .section(let id):
            return sections.first { $0.id == id }?.name
                ?? "Section"
        case .unsorted:
            return sections.isEmpty ? "All Recipes" : "Unsorted"
        }
    }

    func recipes(
        on page: CookbookPage
    ) -> [Recipe] {
        switch page {
        case .section(let id):
            return recipes(inSection: id)
        case .unsorted:
            return unsortedRecipes
        }
    }

    // MARK: - Page

    func pageView(
        _ page: CookbookPage
    ) -> some View {
        let pageRecipes =
            recipes(on: page)

        let isEditing =
            editingPage == page

        let section: CookbookSection? = {
            if case .section(let id) = page {
                return sections.first { $0.id == id }
            }
            return nil
        }()

        return VStack(
            alignment: .leading,
            spacing: KinSpacing.small
        ) {
            HStack(
                alignment: .firstTextBaseline
            ) {
                sectionHeading(
                    title(for: page),
                    count: pageRecipes.count
                )

                if pageRecipes.count > 1 {
                    Button(isEditing ? "Done" : "Reorder") {
                        withAnimation {
                            editingPage =
                                isEditing ? nil : page
                        }
                    }
                    .font(KinTypography.callout)
                    .foregroundStyle(KinColors.primary)
                }

            }
            .padding(.horizontal, KinSpacing.large)

            if pageRecipes.isEmpty {
                VStack(spacing: KinSpacing.small) {
                    Text("No recipes in this section yet.")
                        .font(KinTypography.footnote)
                        .foregroundStyle(KinColors.secondaryText)

                    Text("Press and hold a recipe and choose Move to Section.")
                        .font(KinTypography.caption)
                        .foregroundStyle(KinColors.secondaryText)
                }
                .frame(maxWidth: .infinity)
                .padding(KinSpacing.large)
                .background(KinColors.surface.opacity(0.6))
                .clipShape(
                    RoundedRectangle(
                        cornerRadius: KinRadius.medium
                    )
                )
                .padding(.horizontal, KinSpacing.large)
            } else {
                VStack(spacing: KinSpacing.small) {
                    ForEach(
                        Array(pageRecipes.enumerated()),
                        id: \.element.id
                    ) { index, recipe in
                        if isEditing {
                            reorderRow(
                                recipe,
                                at: index,
                                of: pageRecipes.count,
                                on: page
                            )
                        } else {
                            recipeRow(recipe)
                        }
                    }
                }
                .padding(.horizontal, KinSpacing.large)
            }
        }
        // Keep short pages from collapsing so swiping still works.
        .frame(
            maxWidth: .infinity,
            minHeight: 240,
            alignment: .top
        )
    }

    /// A recipe in Reorder mode: the card plus up/down buttons.
    func reorderRow(
        _ recipe: Recipe,
        at index: Int,
        of count: Int,
        on page: CookbookPage
    ) -> some View {
        HStack(spacing: KinSpacing.small) {
            recipeCard(recipe)

            VStack(spacing: KinSpacing.xSmall) {
                reorderButton(
                    systemImage: "chevron.up",
                    label: "Move \(recipe.name) up",
                    isDisabled: index == 0
                ) {
                    moveRecipes(
                        on: page,
                        from: [index],
                        to: index - 1
                    )
                }

                reorderButton(
                    systemImage: "chevron.down",
                    label: "Move \(recipe.name) down",
                    isDisabled: index == count - 1
                ) {
                    // List-move convention: drop after the next item.
                    moveRecipes(
                        on: page,
                        from: [index],
                        to: index + 2
                    )
                }
            }
        }
    }

    func reorderButton(
        systemImage: String,
        label: String,
        isDisabled: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                action()
            }
        } label: {
            Image(systemName: systemImage)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(
                    isDisabled
                        ? KinColors.secondaryText.opacity(0.4)
                        : KinColors.primary
                )
                .frame(width: 36, height: 30)
                .background(
                    KinColors.primary.opacity(
                        isDisabled ? 0.04 : 0.12
                    )
                )
                .clipShape(
                    RoundedRectangle(
                        cornerRadius: KinRadius.medium
                    )
                )
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
        .accessibilityLabel(label)
    }

    // MARK: - Reorder Recipes

    /// Shows the new order right away, then saves it. If saving
    /// fails, reloads the stored order and says so.
    func moveRecipes(
        on page: CookbookPage,
        from offsets: IndexSet,
        to destination: Int
    ) {
        let newOrder =
            CookbookService.reordered(
                recipes(on: page).map(\.id),
                moving: offsets,
                to: destination
            )

        let sectionId: UUID? = {
            if case .section(let id) = page {
                return id
            }
            return nil
        }()

        applyLocalOrder(
            newOrder,
            in: sectionId
        )

        Task {
            do {
                try await CookbookService.reorderRecipes(
                    newOrder,
                    in: sectionId,
                    cookbookId: cookbookId
                )
            } catch {
                sectionErrorMessage =
                    "The new order couldn't be saved. Please try again."

                print(
                    "COOKBOOK REORDER ERROR:",
                    error.localizedDescription
                )

                await loadCookbook(
                    showLoadingState: false
                )
            }
        }
    }

    func applyLocalOrder(
        _ orderedRecipeIds: [UUID],
        in sectionId: UUID?
    ) {
        relationships =
            relationships
                .map { relationship in
                    guard
                        let position =
                            orderedRecipeIds.firstIndex(
                                of: relationship.recipeId
                            )
                    else {
                        return relationship
                    }

                    return CookbookRecipe(
                        cookbookId: relationship.cookbookId,
                        recipeId: relationship.recipeId,
                        sectionId: sectionId,
                        sortOrder: position,
                        isFeatured: relationship.isFeatured
                    )
                }
                .sorted(by: CookbookRecipe.displayOrder)

        recipes =
            relationships.compactMap {
                recipesById[$0.recipeId]
            }
    }

    // MARK: - Sections

    /// Recipes in a section, in saved order.
    func recipes(
        inSection sectionId: UUID
    ) -> [Recipe] {
        let recipeIds =
            relationships
                .filter { $0.sectionId == sectionId }
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
        Button {
            selectedRecipeId = recipe.id
        } label: {
            recipeCard(recipe)
        }
        .buttonStyle(.plain)
        // Organizing options: press and hold the card.
        .contextMenu {
                // Move to another section (or Unsorted).
                if !sections.isEmpty {
                    Menu {
                        ForEach(sections) { section in
                            Button {
                                Task {
                                    await moveRecipe(
                                        recipe,
                                        to: section.id
                                    )
                                }
                            } label: {
                                if sectionId(of: recipe) == section.id {
                                    Label(section.name, systemImage: "checkmark")
                                } else {
                                    Text(section.name)
                                }
                            }
                        }

                        Divider()

                        Button {
                            Task {
                                await moveRecipe(
                                    recipe,
                                    to: nil
                                )
                            }
                        } label: {
                            if sectionId(of: recipe) == nil {
                                Label("Unsorted", systemImage: "checkmark")
                            } else {
                                Text("Unsorted")
                            }
                        }
                    } label: {
                        Label(
                            "Move to Section",
                            systemImage: "folder"
                        )
                    }
                }

                // Featured recipes appear in full in the preview.
                if isFeatured(recipe) {
                    Button {
                        Task {
                            await setFeatured(false, recipe)
                        }
                    } label: {
                        Label(
                            "Remove from Preview",
                            systemImage: "star.slash"
                        )
                    }
                } else if canFeature(recipe) {
                    Button {
                        Task {
                            await setFeatured(true, recipe)
                        }
                    } label: {
                        Label(
                            "Feature in Preview",
                            systemImage: "star"
                        )
                    }
                } else {
                    Button {} label: {
                        Label(
                            "Section has \(CookbookRecipe.maxFeaturedPerSection) featured",
                            systemImage: "star"
                        )
                    }
                    .disabled(true)
                }

                Button(role: .destructive) {
                    recipeToRemove = recipe
                } label: {
                    Label(
                        "Remove from Cookbook",
                        systemImage: "minus.circle"
                    )
                }
        }
        .disabled(
            isRemovingRecipe || isMovingRecipe
        )
        .accessibilityHint(
            "Opens the recipe. Press and hold for options."
        )
    }

    // MARK: - Featured

    func isFeatured(
        _ recipe: Recipe
    ) -> Bool {
        relationships
            .first { $0.recipeId == recipe.id }?
            .isFeatured ?? false
    }

    /// Room for another featured recipe in this recipe's section.
    func canFeature(
        _ recipe: Recipe
    ) -> Bool {
        let sectionId =
            relationships
                .first { $0.recipeId == recipe.id }?
                .sectionId

        return CookbookRecipe.canFeature(
            in: sectionId,
            relationships:
                relationships.filter {
                    $0.recipeId != recipe.id
                }
        )
    }

    @MainActor
    func setFeatured(
        _ featured: Bool,
        _ recipe: Recipe
    ) async {
        sectionErrorMessage = nil

        do {
            try await CookbookService.setFeatured(
                featured,
                recipeId: recipe.id,
                in: cookbookId,
                relationships: relationships
            )

            await loadCookbook(
                showLoadingState: false
            )

        } catch {
            sectionErrorMessage =
                error.localizedDescription
        }
    }

    /// The recipe's current section, nil when Unsorted or when its
    /// section no longer exists.
    func sectionId(
        of recipe: Recipe
    ) -> UUID? {
        guard
            let sectionId =
                relationships
                    .first(where: { $0.recipeId == recipe.id })?
                    .sectionId,
            sections.contains(where: { $0.id == sectionId })
        else {
            return nil
        }
        return sectionId
    }

    @MainActor
    func moveRecipe(
        _ recipe: Recipe,
        to sectionId: UUID?
    ) async {
        guard
            !isMovingRecipe,
            self.sectionId(of: recipe) != sectionId
        else {
            return
        }

        isMovingRecipe = true
        sectionErrorMessage = nil

        defer {
            isMovingRecipe = false
        }

        do {
            try await CookbookService.moveRecipe(
                recipeId: recipe.id,
                in: cookbookId,
                to: sectionId,
                relationships: relationships
            )

            // Show what's actually stored.
            await loadCookbook(
                showLoadingState: false
            )

        } catch {
            sectionErrorMessage =
                "\(recipe.name) couldn't be moved. Please try again."

            print(
                "COOKBOOK MOVE RECIPE ERROR:",
                error.localizedDescription
            )
        }
    }

    /// The recipe photo fills the card and fades into the card color
    /// behind the name, like the gathering cards on Home.
    func recipeCard(
        _ recipe: Recipe
    ) -> some View {
        let details =
            HomeView.recipeDetails(
                minutes: recipe.totalTimeMinutes,
                formattedTime: recipe.formattedTotalTime,
                category: recipe.category
            )

        return VStack(
            alignment: .leading,
            spacing: KinSpacing.xxSmall
        ) {
            Text(recipe.name)
                .font(KinTypography.headline)
                .foregroundStyle(KinColors.primaryText)
                .multilineTextAlignment(.leading)
                .lineLimit(2)

            if let details {
                Text(details)
                    .font(KinTypography.footnote)
                    .foregroundStyle(KinColors.secondaryText)
            }

            if isFeatured(recipe) {
                Label(
                    "Featured in Preview",
                    systemImage: "star.fill"
                )
                .font(KinTypography.caption)
                .foregroundStyle(KinColors.warning)
            }
        }
        .padding(KinSpacing.medium)
        .frame(
            maxWidth: .infinity,
            minHeight: 88,
            alignment: .leading
        )
        .background {
            ZStack {
                KinColors.surface

                KinStorageImage(
                    bucket: "recipe-photos",
                    path: recipe.photoPath
                )
                // The photo shows on the right and fades out toward
                // the text.
                .mask {
                    LinearGradient(
                        stops: [
                            .init(color: .clear, location: 0.3),
                            .init(color: .black.opacity(0.6), location: 0.62),
                            .init(color: .black, location: 1)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                }
            }
        }
        .clipShape(
            RoundedRectangle(
                cornerRadius: KinRadius.large
            )
        )
        .shadow(
            color: .black.opacity(0.06),
            radius: 6,
            y: 2
        )
        .contentShape(
            RoundedRectangle(
                cornerRadius: KinRadius.large
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
            recipesById = contents.recipesById
            relationships =
                contents.relationships.sorted(
                    by: CookbookRecipe.displayOrder
                )

            // Saved order; recipes that no longer exist are skipped.
            recipes =
                relationships.compactMap {
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
        deleteErrorMessage = nil

        do {

            try await CookbookService
                .deleteCookbook(
                    id: cookbookId
                )

            // Back to Cookbooks, which reloads without it.
            dismiss()

        } catch is CancellationError {

            isDeletingCookbook = false

        } catch {

            // The cookbook stays on screen: a failed delete changed
            // nothing.
            deleteErrorMessage =
                KinDeletion.failureMessage(
                    for: error,
                    deleting: .cookbook
                )

            print(
                "COOKBOOK DELETE ERROR:",
                error.localizedDescription
            )

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
            // Keep the cookbook on screen; the recipe is still in it.
            sectionErrorMessage =
                "The recipe couldn't be removed. Please try again."

            print(
                "COOKBOOK REMOVE RECIPE ERROR:",
                error.localizedDescription
            )

            recipeToRemove = nil
        }

        isRemovingRecipe = false
    }
}

// MARK: - Edit Cookbook View

/// Things Edit Cookbook hands back to the cookbook screen to do once
/// the sheet closes.
enum EditCookbookAction {
    case changeCover
    case delete
}

private struct EditCookbookView: View {

    let cookbook: Cookbook
    let onUpdated: (Cookbook) -> Void
    let onAction: (EditCookbookAction) -> Void

    @Environment(\.dismiss)
    private var dismiss

    @State private var name: String
    @State private var description: String

    @State private var isSaving = false
    @State private var errorMessage: String?

    init(
        cookbook: Cookbook,
        onUpdated: @escaping (Cookbook) -> Void,
        onAction: @escaping (EditCookbookAction) -> Void
    ) {
        self.cookbook = cookbook
        self.onUpdated = onUpdated
        self.onAction = onAction

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

                        coverAndDelete
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

// MARK: - Edit Cookbook Cover & Delete

private extension EditCookbookView {

    var coverAndDelete: some View {

        VStack(
            spacing: KinSpacing.medium
        ) {

            Button {
                onAction(.changeCover)
                dismiss()
            } label: {
                Label(
                    cookbook.coverPath == nil
                        ? "Add Cover Image"
                        : "Change Cover Image",
                    systemImage: "photo"
                )
                .font(KinTypography.headline)
                .foregroundStyle(KinColors.primary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, KinSpacing.medium)
                .background(KinColors.primary.opacity(0.10))
                .clipShape(
                    RoundedRectangle(
                        cornerRadius: KinRadius.medium
                    )
                )
            }
            .buttonStyle(.plain)

            Button {
                onAction(.delete)
                dismiss()
            } label: {
                Label(
                    "Delete Cookbook",
                    systemImage: KinIcons.delete
                )
                .font(KinTypography.headline)
                .foregroundStyle(KinColors.error)
                .frame(maxWidth: .infinity)
                .padding(.vertical, KinSpacing.medium)
                .background(KinColors.error.opacity(0.10))
                .clipShape(
                    RoundedRectangle(
                        cornerRadius: KinRadius.medium
                    )
                )
            }
            .buttonStyle(.plain)
        }
        .disabled(isSaving)
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

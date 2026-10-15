//
//  CookbookReadingPage.swift
//  KinKitchen
//
//  Created by Greg Hudler on 10/14/26.
//

import SwiftUI
import Supabase

/// One recipe as a cookbook page: the photo across the top, then a
/// paper-style page with the essentials and Recipe / Ingredients /
/// Steps / Notes tabs. Everything else (ratings, versions, sharing,
/// editing) is one tap away in Full Details.
struct CookbookReadingPage: View {

    enum Tab: String, CaseIterable, Identifiable {
        case recipe = "Recipe"
        case ingredients = "Ingredients"
        case steps = "Steps"
        case notes = "Notes"
        var id: String { rawValue }
    }

    let recipeId: UUID
    /// Room to leave on the right for the section tabs.
    var trailingInset: CGFloat = 0
    let onBack: () -> Void
    let onFullDetails: () -> Void

    @State private var detail: RecipeWithIngredients?
    @State private var rating: RecipeRatingSummary?
    @State private var notes: [RecipeStory] = []
    @State private var dietaryCheck: RecipeDietaryCheckResult?
    @State private var attribution: String?
    @State private var loadFailed = false

    @State private var tab: Tab = .recipe
    @State private var checkedIngredients = Set<UUID>()
    @State private var didCopy = false

    var body: some View {

        ScrollView {

            VStack(spacing: 0) {

                photo

                if let detail {
                    page(detail)
                } else if loadFailed {
                    message("This recipe couldn't be loaded. Check your connection and try again.")
                } else {
                    KinLoadingView(message: "Loading recipe...")
                        .frame(minHeight: 320)
                }
            }
        }
        .ignoresSafeArea(edges: .top)
        .background(KinColors.background)
        .overlay(alignment: .topLeading) {
            backButton
        }
        .task {
            guard detail == nil else {
                return
            }
            await load()
        }
    }


    // MARK: - Photo

    private var photo: some View {

        KinStorageImage(
            bucket: "recipe-photos",
            path: detail?.recipe.photoPath
        )
        .frame(height: 300)
        .frame(maxWidth: .infinity)
        .overlay(alignment: .top) {
            // Keeps the clock and back button readable on any photo.
            LinearGradient(
                colors: [
                    KinColors.background.opacity(0.7),
                    KinColors.background.opacity(0)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 110)
        }
    }

    private var backButton: some View {

        Button(action: onBack) {
            Image(systemName: KinIcons.back)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(KinColors.primaryText)
                .frame(width: 44, height: 44)
                .background(KinColors.surface)
                .clipShape(Circle())
                .kinFloatingShadow()
        }
        .buttonStyle(.plain)
        .padding(.leading, KinSpacing.large)
        .accessibilityLabel("Back to cookbook")
    }


    // MARK: - Page

    /// Paper-style sheet that overlaps the bottom of the photo.
    private func page(
        _ detail: RecipeWithIngredients
    ) -> some View {

        let recipe = detail.recipe

        return VStack(
            alignment: .leading,
            spacing: KinSpacing.medium
        ) {

            Text(recipe.name)
                .font(KinTypography.title)
                .foregroundStyle(KinColors.primaryText)
                .accessibilityAddTraits(.isHeader)

            if let rating, rating.ratingCount > 0,
               let average = rating.averageRating {
                stars(average, count: rating.ratingCount)
            }

            facts(recipe)

            if let attribution {
                Text(attribution)
                    .font(KinTypography.footnote)
                    .italic()
                    .foregroundStyle(KinColors.secondaryText)
            }

            dietaryNotice

            tabPicker

            Group {
                switch tab {
                case .recipe:
                    overview(detail)
                case .ingredients:
                    ingredients(detail)
                case .steps:
                    steps(recipe)
                case .notes:
                    notesView(recipe)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Button(action: onFullDetails) {
                Label("Full Recipe Details", systemImage: "info.circle")
                    .font(KinTypography.subheadline)
                    .foregroundStyle(KinColors.primary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, KinSpacing.medium)
                    .background(KinColors.primary.opacity(0.08))
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            .accessibilityHint("Ratings, versions, sharing and editing")
            .padding(.top, KinSpacing.small)
        }
        .padding(KinSpacing.large)
        .padding(.trailing, trailingInset)
        // Room for the page bar.
        .padding(.bottom, 90)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            UnevenRoundedRectangle(
                topLeadingRadius: KinRadius.xLarge,
                topTrailingRadius: KinRadius.xLarge
            )
            .fill(KinColors.paper)
            .kinSheetShadow()
        )
        .offset(y: -28)
    }

    // MARK: - Header Pieces

    private func stars(
        _ average: Double,
        count: Int
    ) -> some View {

        HStack(spacing: 2) {
            ForEach(1...5, id: \.self) { star in
                Image(
                    systemName:
                        Double(star) <= average.rounded()
                            ? "star.fill"
                            : "star"
                )
            }
            Text("(\(count))")
                .foregroundStyle(KinColors.secondaryText)
                .padding(.leading, KinSpacing.xSmall)
        }
        .font(.footnote)
        .foregroundStyle(KinColors.accent)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            String(format: "Rated %.1f out of 5, %d ratings", average, count)
        )
    }

    private func facts(
        _ recipe: Recipe
    ) -> some View {

        HStack(spacing: KinSpacing.large) {

            if recipe.totalTimeMinutes > 0 {
                Label(recipe.formattedTotalTime, systemImage: KinIcons.time)
            }

            if let category = recipe.category,
               !category.isEmpty {
                Label(category, systemImage: "fork.knife")
            }

            if let servings = recipe.servings,
               servings > 0 {
                Label("Serves \(servings)", systemImage: KinIcons.servings)
            }
        }
        .font(KinTypography.footnote)
        .foregroundStyle(KinColors.secondaryText)
        .lineLimit(1)
        .minimumScaleFactor(0.8)
    }

    /// The same rules as everywhere else: conflicts are flagged and
    /// unchecked ingredients are mentioned. Never "safe".
    @ViewBuilder
    private var dietaryNotice: some View {

        if let dietaryCheck {

            if dietaryCheck.hasConflict {
                notice(
                    "May conflict with your allergies: "
                        + dietaryCheck.conflictingAllergens
                            .map(\.name)
                            .joined(separator: ", "),
                    color: KinColors.warning
                )
            } else if dietaryCheck.hasIncompleteInformation {
                notice(
                    "Couldn't fully check this recipe against your allergies.",
                    color: KinColors.secondaryText
                )
            }
        }
    }

    private func notice(
        _ text: String,
        color: Color
    ) -> some View {

        Button(action: onFullDetails) {
            Label(text, systemImage: KinIcons.warning)
                .font(KinTypography.footnote)
                .foregroundStyle(color)
                .multilineTextAlignment(.leading)
                .padding(KinSpacing.small)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(color.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: KinRadius.small))
        }
        .buttonStyle(.plain)
        .accessibilityHint("Opens full details")
    }


    // MARK: - Tabs

    private var tabPicker: some View {

        HStack(spacing: KinSpacing.xSmall) {
            ForEach(Tab.allCases) { option in
                Button {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        tab = option
                    }
                } label: {
                    Text(option.rawValue)
                        .font(KinTypography.subheadline)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                        .foregroundStyle(
                            tab == option ? .white : KinColors.primaryText
                        )
                        .padding(.vertical, KinSpacing.small)
                        .frame(maxWidth: .infinity)
                        .background(
                            tab == option
                                ? KinColors.primary
                                : KinColors.primary.opacity(0.06)
                        )
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(tab == option ? .isSelected : [])
            }
        }
        .padding(.top, KinSpacing.small)
    }

    /// Everything at a glance: description, ingredients, steps.
    private func overview(
        _ detail: RecipeWithIngredients
    ) -> some View {

        VStack(alignment: .leading, spacing: KinSpacing.large) {

            if let description = cleaned(detail.recipe.description) {
                Text(description)
                    .font(KinTypography.body)
                    .foregroundStyle(KinColors.primaryText)
            }

            ingredients(detail)

            steps(detail.recipe)
        }
    }

    private func ingredients(
        _ detail: RecipeWithIngredients
    ) -> some View {

        let items = detail.orderedIngredients

        return VStack(alignment: .leading, spacing: KinSpacing.small) {

            HStack {
                heading("Ingredients")

                Spacer()

                if !items.isEmpty {
                    Button {
                        UIPasteboard.general.string =
                            items.map(ingredientText).joined(separator: "\n")
                        didCopy = true
                    } label: {
                        Label(
                            didCopy ? "Copied" : "Copy",
                            systemImage: didCopy ? KinIcons.check : "doc.on.doc"
                        )
                        .font(KinTypography.footnote)
                        .foregroundStyle(KinColors.primary)
                    }
                    .buttonStyle(.plain)
                    .accessibilityHint("Copies the ingredient list")
                }
            }

            if items.isEmpty {
                empty("No ingredients listed.")
            }

            // Tick off ingredients while cooking.
            ForEach(items) { ingredient in

                let isChecked = checkedIngredients.contains(ingredient.id)

                Button {
                    if isChecked {
                        checkedIngredients.remove(ingredient.id)
                    } else {
                        checkedIngredients.insert(ingredient.id)
                    }
                } label: {
                    HStack(alignment: .firstTextBaseline, spacing: KinSpacing.small) {
                        Image(systemName: isChecked ? "checkmark.square.fill" : "square")
                            .foregroundStyle(
                                isChecked ? KinColors.success : KinColors.primary
                            )

                        Text(ingredientText(ingredient))
                            .font(KinTypography.body)
                            .foregroundStyle(
                                isChecked ? KinColors.secondaryText : KinColors.primaryText
                            )
                            .strikethrough(isChecked)
                            .multilineTextAlignment(.leading)

                        Spacer(minLength: 0)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(isChecked ? .isSelected : [])
            }
        }
    }

    private func steps(
        _ recipe: Recipe
    ) -> some View {

        let steps = Self.steps(from: recipe.instructions)

        return VStack(alignment: .leading, spacing: KinSpacing.medium) {

            heading("Steps")

            if steps.isEmpty {
                empty("No steps listed.")
            }

            ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                HStack(alignment: .top, spacing: KinSpacing.medium) {
                    Text("\(index + 1)")
                        .font(KinTypography.headline)
                        .foregroundStyle(.white)
                        .frame(width: 28, height: 28)
                        .background(KinColors.primary)
                        .clipShape(Circle())

                    Text(step)
                        .font(KinTypography.body)
                        .foregroundStyle(KinColors.primaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Step \(index + 1). \(step)")
            }
        }
    }

    private func notesView(
        _ recipe: Recipe
    ) -> some View {

        let story = cleaned(recipe.story)
        let contributor = cleaned(recipe.originalContributor)
        let entries = notes.compactMap { cleaned($0.story) }

        return VStack(alignment: .leading, spacing: KinSpacing.medium) {

            heading("Story & Notes")

            if story == nil && contributor == nil && entries.isEmpty {
                empty("No story or notes yet. Add them in Full Recipe Details.")
            }

            if let contributor {
                Text("From \(contributor)")
                    .font(KinTypography.footnote)
                    .italic()
                    .foregroundStyle(KinColors.secondaryText)
            }

            if let story {
                Text(story)
                    .font(KinTypography.body)
                    .foregroundStyle(KinColors.primaryText)
            }

            ForEach(Array(entries.enumerated()), id: \.offset) { _, note in
                Text(note)
                    .font(KinTypography.body)
                    .foregroundStyle(KinColors.primaryText)
                    .padding(KinSpacing.medium)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(KinColors.accent.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: KinRadius.medium))
            }
        }
    }


    // MARK: - Small Pieces

    private func heading(_ text: String) -> some View {
        Text(text)
            .font(KinTypography.title3)
            .foregroundStyle(KinColors.primaryText)
            .accessibilityAddTraits(.isHeader)
    }

    private func empty(_ text: String) -> some View {
        Text(text)
            .font(KinTypography.footnote)
            .foregroundStyle(KinColors.secondaryText)
    }

    private func message(_ text: String) -> some View {
        Text(text)
            .font(KinTypography.body)
            .foregroundStyle(KinColors.secondaryText)
            .multilineTextAlignment(.center)
            .padding(KinSpacing.xLarge)
    }

    private func ingredientText(
        _ ingredient: RecipeIngredient
    ) -> String {
        let measure =
            IngredientQuantityFormatter.formattedMeasurement(
                quantity: ingredient.quantity,
                unit: ingredient.unit
            )
        return measure.isEmpty
            ? ingredient.name
            : "\(measure) \(ingredient.name)"
    }

    private func cleaned(_ value: String?) -> String? {
        guard let value = value?.trimmingCharacters(in: .whitespacesAndNewlines),
              !value.isEmpty else {
            return nil
        }
        return value
    }

    /// One step per line, without any "1." the author typed.
    nonisolated static func steps(
        from instructions: String?
    ) -> [String] {
        (instructions ?? "")
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .map {
                $0.replacingOccurrences(
                    of: #"^\d+[.)]\s*"#,
                    with: "",
                    options: .regularExpression
                )
            }
    }


    // MARK: - Load

    @MainActor
    private func load() async {

        do {
            detail =
                try await RecipeService.fetchRecipeWithIngredients(
                    id: recipeId
                )
        } catch {
            loadFailed = !(error is CancellationError)
            return
        }

        // Extras: the page still reads fine if any of these fail.
        async let ratingRequest =
            try? RecipeService.fetchRecipeRatingSummary(recipeId: recipeId)
        async let notesRequest =
            try? RecipeService.fetchRecipeStories(recipeId: recipeId)
        async let dietaryRequest =
            try? RecipeDietaryCheckService.checkRecipe(recipeId: recipeId)

        rating = await ratingRequest
        notes = await notesRequest ?? []
        dietaryCheck = await dietaryRequest

        await loadAttribution()

        if let userId = SupabaseManager.client.auth.currentUser?.id {
            RecentRecipesStore().recordView(of: recipeId, by: userId)
        }
    }

    /// "By Rose · version by Sam", using the same rules as Recipe
    /// Detail.
    @MainActor
    private func loadAttribution() async {

        guard let recipe = detail?.recipe else {
            return
        }

        let authorId =
            RecipeAttribution.originalAuthorId(
                of: recipe,
                originalOwners: [:]
            ) ?? recipe.ownerId

        let currentUserId =
            SupabaseManager.client.auth.currentUser?.id

        let profiles =
            (try? await ProfileService.fetchProfiles(
                userIds: Array(Set([authorId, recipe.ownerId]))
            )) ?? []

        attribution =
            RecipeAttribution.authorLine(
                for: recipe,
                authorId: authorId,
                name: { userId in
                    if userId == currentUserId {
                        return "you"
                    }
                    return profiles.first { $0.id == userId }?
                        .bestDisplayName ?? "a Kin Kitchen user"
                }
            )
    }
}

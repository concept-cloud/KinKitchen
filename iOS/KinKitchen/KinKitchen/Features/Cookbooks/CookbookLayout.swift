//
//  CookbookLayout.swift
//  KinKitchen
//
//  Created by Greg Hudler on 10/14/26.
//

import Foundation

/// Which recipes sit in which section, in order: the sections in
/// saved order, then Unsorted (`nil`) last. Organize Cookbook edits
/// this, then saves only the sections that changed.
nonisolated struct CookbookLayout: Equatable {

    struct Group: Equatable {
        var sectionId: UUID?
        var recipeIds: [UUID]
    }

    /// One line in the organize list: a section heading or a recipe.
    enum Row: Hashable, Identifiable {
        case heading(UUID?)
        case recipe(UUID)

        var id: String {
            switch self {
            case .heading(let id):
                return "heading-\(id?.uuidString ?? "unsorted")"
            case .recipe(let id):
                return "recipe-\(id.uuidString)"
            }
        }
    }

    var groups: [Group]


    /// Builds the layout from stored data. Recipes whose section no
    /// longer exists count as Unsorted.
    init(
        sectionIds: [UUID],
        relationships: [CookbookRecipe]
    ) {
        let known = Set(sectionIds)
        let ordered = relationships.sorted(by: CookbookRecipe.displayOrder)

        groups =
            sectionIds.map { id in
                Group(
                    sectionId: id,
                    recipeIds: ordered
                        .filter { $0.sectionId == id }
                        .map(\.recipeId)
                )
            }
            + [
                Group(
                    sectionId: nil,
                    recipeIds: ordered
                        .filter { $0.sectionId.map { !known.contains($0) } ?? true }
                        .map(\.recipeId)
                )
            ]
    }

    init(groups: [Group]) {
        self.groups = groups
    }


    // MARK: - Rows

    var rows: [Row] {
        groups.flatMap { group in
            [Row.heading(group.sectionId)]
                + group.recipeIds.map(Row.recipe)
        }
    }

    /// Rebuilds groups from a flat list: each recipe belongs to the
    /// heading above it.
    init(rows: [Row]) {
        var groups: [Group] = []

        for row in rows {
            switch row {
            case .heading(let id):
                groups.append(Group(sectionId: id, recipeIds: []))
            case .recipe(let id):
                if groups.isEmpty {
                    groups.append(Group(sectionId: nil, recipeIds: []))
                }
                groups[groups.count - 1].recipeIds.append(id)
            }
        }

        self.groups = groups
    }


    // MARK: - Moving

    /// A drag in the flat list. Only recipe rows move; dropping above
    /// the first heading lands in the first section.
    func moving(
        rowsAt offsets: IndexSet,
        to destination: Int
    ) -> CookbookLayout {
        var rows = self.rows

        let moved = offsets.map { rows[$0] }

        guard moved.allSatisfy({
            if case .recipe = $0 { return true }
            return false
        }) else {
            return self
        }

        // Same rules as a SwiftUI list move: take the rows out, then
        // insert them where the drop lands.
        let target = max(1, destination)
        let insertAt = target - offsets.filter { $0 < target }.count

        rows = rows.enumerated()
            .filter { !offsets.contains($0.offset) }
            .map(\.element)

        rows.insert(
            contentsOf: moved,
            at: min(max(insertAt, 1), rows.count)
        )

        return CookbookLayout(rows: rows)
    }

    /// Moves several recipes to the end of one section, keeping
    /// their current order.
    func moving(
        _ recipeIds: Set<UUID>,
        to sectionId: UUID?
    ) -> CookbookLayout {
        let ordered =
            rows.compactMap { row -> UUID? in
                if case .recipe(let id) = row, recipeIds.contains(id) {
                    return id
                }
                return nil
            }

        var groups =
            self.groups.map { group in
                Group(
                    sectionId: group.sectionId,
                    recipeIds: group.recipeIds.filter { !recipeIds.contains($0) }
                )
            }

        if let index = groups.firstIndex(where: { $0.sectionId == sectionId }) {
            groups[index].recipeIds += ordered
        }

        return CookbookLayout(groups: groups)
    }

    /// Sections whose recipes or order differ from `old`: the only
    /// ones that need saving.
    func changedGroups(
        since old: CookbookLayout
    ) -> [Group] {
        groups.filter { group in
            old.groups.first { $0.sectionId == group.sectionId } != group
        }
    }


    // MARK: - Section changes

    func addingSection(_ id: UUID) -> CookbookLayout {
        var groups = self.groups
        let unsortedIndex = groups.firstIndex { $0.sectionId == nil } ?? groups.count
        groups.insert(Group(sectionId: id, recipeIds: []), at: unsortedIndex)
        return CookbookLayout(groups: groups)
    }

    /// Its recipes move to Unsorted, matching what the database does.
    func removingSection(_ id: UUID) -> CookbookLayout {
        let removed = groups.first { $0.sectionId == id }?.recipeIds ?? []
        var groups = self.groups.filter { $0.sectionId != id }

        if let unsorted = groups.firstIndex(where: { $0.sectionId == nil }) {
            groups[unsorted].recipeIds += removed
        }

        return CookbookLayout(groups: groups)
    }

    func orderingSections(_ ids: [UUID]) -> CookbookLayout {
        let byId = Dictionary(
            uniqueKeysWithValues: groups.compactMap { group in
                group.sectionId.map { ($0, group) }
            }
        )

        return CookbookLayout(
            groups: ids.compactMap { byId[$0] }
                + groups.filter { $0.sectionId == nil }
        )
    }
}

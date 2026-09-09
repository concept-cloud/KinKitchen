//
//  RecipeDragSupport.swift
//  KinKitchen
//
//  Created by Greg Hudler on 9/9/26.
//

import SwiftUI
import UniformTypeIdentifiers

// MARK: - Drop Position

enum RecipeDropPosition {
    case above
    case below
}


// MARK: - Drag Items

struct IngredientDragItem: Codable, Transferable {

    let id: UUID

    static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(
            contentType: .kinKitchenIngredient
        )
    }
}


struct InstructionDragItem: Codable, Transferable {

    let id: UUID

    static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(
            contentType: .kinKitchenInstruction
        )
    }
}


// MARK: - Ingredient Hover Drop Delegate

struct IngredientHoverDropDelegate: DropDelegate {

    let targetID: UUID

    let onDragLocationChanged: (CGPoint) -> Void

    @Binding var draggedID: UUID?
    @Binding var targetIDBinding: UUID?
    @Binding var position: RecipeDropPosition?

    func dropEntered(
        info: DropInfo
    ) {
        guard
            draggedID != nil,
            draggedID != targetID
        else {
            return
        }

        targetIDBinding = targetID

        position =
            info.location.y > 44
                ? .below
                : .above
    }

    func dropUpdated(
        info: DropInfo
    ) -> DropProposal? {

        guard
            draggedID != nil,
            draggedID != targetID
        else {
            return DropProposal(
                operation: .move
            )
        }

        targetIDBinding = targetID

        position =
            info.location.y > 44
                ? .below
                : .above

        onDragLocationChanged(
            info.location
        )

        return DropProposal(
            operation: .move
        )
    }

    func performDrop(
        info: DropInfo
    ) -> Bool {
        false
    }

    func dropExited(
        info: DropInfo
    ) {
        if targetIDBinding == targetID {
            targetIDBinding = nil
            position = nil
        }
    }
}


// MARK: - Instruction Hover Drop Delegate

struct InstructionHoverDropDelegate: DropDelegate {

    let targetID: UUID

    let onDragLocationChanged: (CGPoint) -> Void

    @Binding var draggedID: UUID?
    @Binding var targetIDBinding: UUID?
    @Binding var position: RecipeDropPosition?

    func dropEntered(
        info: DropInfo
    ) {
        guard
            draggedID != nil,
            draggedID != targetID
        else {
            return
        }

        targetIDBinding = targetID

        position =
            info.location.y > 44
                ? .below
                : .above
    }

    func dropUpdated(
        info: DropInfo
    ) -> DropProposal? {

        guard
            draggedID != nil,
            draggedID != targetID
        else {
            return DropProposal(
                operation: .move
            )
        }

        targetIDBinding = targetID

        position =
            info.location.y > 44
                ? .below
                : .above

        onDragLocationChanged(
            info.location
        )

        return DropProposal(
            operation: .move
        )
    }

    func performDrop(
        info: DropInfo
    ) -> Bool {
        false
    }

    func dropExited(
        info: DropInfo
    ) {
        if targetIDBinding == targetID {
            targetIDBinding = nil
            position = nil
        }
    }
}


// MARK: - Content Types

extension UTType {

    static let kinKitchenIngredient =
        UTType(
            exportedAs: "com.kinkitchen.ingredient"
        )

    static let kinKitchenInstruction =
        UTType(
            exportedAs: "com.kinkitchen.instruction"
        )
}

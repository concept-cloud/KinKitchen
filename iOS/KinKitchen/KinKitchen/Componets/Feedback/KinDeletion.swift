//
//  KinDeletion.swift
//  KinKitchen
//
//  Created by Greg Hudler on 10/11/26.
//

import Foundation
import SwiftUI

/// One look and one set of messages for deleting recipes, cookbooks
/// and gatherings. Every delete runs as a single database
/// transaction, so a failure always means nothing was changed.
enum KinDeletion {

    /// What kind of content is being deleted. Drives the wording of
    /// failure messages.
    enum Content {
        case recipe
        case cookbook
        case gathering

        var noun: String {
            switch self {
            case .recipe: "recipe"
            case .cookbook: "cookbook"
            case .gathering: "event"
            }
        }
    }

    /// Turns a failed delete into a message for the person. The
    /// content is always still there afterwards, so the message says
    /// so.
    static func failureMessage(
        for error: Error,
        deleting content: Content
    ) -> String {

        let description =
            String(describing: error)

        if description.contains("NOT_RECIPE_OWNER") {
            return "Only the person who created this recipe can delete it."
        }

        if description.contains("NOT_COOKBOOK_OWNER") {
            return "Only the owner can delete this cookbook."
        }

        if description.contains("NOT_GATHERING_HOST")
            || description.contains("GATHERING_ALREADY_OCCURRED") {
            return GatheringService.friendlyMessage(
                for: error,
                fallback: ""
            )
        }

        if isOffline(error) {
            return "You appear to be offline. The \(content.noun) was not deleted. Check your connection and try again."
        }

        return "The \(content.noun) couldn't be deleted. Nothing was changed. Please try again."
    }

    private static func isOffline(
        _ error: Error
    ) -> Bool {

        guard let urlError = error as? URLError else {
            return false
        }

        return [
            .notConnectedToInternet,
            .networkConnectionLost,
            .timedOut,
            .cannotConnectToHost,
            .cannotFindHost
        ].contains(urlError.code)
    }
}


// MARK: - View Modifiers

extension View {

    /// The standard delete confirmation: a centered alert naming the
    /// item, with Cancel always visible.
    func deleteConfirmation(
        _ title: String,
        isPresented: Binding<Bool>,
        message: String,
        onDelete: @escaping () -> Void
    ) -> some View {

        alert(
            title,
            isPresented: isPresented
        ) {
            Button(
                "Cancel",
                role: .cancel
            ) {}

            Button(
                "Delete",
                role: .destructive,
                action: onDelete
            )
        } message: {
            Text(message)
        }
    }

    /// Covers the screen while a delete runs so nothing else can be
    /// tapped, including a second delete.
    func deletingOverlay(
        _ isDeleting: Bool
    ) -> some View {

        overlay {
            if isDeleting {
                ZStack {
                    Color.black.opacity(0.15)
                        .ignoresSafeArea()

                    ProgressView("Deleting…")
                        .padding(KinSpacing.large)
                        .background(KinColors.surface)
                        .clipShape(
                            RoundedRectangle(
                                cornerRadius: KinRadius.medium
                            )
                        )
                }
            }
        }
    }

    /// The standard failed-delete alert. The item stays on screen,
    /// unchanged.
    func deleteFailedAlert(
        _ message: Binding<String?>
    ) -> some View {

        alert(
            "Couldn't Delete",
            isPresented: Binding(
                get: { message.wrappedValue != nil },
                set: { if !$0 { message.wrappedValue = nil } }
            )
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(message.wrappedValue ?? "")
        }
    }
}

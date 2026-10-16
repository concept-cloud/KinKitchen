//
//  CookbookShelf.swift
//  KinKitchen
//
//  Created by Greg Hudler on 10/15/26.
//

import SwiftUI

// MARK: - Layout

/// What sits on the shelves: the cookbooks, then a "New Cookbook"
/// book, two to a shelf.
nonisolated enum CookbookShelfLayout {

    enum Slot: Hashable {
        case cookbook(UUID)
        case add
    }

    static let booksPerShelf = 2

    /// The "New Cookbook" book is left off while searching.
    static func shelves(
        for cookbookIds: [UUID],
        includesAdd: Bool = true
    ) -> [[Slot]] {
        let slots = cookbookIds.map(Slot.cookbook) + (includesAdd ? [.add] : [])
        return stride(from: 0, to: slots.count, by: booksPerShelf).map {
            Array(slots[$0..<min($0 + booksPerShelf, slots.count)])
        }
    }
}


// MARK: - Shelf

/// A honey-oak plank the books stand on: a lit top, a soft contact
/// shadow where the books sit, a bright front edge, and shade falling
/// on the wall below. No drawn grain, so it stays clean.
struct KinWoodShelf: View {

    private static let top = Color(red: 0.74, green: 0.53, blue: 0.33)
    private static let topBack = Color(red: 0.52, green: 0.35, blue: 0.21)
    private static let front = Color(red: 0.62, green: 0.42, blue: 0.25)
    private static let frontLow = Color(red: 0.45, green: 0.29, blue: 0.16)

    var body: some View {

        VStack(spacing: 0) {

            // Top surface: darker at the back, where the books stand.
            LinearGradient(
                colors: [Self.topBack, Self.top],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 10)

            // Front edge: a thin highlight, then the face.
            VStack(spacing: 0) {
                Color(red: 0.86, green: 0.67, blue: 0.45)
                    .frame(height: 1)
                LinearGradient(
                    colors: [Self.front, Self.frontLow],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
            .frame(height: 16)

            // Shade the shelf casts on the wall below.
            LinearGradient(
                colors: [.black.opacity(0.4), .black.opacity(0)],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 28)
        }
        .accessibilityHidden(true)
    }
}


// MARK: - Bookcase Wall

/// The back of the bookcase: smooth dark walnut, lit from the top and
/// darker toward the edges.
struct KinBookcaseWall: View {

    var body: some View {

        LinearGradient(
            colors: [
                Color(red: 0.30, green: 0.19, blue: 0.11),
                Color(red: 0.25, green: 0.16, blue: 0.09),
                Color(red: 0.19, green: 0.12, blue: 0.07)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        // Warm lamp light near the top.
        .overlay {
            RadialGradient(
                colors: [
                    Color(red: 1, green: 0.82, blue: 0.55).opacity(0.22),
                    .clear
                ],
                center: UnitPoint(x: 0.5, y: 0.05),
                startRadius: 0,
                endRadius: 460
            )
        }
        // Darker toward the sides, like the inside of a cabinet.
        .overlay {
            LinearGradient(
                stops: [
                    .init(color: .black.opacity(0.35), location: 0),
                    .init(color: .clear, location: 0.18),
                    .init(color: .clear, location: 0.82),
                    .init(color: .black.opacity(0.35), location: 1)
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
        }
        .accessibilityHidden(true)
    }
}


// MARK: - New Cookbook Book

/// The last book on the shelf: an outlined book to start a new one.
struct KinAddCookbookBook: View {

    var height: CGFloat

    private var shape: UnevenRoundedRectangle {
        UnevenRoundedRectangle(
            topLeadingRadius: 4,
            bottomLeadingRadius: 4,
            bottomTrailingRadius: KinRadius.large,
            topTrailingRadius: KinRadius.large
        )
    }

    var body: some View {

        VStack(spacing: KinSpacing.small) {

            Image(systemName: KinIcons.add)
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 46, height: 46)
                .background(KinColors.primary, in: Circle())
                .kinFloatingShadow()

            Text("New Cookbook")
                .font(KinTypography.headline)
                .foregroundStyle(.white)

            Text("Start a family collection")
                .font(KinTypography.caption)
                .foregroundStyle(.white.opacity(0.75))
                .multilineTextAlignment(.center)
        }
        .padding(KinSpacing.medium)
        .frame(maxWidth: .infinity)
        .frame(height: height)
        .background(.black.opacity(0.18), in: shape)
        .overlay {
            shape.strokeBorder(
                KinCookbookCoverCard.gold.opacity(0.9),
                style: StrokeStyle(lineWidth: 1.5, dash: [6, 4])
            )
        }
        .padding(.trailing, 5)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("New Cookbook")
        .accessibilityAddTraits(.isButton)
    }
}


// MARK: - Book Button

/// Tapping a book opens it like a real one: it lifts off the shelf,
/// the cover swings open on its spine to a cream first page, then the
/// cookbook zooms up out of it (see CookbooksView). Coming back, it
/// zooms back down and the cover closes.
struct KinShelfBookButton<Label: View>: View {

    let action: () -> Void
    @ViewBuilder var label: Label

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private enum Phase {
        case resting
        case lifted
        case open
    }

    @State private var phase: Phase = .resting

    private var isLifted: Bool { phase != .resting }
    private var isOpen: Bool { phase == .open }

    var body: some View {

        Button {
            open()
        } label: {
            ZStack {
                // Revealed as the cover swings away.
                KinBookFirstPage()
                    .padding(.trailing, 5)
                    .opacity(isOpen ? 1 : 0)

                label
                    .rotation3DEffect(
                        .degrees(isOpen ? -70 : 0),
                        axis: (x: 0, y: 1, z: 0),
                        anchor: .leading,
                        // Gentle, so the swinging edge stays inside
                        // the book's space.
                        perspective: 0.25
                    )
            }
            .scaleEffect(isLifted ? 1.04 : 1, anchor: .bottom)
            .offset(y: isLifted ? -6 : 0)
            .shadow(
                color: .black.opacity(isLifted ? 0.4 : 0),
                radius: isLifted ? 16 : 0,
                y: isLifted ? 12 : 0
            )
            .zIndex(isLifted ? 1 : 0)
        }
        .buttonStyle(.kinPressable)
        .disabled(phase != .resting)
        .sensoryFeedback(.impact(weight: .light), trigger: isLifted) { _, new in new }
        .sensoryFeedback(.impact(flexibility: .soft), trigger: isOpen) { _, new in new }
    }

    private func open() {

        guard phase == .resting else {
            return
        }

        guard !reduceMotion else {
            action()
            return
        }

        Task { @MainActor in
            // Pull it off the shelf.
            withAnimation(.spring(duration: 0.22, bounce: 0.25)) {
                phase = .lifted
            }
            try? await Task.sleep(for: .milliseconds(150))

            // Swing the cover open.
            withAnimation(.easeInOut(duration: 0.34)) {
                phase = .open
            }
            try? await Task.sleep(for: .milliseconds(300))

            // The cookbook zooms up out of the open book.
            action()

            // Close it again once it's off screen, ready for the
            // zoom back.
            try? await Task.sleep(for: .milliseconds(700))
            var quiet = Transaction()
            quiet.disablesAnimations = true
            withTransaction(quiet) {
                phase = .resting
            }
        }
    }
}


/// The inside of a cookbook: a cream page with a few faint lines,
/// seen when the cover opens.
struct KinBookFirstPage: View {

    var body: some View {

        UnevenRoundedRectangle(
            topLeadingRadius: 2,
            bottomLeadingRadius: 2,
            bottomTrailingRadius: KinRadius.large,
            topTrailingRadius: KinRadius.large
        )
        .fill(Color(red: 0.99, green: 0.96, blue: 0.89))
        .overlay {
            VStack(alignment: .leading, spacing: 9) {
                Image(systemName: "fork.knife")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(KinCookbookCoverCard.gold)
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, 6)
                ForEach(0..<6, id: \.self) { line in
                    Capsule()
                        .fill(Color(red: 0.45, green: 0.38, blue: 0.32).opacity(0.18))
                        .frame(height: 3)
                        .padding(.trailing, line % 3 == 2 ? 40 : 0)
                }
            }
            .padding(.horizontal, KinSpacing.large)
        }
        // Shade along the spine, where the page curves in.
        .overlay(alignment: .leading) {
            LinearGradient(
                colors: [.black.opacity(0.18), .clear],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(width: 18)
        }
        .clipShape(
            UnevenRoundedRectangle(
                topLeadingRadius: 2,
                bottomLeadingRadius: 2,
                bottomTrailingRadius: KinRadius.large,
                topTrailingRadius: KinRadius.large
            )
        )
        .accessibilityHidden(true)
    }
}

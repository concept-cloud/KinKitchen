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

/// Tapping a book lifts it off the shelf a little before it opens.
struct KinShelfBookButton<Label: View>: View {

    let action: () -> Void
    @ViewBuilder var label: Label

    @State private var isLifted = false

    var body: some View {

        Button {
            guard !isLifted else { return }
            withAnimation(.spring(duration: 0.22, bounce: 0.3)) {
                isLifted = true
            }
            Task {
                try? await Task.sleep(for: .milliseconds(180))
                action()
                try? await Task.sleep(for: .milliseconds(400))
                isLifted = false
            }
        } label: {
            label
                .scaleEffect(isLifted ? 1.06 : 1, anchor: .bottom)
                .offset(y: isLifted ? -8 : 0)
                .rotation3DEffect(
                    .degrees(isLifted ? -8 : 0),
                    axis: (x: 0, y: 1, z: 0),
                    anchor: .leading,
                    perspective: 0.6
                )
        }
        .buttonStyle(.kinPressable)
        .sensoryFeedback(.impact(weight: .light), trigger: isLifted)
    }
}

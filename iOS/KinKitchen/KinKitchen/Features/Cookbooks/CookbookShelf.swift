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

/// A wooden plank the books stand on: a lit top edge, a grained front
/// lip, and a shadow on the wall below.
struct KinWoodShelf: View {

    private static let light = Color(red: 0.69, green: 0.48, blue: 0.30)
    private static let mid = Color(red: 0.55, green: 0.36, blue: 0.21)
    private static let dark = Color(red: 0.40, green: 0.25, blue: 0.14)

    var body: some View {

        VStack(spacing: 0) {

            // Top surface, seen from slightly above.
            LinearGradient(
                colors: [Self.light, Self.mid],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 9)

            // Front lip with wood grain.
            LinearGradient(
                colors: [Self.mid, Self.dark],
                startPoint: .top,
                endPoint: .bottom
            )
            .overlay {
                Canvas { context, size in
                    for row in stride(from: 3.0, to: size.height, by: 4) {
                        var path = Path()
                        path.move(to: CGPoint(x: 0, y: row))
                        var x: CGFloat = 0
                        while x < size.width {
                            x += 24
                            path.addQuadCurve(
                                to: CGPoint(x: x, y: row),
                                control: CGPoint(x: x - 12, y: row + (Int(x / 24) % 2 == 0 ? 1.2 : -1.2))
                            )
                        }
                        context.stroke(path, with: .color(.black.opacity(0.12)), lineWidth: 0.7)
                    }
                }
            }
            .frame(height: 14)
        }
        .clipShape(RoundedRectangle(cornerRadius: 3))
        .shadow(color: .black.opacity(0.28), radius: 6, y: 7)
        .accessibilityHidden(true)
    }
}


// MARK: - Bookcase Wall

/// The back of the bookcase: warm wood boards behind the shelves.
struct KinBookcaseWall: View {

    var body: some View {

        LinearGradient(
            colors: [
                Color(red: 0.36, green: 0.23, blue: 0.14),
                Color(red: 0.45, green: 0.30, blue: 0.18),
                Color(red: 0.33, green: 0.21, blue: 0.12)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .overlay {
            // Vertical boards with a little grain.
            Canvas { context, size in
                let boardWidth: CGFloat = 78
                var x: CGFloat = boardWidth
                while x < size.width {
                    var seam = Path()
                    seam.move(to: CGPoint(x: x, y: 0))
                    seam.addLine(to: CGPoint(x: x, y: size.height))
                    context.stroke(seam, with: .color(.black.opacity(0.22)), lineWidth: 1)
                    x += boardWidth
                }
                var grain = Path()
                var gx: CGFloat = 9
                while gx < size.width {
                    grain.move(to: CGPoint(x: gx, y: 0))
                    grain.addLine(to: CGPoint(x: gx + 2, y: size.height))
                    gx += 13
                }
                context.stroke(grain, with: .color(.white.opacity(0.025)), lineWidth: 1)
            }
        }
        // Lamp light from the top.
        .overlay {
            RadialGradient(
                colors: [Color(red: 1, green: 0.85, blue: 0.6).opacity(0.18), .clear],
                center: .top,
                startRadius: 0,
                endRadius: 420
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

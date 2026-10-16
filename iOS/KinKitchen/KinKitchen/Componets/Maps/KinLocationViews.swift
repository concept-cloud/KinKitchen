//
//  KinLocationViews.swift
//  KinKitchen
//
//  Created by Greg Hudler on 10/15/26.
//

import SwiftUI
import MapKit
import UIKit

// MARK: - Links

/// Map links for an address typed as text. They work even when the
/// address can't be found on the map: the maps app searches for it.
nonisolated enum KinMapLinks {

    static func appleMapsDirections(to address: String) -> URL? {
        url("https://maps.apple.com/", ["daddr": address])
    }

    /// Opens the Google Maps app when it's installed, the website
    /// otherwise.
    static func googleMapsDirections(to address: String) -> URL? {
        url("https://www.google.com/maps/dir/", ["api": "1", "destination": address])
    }

    private static func url(_ base: String, _ items: [String: String]) -> URL? {
        var components = URLComponents(string: base)
        components?.queryItems = items
            .sorted { $0.key < $1.key }
            .map { URLQueryItem(name: $0.key, value: $0.value) }
        return components?.url
    }
}


// MARK: - Event Location Card

/// The event's place on Event Detail: a small map with a pin, and
/// buttons for directions. Tapping the map opens Apple Maps.
struct EventLocationCard: View {

    let address: String
    var isHighlighted = false

    @Environment(\.openURL) private var openURL

    @State private var place: MKMapItem?
    @State private var didCopy = false

    var body: some View {

        VStack(alignment: .leading, spacing: 0) {

            if let place {
                Button {
                    place.openInMaps()
                } label: {
                    Map(
                        initialPosition: .region(
                            MKCoordinateRegion(
                                center: place.location.coordinate,
                                latitudinalMeters: 900,
                                longitudinalMeters: 900
                            )
                        ),
                        interactionModes: []
                    ) {
                        Marker(address, systemImage: "fork.knife", coordinate: place.location.coordinate)
                            .tint(KinColors.primary)
                    }
                    .frame(height: 150)
                    .allowsHitTesting(false)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Map of \(address)")
                .accessibilityHint("Opens Apple Maps")
                .transition(.opacity)
            }

            HStack(alignment: .center, spacing: KinSpacing.medium) {

                Label(address, systemImage: "mappin.and.ellipse")
                    .font(KinTypography.body)
                    .foregroundStyle(KinColors.primaryText)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .kinChangeHighlight(isHighlighted)

                Menu {
                    Button {
                        openDirections()
                    } label: {
                        Label("Apple Maps", systemImage: "map")
                    }

                    Button {
                        if let url = KinMapLinks.googleMapsDirections(to: address) {
                            openURL(url)
                        }
                    } label: {
                        Label("Google Maps", systemImage: "globe")
                    }

                    Button {
                        UIPasteboard.general.string = address
                        didCopy = true
                    } label: {
                        Label("Copy Address", systemImage: "doc.on.doc")
                    }
                } label: {
                    Label("Directions", systemImage: "arrow.triangle.turn.up.right.diamond.fill")
                        .font(KinTypography.footnote.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, KinSpacing.medium)
                        .padding(.vertical, KinSpacing.small)
                        .background(KinColors.primary, in: Capsule())
                }
                .fixedSize()
            }
            .padding(KinSpacing.medium)
        }
        .background(
            KinColors.surface,
            in: RoundedRectangle(cornerRadius: KinRadius.large)
        )
        .clipShape(RoundedRectangle(cornerRadius: KinRadius.large))
        .kinCardShadow()
        .sensoryFeedback(.success, trigger: didCopy)
        .animation(.easeInOut(duration: 0.25), value: place)
        .task(id: address) {
            place = await Self.find(address)
        }
    }

    private func openDirections() {
        if let place {
            place.openInMaps(launchOptions: [
                MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDefault
            ])
        } else if let url = KinMapLinks.appleMapsDirections(to: address) {
            openURL(url)
        }
    }

    /// The best match for the address, or nil (the card then shows
    /// just the address and buttons).
    static func find(_ address: String) async -> MKMapItem? {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = address
        return try? await MKLocalSearch(request: request).start().mapItems.first
    }
}


// MARK: - Address Field

/// A text field that suggests addresses and places as you type, from
/// Apple Maps. Picking one fills in the full address; anything typed
/// still works.
struct KinAddressField: View {

    let placeholder: String
    @Binding var text: String
    var background: Color = KinColors.background

    @State private var completer = AddressCompleter()
    @FocusState private var isFocused: Bool

    /// Set when a suggestion is picked so it doesn't search again.
    @State private var picked: String?

    var body: some View {

        VStack(alignment: .leading, spacing: KinSpacing.xSmall) {

            HStack(spacing: KinSpacing.small) {

                Image(systemName: "mappin.and.ellipse")
                    .foregroundStyle(isFocused ? KinColors.primary : KinColors.secondaryText)

                TextField(placeholder, text: $text)
                    .font(KinTypography.body)
                    .foregroundStyle(KinColors.primaryText)
                    .focused($isFocused)
                    .submitLabel(.done)
                    .textContentType(.fullStreetAddress)

                if !text.isEmpty && isFocused {
                    Button {
                        text = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(KinColors.secondaryText.opacity(0.6))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Clear location")
                }
            }
            .padding(KinSpacing.medium)
            .background(background, in: RoundedRectangle(cornerRadius: KinRadius.medium))
            .overlay {
                RoundedRectangle(cornerRadius: KinRadius.medium)
                    .strokeBorder(
                        isFocused
                            ? KinColors.primary.opacity(0.6)
                            : KinColors.secondaryText.opacity(0.15)
                    )
            }

            if isFocused && !completer.results.isEmpty {

                VStack(alignment: .leading, spacing: 0) {
                    ForEach(Array(completer.results.prefix(4).enumerated()), id: \.offset) { index, result in

                        if index > 0 {
                            Divider()
                                .overlay(KinColors.secondaryText.opacity(0.15))
                        }

                        Button {
                            choose(result)
                        } label: {
                            VStack(alignment: .leading, spacing: KinSpacing.xxSmall) {
                                Text(result.title)
                                    .font(KinTypography.callout)
                                    .foregroundStyle(KinColors.primaryText)
                                if !result.subtitle.isEmpty {
                                    Text(result.subtitle)
                                        .font(KinTypography.caption)
                                        .foregroundStyle(KinColors.secondaryText)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, KinSpacing.medium)
                            .padding(.vertical, KinSpacing.small)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
                .background(background, in: RoundedRectangle(cornerRadius: KinRadius.medium))
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .animation(.easeOut(duration: 0.15), value: completer.results.count)
        .animation(.easeOut(duration: 0.15), value: isFocused)
        .onChange(of: text) { _, newValue in
            if newValue == picked {
                return
            }
            picked = nil
            completer.search(newValue)
        }
    }

    private func choose(_ result: MKLocalSearchCompletion) {
        let full = AddressCompleter.fullText(title: result.title, subtitle: result.subtitle)
        picked = full
        text = full
        completer.results = []
        isFocused = false
    }
}


/// Wraps MapKit's search-as-you-type for SwiftUI.
@Observable
final class AddressCompleter: NSObject, MKLocalSearchCompleterDelegate {

    var results: [MKLocalSearchCompletion] = []

    @ObservationIgnored
    private let completer: MKLocalSearchCompleter = {
        let completer = MKLocalSearchCompleter()
        completer.resultTypes = [.address, .pointOfInterest]
        return completer
    }()

    override init() {
        super.init()
        completer.delegate = self
    }

    func search(_ text: String) {
        let query = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard query.count >= 3 else {
            results = []
            return
        }
        completer.queryFragment = query
    }

    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        results = completer.results
    }

    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        results = []
    }

    /// "Lincoln Park Zoo" + "2001 N Clark St, Chicago, IL" →
    /// "Lincoln Park Zoo, 2001 N Clark St, Chicago, IL".
    nonisolated static func fullText(title: String, subtitle: String) -> String {
        let subtitle = subtitle.trimmingCharacters(in: .whitespaces)
        guard !subtitle.isEmpty, !subtitle.hasPrefix("Search Nearby") else {
            return title
        }
        return "\(title), \(subtitle)"
    }
}

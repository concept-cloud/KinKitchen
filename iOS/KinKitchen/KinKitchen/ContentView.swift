//
//  ContentView.swift
//  KinKitchen
//
//  Created by Greg Hudler on 8/26/26.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                colorRow("Background", color: KinColors.background)
                colorRow("Surface", color: KinColors.surface)
                colorRow("PrimaryText", color: KinColors.primaryText)
                colorRow("SecondaryText", color: KinColors.secondaryText)
                colorRow("Primary", color: KinColors.primary)
                colorRow("Secondary", color: KinColors.secondary)
                colorRow("Accent", color: KinColors.accent)
                colorRow("Error", color: KinColors.error)
                colorRow("Warning", color: KinColors.warning)
                colorRow("Success", color: KinColors.success)
            }
            .padding()
        }
        .background(KinColors.background)
    }

    private func colorRow(_ name: String, color: Color) -> some View {
        HStack {
            Text(name)
                .foregroundStyle(KinColors.primaryText)

            Spacer()

            RoundedRectangle(cornerRadius: 8)
                .fill(color)
                .frame(width: 80, height: 44)
        }
        .padding()
        .background(KinColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    ContentView()
}

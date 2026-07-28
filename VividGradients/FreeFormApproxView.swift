//
//  FreeFormApproxView.swift
//  VividGradients
//
//  Created by Fernando Zafe on 29/09/2025.
//

import SwiftUI

struct FreeformApproxView: View {
    @State private var store = GradientStore()
    @State private var showSettings = false

    var body: some View {
        GradientCanvasView(store: store)
            .overlay(alignment: .topTrailing) {
                Button {
                    showSettings = true
                } label: {
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(12)
                        .background(.ultraThinMaterial, in: Circle())
                }
                .padding(.trailing, 20)
                .padding(.top, 8)
                .opacity(showSettings ? 0 : 1)
                .animation(.easeInOut(duration: 0.2), value: showSettings)
                .accessibilityLabel("Gradient settings")
            }
            // Tap anywhere to summon the panel — the gear is easy to lose
            // against a bright node.
            .onTapGesture { showSettings = true }
            .sheet(isPresented: $showSettings) {
                SettingsPanelView(store: store)
                    .presentationDetents([.fraction(0.55), .large])
                    .presentationDragIndicator(.visible)
                    .presentationBackground(.ultraThinMaterial)
                    .presentationBackgroundInteraction(.enabled(upThrough: .fraction(0.55)))
            }
    }
}

#Preview {
    FreeformApproxView()
}

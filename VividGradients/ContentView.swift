//
//  ContentView.swift
//  VividGradients
//
//  Created by Fernando Zafe on 29/09/2025.
//

import SwiftUI

struct ContentView: View {

    var body: some View {
        Color.green
            .ignoresSafeArea()
    }

}

#Preview {
    ContentView()
        .modelContainer(for: Item.self, inMemory: true)
}

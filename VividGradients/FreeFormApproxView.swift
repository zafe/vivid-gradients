//
//  FreeFormApproxView.swift
//  VividGradients
//
//  Created by Fernando Zafe on 29/09/2025.
//

import SwiftUI

struct FreeformApproxView: View {
    let nodes: [(pos: CGPoint, color: Color, radius: CGFloat)] = [
        (CGPoint(x: 0.2, y: 0.3), .pink.opacity(0.9), 0.5),
        (CGPoint(x: 0.6, y: 0.25), .orange.opacity(0.9), 0.45),
        (CGPoint(x: 0.4, y: 0.7), .cyan.opacity(0.9), 0.6),
        (CGPoint(x: 0.85, y: 0.6), .purple.opacity(0.85), 0.4)
    ]

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // base background                  //  .blur(radius: 0.3)

                // draw radial "color blobs" and blend them
                ForEach(0..<nodes.count, id: \.self) { i in
                    let n = nodes[i]
                    RadialGradient(
                        gradient: Gradient(colors: [n.color, n.color.opacity(0.0)]),
                        center: .center,
                        startRadius: 0,
                        endRadius: min(geo.size.width, geo.size.height) * n.radius
                    )
                    .frame(width: geo.size.width, height: geo.size.height)
                    .position(x: n.pos.x * geo.size.width, y: n.pos.y * geo.size.height)
                    // try different blend modes: .screen, .plusLighter, .overlay
                    .blendMode(.colorDodge)
                   // .blur(radius: 2)
                }
            }
            .compositingGroup() // ensures blend modes compose correctly
            .ignoresSafeArea()
        }
    }
}

#Preview {
    FreeformApproxView()
        .modelContainer(for: Item.self, inMemory: true)
}

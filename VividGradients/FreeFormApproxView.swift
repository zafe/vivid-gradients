//
//  FreeFormApproxView.swift
//  VividGradients
//
//  Created by Fernando Zafe on 29/09/2025.
//

import SwiftUI

struct FreeformApproxView: View {
    @State private var nodePositions: [CGPoint] = [
        CGPoint(x: 0.2, y: 0.3),
        CGPoint(x: 0.6, y: 0.25),
        CGPoint(x: 0.4, y: 0.7),
        CGPoint(x: 0.85, y: 0.6)
    ]
    
    let nodes: [(color: Color, radius: CGFloat)] = [
        (.pink.opacity(0.9), 0.5),
        (.orange.opacity(0.9), 0.45),
        (.cyan.opacity(0.9), 0.6),
        (.purple.opacity(0.85), 0.4)
    ]
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(0..<nodes.count, id: \.self) { i in
                    let n = nodes[i]
                    RadialGradient(
                        gradient: Gradient(colors: [n.color, n.color.opacity(0.0)]),
                        center: .center,
                        startRadius: 0,
                        endRadius: min(geo.size.width, geo.size.height) * n.radius
                    )
                    .frame(width: geo.size.width, height: geo.size.height)
                    .position(
                        x: nodePositions[i].x * geo.size.width,
                        y: nodePositions[i].y * geo.size.height
                    )
                    .blendMode(.colorDodge)
                    .blur(radius: 10)
                }
            }
            .compositingGroup()
            .ignoresSafeArea()
            .onAppear {
                animateRandomly()
            }
        }
    }
    
    private func animateRandomly() {
        withAnimation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true)) {
            for i in 0..<nodePositions.count {
                nodePositions[i] = CGPoint(
                    x: CGFloat.random(in: 0.1...0.9),
                    y: CGFloat.random(in: 0.1...0.9)
                )
            }
        }
    }
}

#Preview {
    FreeformApproxView()
        .modelContainer(for: Item.self, inMemory: true)
}

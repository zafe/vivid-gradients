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
        (.red.opacity(0.9), 0.5),
        (.red.opacity(0.9), 0.45),
        (.red.opacity(0.9), 0.6),
        (.red.opacity(0.85), 0.4)
    ]
    
    let staticNodes: [(position: CGPoint, radius: CGFloat)] = [
        (CGPoint(x: 0.3, y: 0.4), 0.3),
        (CGPoint(x: 0.7, y: 0.3), 0.25),
        (CGPoint(x: 0.5, y: 0.6), 0.35),
        (CGPoint(x: 0.8, y: 0.7), 0.28)
    ]
    
    let blendMode: BlendMode = .overlay
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Static white nodes
                ForEach(0..<staticNodes.count, id: \.self) { i in
                    let n = staticNodes[i]
                    RadialGradient(
                        gradient: Gradient(colors: [.black.opacity(0.7), .black.opacity(0.0)]),
                        center: .center,
                        startRadius: 10,
                        endRadius: min(geo.size.width, geo.size.height) * n.radius
                    )
                    .frame(width: geo.size.width, height: geo.size.height)
                    .position(
                        x: n.position.x * geo.size.width,
                        y: n.position.y * geo.size.height
                    )
                    .blendMode(blendMode)
                }
                
                // Animated colored nodes
                ForEach(0..<nodes.count, id: \.self) { i in
                    let n = nodes[i]
                    RadialGradient(
                        gradient: Gradient(colors: [n.color, n.color.opacity(0.0)]),
                        center: .center,
                        startRadius: 20,
                        endRadius: min(geo.size.width, geo.size.height) * n.radius
                    )
                    .frame(width: geo.size.width, height: geo.size.height)
                    .position(
                        x: nodePositions[i].x * geo.size.width,
                        y: nodePositions[i].y * geo.size.height
                    )
                    .blendMode(blendMode)
                }
            }
            .compositingGroup()
            .blur(radius: 30)
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

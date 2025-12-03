//
//  FrameOverlayView.swift
//  ChefAI
//
//  Created by Claude on 2025-01-30.
//

import SwiftUI

struct FrameOverlayView: View {
    var frameSize: CGFloat = 280
    var cornerLength: CGFloat = 40
    var lineWidth: CGFloat = 4
    var cornerRadius: CGFloat = 12
    var color: Color = .white.opacity(0.8)

    var body: some View {
        GeometryReader { geometry in
            let centerX = geometry.size.width / 2
            let centerY = geometry.size.height / 2
            let halfFrame = frameSize / 2

            ZStack {
                // Top-left corner
                CornerBracket(
                    cornerLength: cornerLength,
                    lineWidth: lineWidth,
                    cornerRadius: cornerRadius,
                    color: color
                )
                .position(x: centerX - halfFrame + cornerLength / 2, y: centerY - halfFrame + cornerLength / 2)

                // Top-right corner
                CornerBracket(
                    cornerLength: cornerLength,
                    lineWidth: lineWidth,
                    cornerRadius: cornerRadius,
                    color: color
                )
                .rotationEffect(.degrees(90))
                .position(x: centerX + halfFrame - cornerLength / 2, y: centerY - halfFrame + cornerLength / 2)

                // Bottom-right corner
                CornerBracket(
                    cornerLength: cornerLength,
                    lineWidth: lineWidth,
                    cornerRadius: cornerRadius,
                    color: color
                )
                .rotationEffect(.degrees(180))
                .position(x: centerX + halfFrame - cornerLength / 2, y: centerY + halfFrame - cornerLength / 2)

                // Bottom-left corner
                CornerBracket(
                    cornerLength: cornerLength,
                    lineWidth: lineWidth,
                    cornerRadius: cornerRadius,
                    color: color
                )
                .rotationEffect(.degrees(270))
                .position(x: centerX - halfFrame + cornerLength / 2, y: centerY + halfFrame - cornerLength / 2)
            }
        }
    }
}

struct CornerBracket: View {
    var cornerLength: CGFloat
    var lineWidth: CGFloat
    var cornerRadius: CGFloat
    var color: Color

    var body: some View {
        Path { path in
            // Vertical line going down
            path.move(to: CGPoint(x: 0, y: cornerLength))
            path.addLine(to: CGPoint(x: 0, y: cornerRadius))

            // Corner arc
            path.addArc(
                center: CGPoint(x: cornerRadius, y: cornerRadius),
                radius: cornerRadius,
                startAngle: .degrees(180),
                endAngle: .degrees(270),
                clockwise: false
            )

            // Horizontal line going right
            path.addLine(to: CGPoint(x: cornerLength, y: 0))
        }
        .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
        .frame(width: cornerLength, height: cornerLength)
    }
}

#Preview {
    ZStack {
        Color.gray
        FrameOverlayView()
    }
}

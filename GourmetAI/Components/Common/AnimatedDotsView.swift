//
//  AnimatedDotsView.swift
//  ChefAI
//
//  Created by Claude on 2025-01-20.
//

import SwiftUI
import Combine

struct AnimatedDotsView: View {
    @State private var dotIndex = 0
    let color: Color
    let size: CGFloat

    private let timer = Timer.publish(every: 0.4, on: .main, in: .common).autoconnect()

    init(color: Color = .black, size: CGFloat = 4) {
        self.color = color
        self.size = size
    }

    var body: some View {
        HStack(spacing: size * 0.5) {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(color)
                    .frame(width: size, height: size)
                    .opacity(index <= dotIndex ? 1 : 0.3)
            }
        }
        .onReceive(timer) { _ in
            withAnimation(.easeInOut(duration: 0.2)) {
                dotIndex = (dotIndex + 1) % 3
            }
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        HStack {
            Text("Thinking")
            AnimatedDotsView()
        }

        HStack {
            Text("Searching")
            AnimatedDotsView(color: .blue, size: 6)
        }

        HStack {
            Text("Calculating")
            AnimatedDotsView(color: .gray, size: 3)
        }
    }
    .padding()
}

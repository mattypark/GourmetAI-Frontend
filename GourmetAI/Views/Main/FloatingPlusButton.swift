//
//  FloatingPlusButton.swift
//  ChefAI
//
//  Created by Claude on 2025-01-28.
//

import SwiftUI

struct FloatingPlusButton: View {
    let onCameraSelected: () -> Void
    let onGallerySelected: () -> Void

    @State private var isExpanded = false

    var body: some View {
        VStack(spacing: 8) {
            // Expanded options (appear above main button)
            if isExpanded {
                // Camera button
                CircleIconButton(icon: "camera.fill", size: 48) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        isExpanded = false
                    }
                    onCameraSelected()
                }
                .transition(.scale.combined(with: .opacity).combined(with: .offset(y: 20)))

                // Gallery button
                CircleIconButton(icon: "photo.on.rectangle", size: 48) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        isExpanded = false
                    }
                    onGallerySelected()
                }
                .transition(.scale.combined(with: .opacity).combined(with: .offset(y: 20)))
            }

            // Main FAB — 55x55 white circle with shadow (matches Figma)
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    isExpanded.toggle()
                }
            } label: {
                Image(systemName: isExpanded ? "xmark" : "plus")
                    .font(.system(size: 21, weight: .medium))
                    .foregroundColor(Color(hex: "1E1E1E"))
                    .frame(width: 55, height: 55)
                    .background(Color.theme.background)
                    .clipShape(Circle())
                    .shadow(color: .black.opacity(0.25), radius: 4, x: 0, y: 4)
                    .rotationEffect(.degrees(isExpanded ? 90 : 0))
            }
        }
    }
}

// MARK: - Circle Icon Button

struct CircleIconButton: View {
    let icon: String
    var size: CGFloat = 48
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(Color(hex: "1E1E1E"))
                .frame(width: size, height: size)
                .background(Color.theme.background)
                .clipShape(Circle())
                .shadow(color: .black.opacity(0.25), radius: 4, x: 0, y: 4)
        }
    }
}

#Preview {
    ZStack {
        Color.gray.opacity(0.1).ignoresSafeArea()
        VStack {
            Spacer()
            HStack {
                Spacer()
                FloatingPlusButton(
                    onCameraSelected: { print("Camera") },
                    onGallerySelected: { print("Gallery") }
                )
                .padding(.trailing, 38)
                .padding(.bottom, 96)
            }
        }
    }
}

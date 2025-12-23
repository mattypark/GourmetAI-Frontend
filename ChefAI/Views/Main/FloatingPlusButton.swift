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
                // Camera button (top)
                CircleIconButton(icon: "camera.fill") {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        isExpanded = false
                    }
                    onCameraSelected()
                }
                .transition(.scale.combined(with: .opacity).combined(with: .offset(y: 20)))

                // Upload button (middle)
                CircleIconButton(icon: "photo.on.rectangle") {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        isExpanded = false
                    }
                    onGallerySelected()
                }
                .transition(.scale.combined(with: .opacity).combined(with: .offset(y: 20)))
            }

            // Main plus/close button
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    isExpanded.toggle()
                }
            } label: {
                Image(systemName: isExpanded ? "xmark" : "plus")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(.black)
                    .frame(width: 60, height: 60)
                    .background(Color.white)
                    .clipShape(Circle())
                    .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
                    .rotationEffect(.degrees(isExpanded ? 90 : 0))
            }
        }
    }
}

// MARK: - Circle Icon Button

struct CircleIconButton: View {
    let icon: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 24, weight: .medium))
                .foregroundColor(.black)
                .frame(width: 56, height: 56)
                .background(Color.white)
                .clipShape(Circle())
                .shadow(color: .black.opacity(0.15), radius: 6, x: 0, y: 3)
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
                .padding(.trailing, 24)
                .padding(.bottom, 40)
            }
        }
    }
}

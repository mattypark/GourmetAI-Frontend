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
        ZStack {
            // Dimmed background when expanded
            if isExpanded {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            isExpanded = false
                        }
                    }
            }

            VStack(spacing: 16) {
                // Expanded options
                if isExpanded {
                    // Gallery option
                    ExpandedOptionButton(
                        icon: "photo.on.rectangle",
                        label: "Upload Photo"
                    ) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            isExpanded = false
                        }
                        onGallerySelected()
                    }
                    .transition(.asymmetric(
                        insertion: .scale.combined(with: .opacity).combined(with: .offset(y: 20)),
                        removal: .scale.combined(with: .opacity)
                    ))

                    // Camera option
                    ExpandedOptionButton(
                        icon: "camera.fill",
                        label: "Take Photo"
                    ) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            isExpanded = false
                        }
                        onCameraSelected()
                    }
                    .transition(.asymmetric(
                        insertion: .scale.combined(with: .opacity).combined(with: .offset(y: 20)),
                        removal: .scale.combined(with: .opacity)
                    ))
                }

                // Main plus button
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
}

// MARK: - Expanded Option Button

struct ExpandedOptionButton: View {
    let icon: String
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.black)

                Text(label)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.black)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(Color.white)
            .cornerRadius(25)
            .shadow(color: .black.opacity(0.12), radius: 8, x: 0, y: 4)
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

//
//  CustomTabBar.swift
//  ChefAI
//
//  Custom pill-style bottom tab bar with matchedGeometryEffect pill
//  and integrated floating + button
//

import SwiftUI

struct CustomTabBar: View {
    @Binding var selectedTab: AppTab
    var onCameraSelected: (() -> Void)?
    var onGallerySelected: (() -> Void)?

    @Namespace private var pillNamespace
    @State private var plusExpanded = false

    var body: some View {
        ZStack(alignment: .topTrailing) {
            // Tab bar island
            HStack(spacing: 0) {
                ForEach(AppTab.allCases, id: \.self) { tab in
                    tabButton(for: tab)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 28)
                    .fill(Color.theme.background)
                    .shadow(color: .black.opacity(0.08), radius: 10, y: 2)
            )
            .padding(.horizontal, 20)

            // Floating + button at top-right corner
            plusButton
                .offset(x: -12, y: -30)
        }
        .padding(.bottom, 4)
    }

    // MARK: - Tab Button

    @ViewBuilder
    private func tabButton(for tab: AppTab) -> some View {
        Button {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                selectedTab = tab
            }
        } label: {
            ZStack {
                // Pill background — only behind active tab, animated with matchedGeometry
                if selectedTab == tab {
                    Capsule()
                        .fill(Color.black)
                        .matchedGeometryEffect(id: "activePill", in: pillNamespace)
                }

                // Content
                HStack(spacing: 5) {
                    Image(systemName: tab.icon)
                        .font(.system(size: 13, weight: .medium))

                    if selectedTab == tab {
                        Text(tab.label)
                            .font(.system(size: 11, weight: .semibold))
                            .transition(.opacity.combined(with: .scale(scale: 0.8)))
                    }
                }
                .foregroundColor(selectedTab == tab ? .white : .gray.opacity(0.4))
                .padding(.horizontal, selectedTab == tab ? 12 : 0)
                .padding(.vertical, 8)
            }
            .frame(height: 36)
        }
    }

    // MARK: - Plus Button

    private var plusButton: some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                plusExpanded.toggle()
            }
        } label: {
            Image(systemName: plusExpanded ? "xmark" : "plus")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(Color(hex: "1E1E1E"))
                .frame(width: 46, height: 46)
                .background(Color.theme.background)
                .clipShape(Circle())
                .shadow(color: .black.opacity(0.18), radius: 4, x: 0, y: 2)
                .rotationEffect(.degrees(plusExpanded ? 90 : 0))
        }
        .overlay(alignment: .bottom) {
            if plusExpanded {
                VStack(spacing: 6) {
                    CircleIconButton(icon: "camera.fill", size: 40) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            plusExpanded = false
                        }
                        onCameraSelected?()
                    }
                    .transition(.scale.combined(with: .opacity).combined(with: .offset(y: 10)))

                    CircleIconButton(icon: "photo.on.rectangle", size: 40) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            plusExpanded = false
                        }
                        onGallerySelected?()
                    }
                    .transition(.scale.combined(with: .opacity).combined(with: .offset(y: 10)))
                }
                .offset(y: -52)
            }
        }
    }
}

#Preview {
    VStack {
        Spacer()
        CustomTabBar(
            selectedTab: .constant(.home),
            onCameraSelected: { print("Camera") },
            onGallerySelected: { print("Gallery") }
        )
    }
    .background(Color.gray.opacity(0.1))
}

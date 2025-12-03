//
//  MainTabView.swift
//  ChefAI
//
//  Created by Claude on 2025-01-28.
//

import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    @State private var showingCaptureScreen = false
    @State private var refreshID = UUID()

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView(refreshID: $refreshID)
                .tag(0)
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }

            Color.clear
                .tag(1)
                .tabItem {
                    Label("Add", systemImage: "plus.circle.fill")
                }
        }
        .tint(.white)
        .toolbarBackground(.ultraThinMaterial, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
        .onChange(of: selectedTab) { oldValue, newValue in
            if newValue == 1 {
                showingCaptureScreen = true
                // Reset to home tab
                selectedTab = 0
            }
        }
        .fullScreenCover(isPresented: $showingCaptureScreen, onDismiss: {
            // Refresh HomeView when capture screen closes
            refreshID = UUID()
        }) {
            CaptureScreenView()
        }
    }
}

#Preview {
    MainTabView()
}

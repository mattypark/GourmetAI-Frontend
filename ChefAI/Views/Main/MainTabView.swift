//
//  MainTabView.swift
//  ChefAI
//
//  Created by Claude on 2025-01-28.
//

import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    @State private var showingCameraSheet = false
    @State private var refreshID = UUID()

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                HomeView()
                    .id(refreshID) // Force refresh when ID changes
                    .tag(0)
                    .tabItem {
                        Label("Home", systemImage: "house.fill")
                    }

                Color.clear
                    .tag(1)
                    .tabItem {
                        Label("", systemImage: "")
                    }

                SettingsView()
                    .tag(2)
                    .tabItem {
                        Label("Settings", systemImage: "gearshape.fill")
                    }
            }
            .tint(.white)

            // Floating Plus Button
            FloatingPlusButton {
                showingCameraSheet = true
            }
            .offset(y: -30)
        }
        .sheet(isPresented: $showingCameraSheet, onDismiss: {
            // Refresh HomeView when camera sheet closes
            refreshID = UUID()
        }) {
            CameraSheetView()
        }
    }
}

#Preview {
    MainTabView()
}

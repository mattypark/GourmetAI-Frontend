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
        ZStack {
            TabView(selection: $selectedTab) {
                HomeView(refreshID: $refreshID)
                    .tag(0)
                    .tabItem {
                        Label("Home", systemImage: "house.fill")
                    }

                StarredView(refreshID: $refreshID)
                    .tag(1)
                    .tabItem {
                        Label("Starred", systemImage: "star.fill")
                    }

                ProfileView()
                    .tag(2)
                    .tabItem {
                        Label("Profile", systemImage: "person.fill")
                    }
            }
            .tint(.black)

            // Floating Action Button Overlay
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    FloatingPlusButton {
                        showingCaptureScreen = true
                    }
                    .padding(.trailing, 24)
                    .padding(.bottom, 90) // Position above tab bar
                }
            }
        }
        .fullScreenCover(isPresented: $showingCaptureScreen, onDismiss: {
            // Refresh views when capture screen closes
            refreshID = UUID()
        }) {
            CaptureScreenView()
        }
    }
}

#Preview {
    MainTabView()
}

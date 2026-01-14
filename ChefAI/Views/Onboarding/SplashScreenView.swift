//
//  SplashScreenView.swift
//  ChefAI
//
//  Splash screen with Chef AI logo - shown on app launch
//

import SwiftUI

struct SplashScreenView: View {
    @Binding var isActive: Bool
    @State private var opacity: Double = 1

    var body: some View {
        ZStack {
            // White background
            Color.white
                .ignoresSafeArea()

            // Chef AI Logo and text - horizontal layout
            HStack(spacing: 12) {
                // Logo image from assets (crossed fork & knife)
                Image("ChefAILogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 48, height: 48)

                // Chef AI text - bold like welcome screen headline
                Text("Chef AI")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.black)
            }
        }
        .opacity(opacity)
        .onAppear {
            // Fade out splash screen after delay, then transition
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                withAnimation(.easeOut(duration: 0.5)) {
                    opacity = 0
                }
                // After fade out completes, switch to welcome
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    isActive = false
                }
            }
        }
    }
}

#Preview {
    SplashScreenView(isActive: .constant(true))
}

//
//  WelcomeScreenView.swift
//  ChefAI
//
//  Welcome screen - "Eat better. Cook smarter."
//

import SwiftUI

struct WelcomeScreenView: View {
    var onGetStarted: () -> Void
    var onSignIn: () -> Void

    @State private var opacity: Double = 0

    var body: some View {
        ZStack {
            // White background
            Color.theme.background
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Main content area (where app preview would go)
                // This is the white space in the middle of the screen

                Spacer()

                // Bottom section with headline and buttons
                VStack(spacing: 24) {
                    // Headline
                    VStack(spacing: 4) {
                        Text("Eat better.")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.black)

                        Text("Cook smarter.")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.black)
                    }

                    // Get Started button
                    Button(action: onGetStarted) {
                        Text("Get Started")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Color.black)
                            .cornerRadius(28)
                    }
                    .padding(.horizontal, 24)

                    // Already have an account? Sign in
                    HStack(spacing: 4) {
                        Text("Already have an account?")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)

                        Button(action: onSignIn) {
                            Text("Sign in")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.black)
                                .underline()
                        }
                    }
                }
                .padding(.bottom, 40)
            }
            .opacity(opacity)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.4)) {
                opacity = 1
            }
        }
    }
}

#Preview {
    WelcomeScreenView(
        onGetStarted: { print("Get Started tapped") },
        onSignIn: { print("Sign In tapped") }
    )
}

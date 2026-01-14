//
//  PaywallView.swift
//  ChefAI
//
//  Paywall screen - "Unlock the full Chef experience"
//

import SwiftUI

struct PaywallView: View {
    var onGetStarted: () -> Void
    var onSignIn: () -> Void
    var onDismiss: (() -> Void)?
    var onRestore: (() -> Void)?

    @State private var opacity: Double = 0

    var body: some View {
        ZStack {
            // White background
            Color.white
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Top bar with restore button
                HStack {
                    Spacer()

                    Button(action: {
                        onRestore?()
                    }) {
                        Text("restore")
                            .font(.system(size: 15))
                            .foregroundColor(.gray)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)

                Spacer()

                // Main content - Headline
                VStack(spacing: 4) {
                    Text("Unlock the full Chef")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.black)
                        .multilineTextAlignment(.center)

                    Text("experience")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.black)
                        .multilineTextAlignment(.center)
                }

                Spacer()

                // Bottom section
                VStack(spacing: 16) {
                    // No Payment Due Now checkmark
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.black)

                        Text("No Payment Due Now")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.black)
                    }

                    // Continue button
                    Button(action: onGetStarted) {
                        Text("Continue")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Color.black)
                            .cornerRadius(28)
                    }
                    .padding(.horizontal, 24)

                    // Pricing text
                    Text("Just $9.99 per month")
                        .font(.system(size: 13))
                        .foregroundColor(.gray)
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
    PaywallView(
        onGetStarted: { print("Continue tapped") },
        onSignIn: { print("Sign In tapped") },
        onRestore: { print("Restore tapped") }
    )
}

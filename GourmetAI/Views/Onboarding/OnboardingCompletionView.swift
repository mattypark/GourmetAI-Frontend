//
//  OnboardingCompletionView.swift
//  ChefAI
//
//  Shown after the last onboarding question. Celebratory screen before navigating to home.
//

import SwiftUI

struct OnboardingCompletionView: View {
    let userName: String
    let onStartCooking: () -> Void

    @State private var showTitle = false
    @State private var showSubtitle = false
    @State private var showButton = false
    @State private var checkmarkScale: CGFloat = 0

    var body: some View {
        ZStack {
            Color.theme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Checkmark circle
                ZStack {
                    Circle()
                        .fill(Color.black)
                        .frame(width: 100, height: 100)

                    Image(systemName: "checkmark")
                        .font(.system(size: 44, weight: .bold))
                        .foregroundColor(.white)
                }
                .scaleEffect(checkmarkScale)
                .padding(.bottom, 32)

                // Title
                Text("Excellent!")
                    .font(.system(size: 34, weight: .bold))
                    .foregroundColor(.black)
                    .opacity(showTitle ? 1 : 0)
                    .offset(y: showTitle ? 0 : 20)
                    .padding(.bottom, 8)

                // Subtitle
                Text(userName.isEmpty ? "You're ready to cook!" : "\(userName), you're ready to cook!")
                    .font(.system(size: 17))
                    .foregroundColor(.gray)
                    .opacity(showSubtitle ? 1 : 0)
                    .offset(y: showSubtitle ? 0 : 20)

                Spacer()

                // Start Cooking button
                Button(action: onStartCooking) {
                    Text("Start Cooking")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.black)
                        .cornerRadius(28)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
                .opacity(showButton ? 1 : 0)
                .offset(y: showButton ? 0 : 20)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.1)) {
                checkmarkScale = 1.0
            }
            withAnimation(.easeOut(duration: 0.5).delay(0.4)) {
                showTitle = true
            }
            withAnimation(.easeOut(duration: 0.5).delay(0.6)) {
                showSubtitle = true
            }
            withAnimation(.easeOut(duration: 0.5).delay(0.9)) {
                showButton = true
            }
        }
    }
}

#Preview {
    OnboardingCompletionView(userName: "Matthew") {
        print("Start cooking tapped")
    }
}

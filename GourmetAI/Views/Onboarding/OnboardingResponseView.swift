//
//  OnboardingResponseView.swift
//  ChefAI
//
//  A personalized response screen that shows after specific onboarding questions.
//  Text lines fade in sequentially, then user taps to continue.
//

import SwiftUI

struct OnboardingResponseView: View {
    let response: OnboardingResponse
    var onContinue: () -> Void

    // Animation states for each line
    @State private var line1Opacity: Double = 0
    @State private var line2Opacity: Double = 0
    @State private var line3Opacity: Double = 0
    @State private var arrowOpacity: Double = 0

    var body: some View {
        ZStack {
            // White background
            Color.white
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                // Lines that fade in sequentially
                VStack(spacing: 16) {
                    if response.lines.count > 0 {
                        Text(response.lines[0])
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.black)
                            .multilineTextAlignment(.center)
                            .opacity(line1Opacity)
                    }

                    if response.lines.count > 1 {
                        Text(response.lines[1])
                            .font(.system(size: 18, weight: .regular))
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .opacity(line2Opacity)
                    }

                    if response.lines.count > 2 {
                        Text(response.lines[2])
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.black)
                            .multilineTextAlignment(.center)
                            .opacity(line3Opacity)
                    }
                }
                .padding(.horizontal, 32)

                Spacer()

                // Continue arrow/indicator
                VStack(spacing: 8) {
                    Image(systemName: "chevron.down")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(.black.opacity(0.5))

                    Text("Tap to continue")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                }
                .opacity(arrowOpacity)
                .padding(.bottom, 60)
            }
        }
        .contentShape(Rectangle())  // Make entire view tappable
        .onTapGesture {
            onContinue()
        }
        .onAppear {
            startAnimations()
        }
    }

    private func startAnimations() {
        // Line 1 fades in after 0.3s
        withAnimation(.easeOut(duration: 0.5).delay(0.3)) {
            line1Opacity = 1
        }

        // Line 2 fades in after 0.8s
        withAnimation(.easeOut(duration: 0.5).delay(0.8)) {
            line2Opacity = 1
        }

        // Line 3 fades in after 1.3s
        withAnimation(.easeOut(duration: 0.5).delay(1.3)) {
            line3Opacity = 1
        }

        // Arrow fades in after 1.8s
        withAnimation(.easeOut(duration: 0.5).delay(1.8)) {
            arrowOpacity = 1
        }
    }
}

#Preview {
    OnboardingResponseView(
        response: OnboardingResponse(
            id: 1,
            triggerAfterQuestionId: 10,
            lines: [
                "Great choice!",
                "Did you know 73% of people want to cook more but don't know where to start?",
                "Gourmet AI will make it easy for you."
            ]
        ),
        onContinue: { print("Continue tapped") }
    )
}

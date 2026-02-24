//
//  RetentionOfferView.swift
//  ChefAI
//
//  "24 hours, on me" retention offer when user tries to dismiss paywall.
//

import SwiftUI

struct RetentionOfferView: View {
    var onAccept: () -> Void
    var onDecline: () -> Void

    @State private var showContent = false

    var body: some View {
        ZStack {
            Color.theme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                // Close button
                HStack {
                    Spacer()
                    Button {
                        onDecline()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.black)
                            .frame(width: 36, height: 36)
                            .background(Color(white: 0.93))
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)

                Spacer()

                // Content
                VStack(spacing: 20) {
                    // Clock icon
                    Image(systemName: "clock.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.black)
                        .opacity(showContent ? 1 : 0)
                        .scaleEffect(showContent ? 1 : 0.5)

                    // Title
                    Text("24 hours, on me")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.black)
                        .opacity(showContent ? 1 : 0)
                        .offset(y: showContent ? 0 : 20)

                    // Subtitle
                    VStack(spacing: 12) {
                        Text("I'd love for you to try the app. Here's a 24-hour trial on me. Nothing you need to do, it's already activated.")
                            .font(.system(size: 16))
                            .foregroundColor(.black)
                            .multilineTextAlignment(.center)

                        Text("No credit card required. Just enjoy!")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.black)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, 24)
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : 20)
                }

                Spacer()

                // Accept button
                Button(action: onAccept) {
                    Text("Sounds good!")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.black)
                        .cornerRadius(28)
                }
                .padding(.horizontal, 24)
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : 20)

                // No thanks
                Button {
                    onDecline()
                } label: {
                    Text("No thanks")
                        .font(.system(size: 15))
                        .foregroundColor(.gray)
                }
                .padding(.top, 12)
                .padding(.bottom, 32)
                .opacity(showContent ? 1 : 0)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.6).delay(0.2)) {
                showContent = true
            }
        }
    }
}

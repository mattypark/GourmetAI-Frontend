//
//  WelcomeGradientOverlayView.swift
//  ChefAI
//
//  Full-screen animated blue gradient "Welcome" overlay.
//  Shown once per fresh app launch when the user is onboarded, authenticated,
//  and has an active subscription.
//

import SwiftUI
import Combine

struct WelcomeGradientOverlayView: View {
    let userName: String
    let onDismiss: () -> Void

    // MARK: - Animation State

    @State private var gradientPhase: CGFloat = 0
    @State private var secondaryPhase: CGFloat = 0.3
    @State private var tertiaryPhase: CGFloat = 0.7
    @State private var textOpacity: Double = 0
    @State private var textScale: CGFloat = 0.92
    @State private var dismissing = false

    // MARK: - Gradient Colors (blue palette)

    private let deepBlue = Color(red: 0.05, green: 0.10, blue: 0.35)
    private let mediumBlue = Color(red: 0.12, green: 0.25, blue: 0.65)
    private let brightBlue = Color(red: 0.20, green: 0.45, blue: 0.90)
    private let skyBlue = Color(red: 0.35, green: 0.60, blue: 0.95)
    private let lightBlue = Color(red: 0.55, green: 0.75, blue: 1.0)
    private let accentIndigo = Color(red: 0.25, green: 0.15, blue: 0.60)

    var body: some View {
        ZStack {
            // Layer 1: Deep angular gradient (slowest rotation)
            AngularGradient(
                gradient: Gradient(colors: [
                    deepBlue, mediumBlue, accentIndigo,
                    deepBlue, brightBlue, deepBlue
                ]),
                center: .center,
                startAngle: .degrees(Double(gradientPhase) * 360),
                endAngle: .degrees(Double(gradientPhase) * 360 + 360)
            )
            .ignoresSafeArea()

            // Layer 2: Radial gradient overlay (organic motion)
            RadialGradient(
                gradient: Gradient(colors: [
                    brightBlue.opacity(0.6),
                    mediumBlue.opacity(0.3),
                    Color.clear
                ]),
                center: UnitPoint(
                    x: 0.3 + 0.4 * cos(Double(secondaryPhase) * .pi * 2),
                    y: 0.3 + 0.4 * sin(Double(secondaryPhase) * .pi * 2)
                ),
                startRadius: 50,
                endRadius: 500
            )
            .ignoresSafeArea()
            .blendMode(.screen)

            // Layer 3: Secondary radial glow (counter-motion)
            RadialGradient(
                gradient: Gradient(colors: [
                    skyBlue.opacity(0.5),
                    lightBlue.opacity(0.2),
                    Color.clear
                ]),
                center: UnitPoint(
                    x: 0.7 - 0.3 * cos(Double(tertiaryPhase) * .pi * 2),
                    y: 0.6 + 0.3 * sin(Double(tertiaryPhase) * .pi * 2)
                ),
                startRadius: 30,
                endRadius: 400
            )
            .ignoresSafeArea()
            .blendMode(.screen)

            // Layer 4: Soft linear sweep (shimmer)
            LinearGradient(
                colors: [
                    Color.clear,
                    lightBlue.opacity(0.15),
                    Color.white.opacity(0.08),
                    Color.clear
                ],
                startPoint: UnitPoint(
                    x: Double(gradientPhase) - 0.2,
                    y: 0.3
                ),
                endPoint: UnitPoint(
                    x: Double(gradientPhase) + 0.5,
                    y: 0.8
                )
            )
            .ignoresSafeArea()

            // Text content
            VStack(spacing: 8) {
                Text("Welcome")
                    .font(.system(size: 42, weight: .bold, design: .default))
                    .foregroundColor(.white)

                Text(userName.isEmpty ? "Chef" : userName)
                    .font(.system(size: 42, weight: .bold, design: .default))
                    .foregroundColor(.white)
            }
            .shadow(color: .black.opacity(0.25), radius: 12, x: 0, y: 4)
            .opacity(textOpacity)
            .scaleEffect(textScale)
        }
        .opacity(dismissing ? 0 : 1)
        .scaleEffect(dismissing ? 1.05 : 1.0)
        .onAppear {
            startAnimations()
            scheduleAutoDismiss()
        }
    }

    // MARK: - Animations

    private func startAnimations() {
        // Text fade in
        withAnimation(.easeOut(duration: 0.8).delay(0.2)) {
            textOpacity = 1.0
            textScale = 1.0
        }

        // Gradient layer 1: slow rotation
        withAnimation(
            .linear(duration: 8.0)
            .repeatForever(autoreverses: false)
        ) {
            gradientPhase = 1.0
        }

        // Gradient layer 2: organic motion
        withAnimation(
            .easeInOut(duration: 3.0)
            .repeatForever(autoreverses: true)
        ) {
            secondaryPhase = 1.0
        }

        // Gradient layer 3: counter-motion
        withAnimation(
            .easeInOut(duration: 2.5)
            .repeatForever(autoreverses: true)
        ) {
            tertiaryPhase = 1.0
        }
    }

    private func scheduleAutoDismiss() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation(.easeInOut(duration: 0.6)) {
                dismissing = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                onDismiss()
            }
        }
    }
}

// MARK: - Launch Welcome Gate

/// Manages whether the welcome gradient overlay should be shown.
/// Shows once per fresh app launch session — not persisted to disk.
class WelcomeOverlayManager: ObservableObject {
    static let shared = WelcomeOverlayManager()

    /// Whether the overlay is currently being displayed
    @Published var isShowingOverlay = false

    /// Tracks if we've already shown the overlay this launch session (in-memory only)
    private var hasShownThisSession = false

    private init() {}

    /// Call this when the app determines the user should see the home screen.
    /// Checks all conditions and triggers the overlay if appropriate.
    func checkAndShow(
        isOnboarded: Bool,
        isAuthenticated: Bool,
        hasAccess: Bool
    ) {
        guard !hasShownThisSession,
              isOnboarded,
              isAuthenticated,
              hasAccess else {
            return
        }

        hasShownThisSession = true
        isShowingOverlay = true
    }

    func dismiss() {
        isShowingOverlay = false
    }
}

#Preview {
    WelcomeGradientOverlayView(
        userName: "Matthew",
        onDismiss: {}
    )
}

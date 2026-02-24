//
//  LiquidGlassSplashView.swift
//  ChefAI
//
//  Single unified intro + welcome screen with a persistent liquid glass orb.
//
//  STATE A (Intro — progress ≈ 0):
//    Warm cream bg. "A new era of cooking is here." centered text.
//    Large frosted glass dome at bottom (~10px from screen edges).
//    "Swipe up to enter" hint above the dome.
//
//  STATE B (Welcome — progress ≈ 1):
//    Background with looping video area. Welcome content (headline + auth buttons).
//    The glass orb persists and is FREELY DRAGGABLE.
//    Welcome content moves proportionally with orb drag.
//    Letting go → springs back to center.
//    Dragging all the way down → fades back to intro state.
//

import SwiftUI
import AVFoundation

// MARK: - Looping Video Player

struct LoopingVideoPlayer: UIViewRepresentable {
    let videoName: String
    let videoExtension: String

    func makeUIView(context: Context) -> UIView {
        let view = PlayerUIView(videoName: videoName, videoExtension: videoExtension)
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {}
}

class PlayerUIView: UIView {
    private var playerLayer = AVPlayerLayer()
    private var playerLooper: AVPlayerLooper?
    private var queuePlayer: AVQueuePlayer?

    init(videoName: String, videoExtension: String) {
        super.init(frame: .zero)

        guard let url = Bundle.main.url(forResource: videoName, withExtension: videoExtension) else {
            return
        }

        let asset = AVURLAsset(url: url)
        let item = AVPlayerItem(asset: asset)
        let player = AVQueuePlayer(playerItem: item)
        playerLooper = AVPlayerLooper(player: player, templateItem: item)
        queuePlayer = player

        playerLayer.player = player
        playerLayer.videoGravity = .resizeAspectFill
        layer.addSublayer(playerLayer)

        player.isMuted = true
        player.play()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer.frame = bounds
    }
}

// MARK: - Main View

struct LiquidGlassSplashView: View {
    var onGoogleSignIn: () -> Void
    var onAppleSignIn: () -> Void

    // MARK: - Phase

    @State private var isWelcomeRevealed = false

    // MARK: - Transition gesture (intro → welcome)

    @State private var transitionProgress: CGFloat = 0
    @State private var isTransitionDragging = false

    // MARK: - Free-drag orb (welcome state)

    @State private var orbOffset: CGSize = .zero
    @State private var isOrbDragging = false

    // MARK: - Entry animations

    @State private var appeared = false
    @State private var textOpacity: Double = 0
    @State private var textOffsetY: CGFloat = 12
    @State private var glowPhase: CGFloat = 0

    // MARK: - Constants

    private let orbDiameter: CGFloat = 150
    private let dragRange: CGFloat = 380
    private let bgIntro = Color.theme.background
    private let edgeInset: CGFloat = 10 // 10px from screen edges

    var body: some View {
        GeometryReader { geo in
            let screenW = max(geo.size.width, 1)
            let screenH = max(geo.size.height, 1)
            let domeWidth = max(screenW - edgeInset * 2, 1)
            let domeHeight = max(screenH * 0.32, 1)

            ZStack {
                // ============================================================
                // LAYER 0: Welcome content (revealed by transition)
                // ============================================================
                welcomeContent(screenW: screenW, screenH: screenH)
                    .opacity(Double(smoothstep(transitionProgress, edge0: 0.3, edge1: 0.8)))

                // ============================================================
                // LAYER 1: Intro background (fades out as progress → 1)
                // ============================================================
                bgIntro
                    .ignoresSafeArea()
                    .opacity(Double(1 - smoothstep(transitionProgress, edge0: 0.3, edge1: 0.85)))
                    .allowsHitTesting(false)

                // ============================================================
                // LAYER 2: Intro text — "A new era of cooking is here."
                // ============================================================
                VStack(spacing: 2) {
                    Text("A new era of")
                        .font(.system(size: 34, weight: .bold))
                        .foregroundColor(.black)
                    Text("cooking is here.")
                        .font(.system(size: 34, weight: .bold))
                        .foregroundColor(.black)
                }
                .opacity(textOpacity * Double(1 - smoothstep(transitionProgress, edge0: 0.0, edge1: 0.4)))
                .offset(y: textOffsetY - transitionProgress * 30)
                .position(x: screenW / 2, y: screenH * 0.38)
                .allowsHitTesting(false)

                // ============================================================
                // LAYER 3: Glass dome at bottom (intro resting state)
                // ============================================================
                if !isWelcomeRevealed {
                    glassDome(screenW: screenW, screenH: screenH, domeWidth: domeWidth, domeHeight: domeHeight)
                        .opacity(Double(1 - smoothstep(transitionProgress, edge0: 0.4, edge1: 0.85)))
                }

                // ============================================================
                // LAYER 4: "Swipe up to enter" hint
                // ============================================================
                Text("Swipe up to enter")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(Color(white: 0.55))
                    .tracking(0.5)
                    .position(x: screenW / 2, y: screenH - domeHeight * 0.50)
                    .opacity(textOpacity * Double(1 - smoothstep(transitionProgress, edge0: 0.0, edge1: 0.25)))
                    .allowsHitTesting(false)

                // ============================================================
                // LAYER 5: Glass orb — freely draggable in welcome state
                // ============================================================
                glassOrb(screenW: screenW, screenH: screenH, domeHeight: domeHeight)
            }
            .gesture(transitionDragGesture(screenH: screenH, domeHeight: domeHeight))
        }
        .ignoresSafeArea()
        .onAppear {
            startEntryAnimations()
        }
    }

    // MARK: - Welcome Content

    private func welcomeContent(screenW: CGFloat, screenH: CGFloat) -> some View {
        // Welcome content shifts proportionally with orb drag
        let contentShift = isWelcomeRevealed ? orbOffset.height * 0.4 : 0

        return ZStack {
            Color.theme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                // Video area (top portion of screen)
                ZStack {
                    // Video player — will play if video file exists, otherwise show placeholder
                    LoopingVideoPlayer(videoName: "WelcomeVideo", videoExtension: "mp4")
                        .frame(maxWidth: .infinity)
                        .frame(height: screenH * 0.52)
                        .clipped()
                        .overlay(
                            // Gradient fade at bottom so video blends into content
                            LinearGradient(
                                colors: [.clear, .clear, Color.theme.background.opacity(0.6), Color.theme.background],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                }

                Spacer()

                // Bottom section with headline and auth buttons
                VStack(spacing: 24) {
                    VStack(spacing: 4) {
                        Text("Eat better.")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.black)

                        Text("Cook smarter.")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.black)
                    }

                    VStack(spacing: 12) {
                        // Continue with Google
                        Button(action: onGoogleSignIn) {
                            HStack(spacing: 12) {
                                Image("GoogleLogo")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 20, height: 20)

                                Text("Continue with Google")
                                    .font(.system(size: 17, weight: .semibold))
                                    .foregroundColor(.black)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Color.theme.background)
                            .cornerRadius(28)
                            .overlay(
                                RoundedRectangle(cornerRadius: 28)
                                    .stroke(Color.black, lineWidth: 1)
                            )
                        }

                        // Continue with Apple
                        Button(action: onAppleSignIn) {
                            HStack(spacing: 12) {
                                Image(systemName: "apple.logo")
                                    .font(.system(size: 20, weight: .medium))
                                    .foregroundColor(.white)

                                Text("Continue with Apple")
                                    .font(.system(size: 17, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Color.black)
                            .cornerRadius(28)
                        }
                    }
                    .padding(.horizontal, 24)

                    // Terms and Privacy
                    VStack(spacing: 4) {
                        Text("By continuing, you agree to our")
                            .font(.caption)
                            .foregroundColor(.gray)

                        HStack(spacing: 4) {
                            Text("Terms of Service")
                                .font(.caption)
                                .foregroundColor(.black)

                            Text("and")
                                .font(.caption)
                                .foregroundColor(.gray)

                            Text("Privacy Policy")
                                .font(.caption)
                                .foregroundColor(.black)
                        }
                    }
                }
                .padding(.bottom, 40)
            }
            .offset(y: contentShift)
            // Fade out content as orb drags down toward intro
            .opacity(isWelcomeRevealed ? Double(1.0 - smoothstep(orbOffset.height, edge0: 50, edge1: 250)) : 1.0)
        }
    }

    // MARK: - Glass Dome (bottom of screen, intro state — 10px from edges)

    private func glassDome(screenW: CGFloat, screenH: CGFloat, domeWidth: CGFloat, domeHeight: CGFloat) -> some View {
        let domeCenterY = screenH + domeHeight * 0.10

        // Morph dome into orb during transition
        let morphProgress = min(transitionProgress / 0.5, 1.0)
        let currentWidth = max(domeWidth - morphProgress * (domeWidth - orbDiameter), 1)
        let currentHeight = max(domeHeight * 2 - morphProgress * (domeHeight * 2 - orbDiameter), 1)
        let orbTargetY = screenH * 0.40
        let currentY = domeCenterY - transitionProgress * (domeCenterY - orbTargetY)

        return ZStack {
            // Dome body — frosted glass with depth
            Ellipse()
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: [
                            Color.white.opacity(0.40),
                            Color(white: 0.93).opacity(0.70),
                            Color(white: 0.95).opacity(0.55),
                            Color(white: 0.96).opacity(0.40)
                        ]),
                        center: .init(x: 0.5, y: 0.18),
                        startRadius: 0,
                        endRadius: currentWidth * 0.55
                    )
                )
                .frame(width: currentWidth, height: currentHeight)
                .position(x: screenW / 2, y: currentY)

            // Glass blur layer
            Ellipse()
                .fill(.ultraThinMaterial)
                .frame(width: currentWidth * 0.98, height: currentHeight * 0.98)
                .position(x: screenW / 2, y: currentY)
                .opacity(0.6)

            // Dome highlight arc — bright curved line at the top
            Ellipse()
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.0),
                            Color.white.opacity(0.90),
                            Color.white.opacity(1.0),
                            Color.white.opacity(0.90),
                            Color.white.opacity(0.0)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    lineWidth: 2.5
                )
                .frame(width: currentWidth * 0.82, height: currentHeight * 0.88)
                .position(x: screenW / 2, y: currentY)

            // Inner bright area near top of dome (glass highlight)
            Ellipse()
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: [
                            Color.white.opacity(0.95),
                            Color.white.opacity(0.45),
                            Color.clear
                        ]),
                        center: .init(x: 0.5, y: 0.12),
                        startRadius: 0,
                        endRadius: currentWidth * 0.32
                    )
                )
                .frame(width: currentWidth * 0.7, height: currentHeight * 0.5)
                .position(x: screenW / 2, y: currentY - currentHeight * 0.14)

            // Shimmer sweep across dome surface
            Ellipse()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.clear,
                            Color.white.opacity(0.40),
                            Color.clear
                        ],
                        startPoint: UnitPoint(x: glowPhase - 0.3, y: 0.3),
                        endPoint: UnitPoint(x: glowPhase + 0.3, y: 0.7)
                    )
                )
                .frame(width: currentWidth * 0.75, height: currentHeight * 0.5)
                .position(x: screenW / 2, y: currentY - currentHeight * 0.05)
        }
    }

    // MARK: - Glass Orb (persistent, freely draggable)

    private func glassOrb(screenW: CGFloat, screenH: CGFloat, domeHeight: CGFloat) -> some View {
        let orbSize: CGFloat = orbDiameter

        // Resting position in welcome state
        let restingCenter = CGPoint(x: screenW / 2, y: screenH * 0.40)

        // During intro transition, orb rises from dome position
        let domeTopY = screenH - domeHeight * 0.55
        let introOrbY = domeTopY - transitionProgress * (domeTopY - restingCenter.y)

        // In welcome state, orb sits at resting center + free drag offset
        let orbX: CGFloat = isWelcomeRevealed
            ? restingCenter.x + orbOffset.width
            : screenW / 2
        let orbY: CGFloat = isWelcomeRevealed
            ? restingCenter.y + orbOffset.height
            : introOrbY

        let showOrb = transitionProgress > 0.35 || isWelcomeRevealed

        return ZStack {
            if showOrb {
                // Soft shadow beneath orb
                Circle()
                    .fill(
                        RadialGradient(
                            gradient: Gradient(colors: [
                                Color.black.opacity(0.08),
                                Color.clear
                            ]),
                            center: .center,
                            startRadius: 0,
                            endRadius: orbSize * 0.7
                        )
                    )
                    .frame(width: orbSize * 1.5, height: orbSize * 0.5)
                    .position(x: orbX, y: orbY + orbSize * 0.48)

                // Glass blur base (material effect)
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: orbSize, height: orbSize)
                    .position(x: orbX, y: orbY)
                    .opacity(0.5)

                // Main glass body — radial gradient for depth
                Circle()
                    .fill(
                        RadialGradient(
                            gradient: Gradient(colors: [
                                Color.white.opacity(0.45),
                                Color.white.opacity(0.20),
                                Color.white.opacity(0.08),
                                Color.white.opacity(0.03)
                            ]),
                            center: .init(x: 0.35, y: 0.28),
                            startRadius: 0,
                            endRadius: orbSize * 0.55
                        )
                    )
                    .frame(width: orbSize, height: orbSize)
                    .position(x: orbX, y: orbY)

                // Glass rim — angular gradient stroke
                Circle()
                    .stroke(
                        AngularGradient(
                            gradient: Gradient(colors: [
                                Color.white.opacity(0.65),
                                Color.white.opacity(0.15),
                                Color.white.opacity(0.04),
                                Color.white.opacity(0.10),
                                Color.white.opacity(0.55),
                                Color.white.opacity(0.65)
                            ]),
                            center: .center,
                            startAngle: .degrees(-50),
                            endAngle: .degrees(310)
                        ),
                        lineWidth: 2.0
                    )
                    .frame(width: orbSize, height: orbSize)
                    .position(x: orbX, y: orbY)

                // Top-left refraction highlight — key glass sphere look
                Circle()
                    .fill(
                        RadialGradient(
                            gradient: Gradient(colors: [
                                Color.white.opacity(0.75),
                                Color.white.opacity(0.25),
                                Color.clear
                            ]),
                            center: .init(x: 0.28, y: 0.22),
                            startRadius: 0,
                            endRadius: orbSize * 0.24
                        )
                    )
                    .frame(width: orbSize * 0.55, height: orbSize * 0.55)
                    .position(x: orbX - orbSize * 0.13, y: orbY - orbSize * 0.13)

                // Secondary smaller highlight (bottom-right)
                Circle()
                    .fill(
                        RadialGradient(
                            gradient: Gradient(colors: [
                                Color.white.opacity(0.20),
                                Color.clear
                            ]),
                            center: .init(x: 0.7, y: 0.7),
                            startRadius: 0,
                            endRadius: orbSize * 0.14
                        )
                    )
                    .frame(width: orbSize * 0.35, height: orbSize * 0.35)
                    .position(x: orbX + orbSize * 0.16, y: orbY + orbSize * 0.16)

                // Shimmer sweep
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.clear,
                                Color.white.opacity(0.20),
                                Color.clear
                            ],
                            startPoint: UnitPoint(x: glowPhase - 0.3, y: 0.3),
                            endPoint: UnitPoint(x: glowPhase + 0.3, y: 0.7)
                        )
                    )
                    .frame(width: orbSize * 0.80, height: orbSize * 0.80)
                    .position(x: orbX, y: orbY)

                // Free-drag gesture area (only active in welcome state)
                if isWelcomeRevealed {
                    Circle()
                        .fill(Color.white.opacity(0.001))
                        .frame(width: orbSize * 1.5, height: orbSize * 1.5)
                        .position(x: orbX, y: orbY)
                        .gesture(orbDragGesture(screenH: screenH))
                }
            }
        }
    }

    // MARK: - Transition Drag Gesture (intro ↔ welcome)

    private func transitionDragGesture(screenH: CGFloat, domeHeight: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 10)
            .onChanged { value in
                guard !isWelcomeRevealed else { return }
                isTransitionDragging = true
                let upDrag = max(0, -value.translation.height)
                transitionProgress = min(1.0, upDrag / dragRange)
            }
            .onEnded { value in
                guard !isWelcomeRevealed else { return }
                isTransitionDragging = false

                let velocity = -value.predictedEndTranslation.height / dragRange
                let effective = transitionProgress + velocity * 0.25

                if effective > 0.35 {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.82)) {
                        transitionProgress = 1.0
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        isWelcomeRevealed = true
                    }
                } else {
                    withAnimation(.spring(response: 0.55, dampingFraction: 0.75)) {
                        transitionProgress = 0
                    }
                }
            }
    }

    // MARK: - Orb Free Drag Gesture (welcome state)

    private func orbDragGesture(screenH: CGFloat) -> some Gesture {
        DragGesture()
            .onChanged { value in
                isOrbDragging = true
                orbOffset = value.translation
            }
            .onEnded { value in
                isOrbDragging = false

                let downThreshold: CGFloat = screenH * 0.30
                let downVelocity = value.predictedEndTranslation.height
                let effectiveDown = value.translation.height + downVelocity * 0.15

                if effectiveDown > downThreshold {
                    // Transition back to intro
                    isWelcomeRevealed = false
                    withAnimation(.spring(response: 0.55, dampingFraction: 0.78)) {
                        orbOffset = .zero
                        transitionProgress = 0
                    }
                } else {
                    // Spring back to center
                    withAnimation(.spring(response: 0.45, dampingFraction: 0.7)) {
                        orbOffset = .zero
                    }
                }
            }
    }

    // MARK: - Entry Animations

    private func startEntryAnimations() {
        guard !appeared else { return }
        appeared = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.easeOut(duration: 0.9)) {
                textOpacity = 1.0
                textOffsetY = 0
            }
        }

        withAnimation(
            .easeInOut(duration: 3.0)
            .repeatForever(autoreverses: true)
        ) {
            glowPhase = 1.0
        }
    }

    // MARK: - Helpers

    private func smoothstep(_ x: CGFloat, edge0: CGFloat, edge1: CGFloat) -> CGFloat {
        let t = max(0, min(1, (x - edge0) / (edge1 - edge0)))
        return t * t * (3 - 2 * t)
    }
}

#Preview {
    LiquidGlassSplashView(
        onGoogleSignIn: { print("Google") },
        onAppleSignIn: { print("Apple") }
    )
}

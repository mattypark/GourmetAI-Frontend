//
//  PaywallFlowView.swift
//  ChefAI
//
//  Coordinator for the 3-screen paywall flow.
//

import SwiftUI

enum PaywallStep {
    case benefits
    case howItWorks
    case planSelector
}

struct PaywallFlowView: View {
    @StateObject private var viewModel = PaywallViewModel()
    @State private var currentStep: PaywallStep = .benefits
    @State private var showingRetentionOffer = false
    @State private var showingWhyCost = false

    var onSubscribed: () -> Void
    var onTrialActivated: () -> Void
    var onDismissed: () -> Void

    var body: some View {
        ZStack {
            Color.theme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                // Top bar: back button + X close button
                HStack {
                    if currentStep != .benefits {
                        Button {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                switch currentStep {
                                case .howItWorks:
                                    currentStep = .benefits
                                case .planSelector:
                                    currentStep = .howItWorks
                                case .benefits:
                                    break
                                }
                            }
                        } label: {
                            Image(systemName: "arrow.left")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(.black)
                                .frame(width: 36, height: 36)
                                .background(Color(white: 0.93))
                                .clipShape(Circle())
                        }
                    }

                    Spacer()

                    Button {
                        showingRetentionOffer = true
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
                .padding(.top, 8)

                // Content
                switch currentStep {
                case .benefits:
                    PaywallBenefitsView()

                case .howItWorks:
                    PaywallTimelineView(selectedPlan: viewModel.selectedPlan)

                case .planSelector:
                    PaywallPlanSelectorView(
                        viewModel: viewModel,
                        showingWhyCost: $showingWhyCost,
                        onSubscribe: {
                            Task {
                                await viewModel.startCheckout()
                            }
                        }
                    )
                }

                // Bottom navigation (benefits + timeline screens)
                if currentStep != .planSelector {
                    HStack(spacing: 12) {
                        if currentStep == .howItWorks {
                            Button {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    currentStep = .benefits
                                }
                            } label: {
                                Image(systemName: "arrow.left")
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundColor(.black)
                                    .frame(width: 56, height: 56)
                                    .background(Color(white: 0.93))
                                    .clipShape(Circle())
                            }
                        }

                        Button {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                switch currentStep {
                                case .benefits:
                                    currentStep = .howItWorks
                                case .howItWorks:
                                    currentStep = .planSelector
                                case .planSelector:
                                    break
                                }
                            }
                        } label: {
                            HStack(spacing: 8) {
                                Text("Next")
                                    .font(.system(size: 17, weight: .semibold))
                                Image(systemName: "arrow.right")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Color.black)
                            .cornerRadius(28)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
                }
            }
        }
        .sheet(isPresented: $showingWhyCost) {
            WhyCostView()
        }
        .fullScreenCover(isPresented: $showingRetentionOffer) {
            RetentionOfferView(
                onAccept: {
                    showingRetentionOffer = false
                    Task {
                        let success = await viewModel.startFreeTrial()
                        if success {
                            onTrialActivated()
                        }
                    }
                },
                onDecline: {
                    showingRetentionOffer = false
                    onDismissed()
                }
            )
        }
        .onChange(of: SubscriptionService.shared.hasAccess) { _, hasAccess in
            if hasAccess {
                viewModel.stopPolling()
                onSubscribed()
            }
        }
    }
}

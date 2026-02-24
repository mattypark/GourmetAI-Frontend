//
//  PaywallPlanSelectorView.swift
//  ChefAI
//
//  Paywall Screen 3: Plan selection + checkout
//

import SwiftUI

struct PaywallPlanSelectorView: View {
    @ObservedObject var viewModel: PaywallViewModel
    @Binding var showingWhyCost: Bool
    var onSubscribe: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Title
                Text("Access all of Gourmet AI")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.black)
                    .padding(.bottom, 20)

                // Feature checkmarks
                VStack(alignment: .leading, spacing: 12) {
                    FeatureCheckRow(text: "Unlimited food searches")
                    FeatureCheckRow(text: "Unlimited recipe generations")
                    FeatureCheckRow(text: "Nutrition tracking")
                    FeatureCheckRow(text: "Smart shopping lists")
                }
                .padding(.bottom, 24)

                // Plan cards
                HStack(spacing: 10) {
                    ForEach(SubscriptionPlan.allCases, id: \.self) { plan in
                        PlanCard(
                            plan: plan,
                            isSelected: viewModel.selectedPlan == plan,
                            onTap: { viewModel.selectedPlan = plan }
                        )
                    }
                }
                .padding(.bottom, 16)

                // Nothing due today
                Text("Nothing due today")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.green)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.bottom, 8)

                // Continue button
                Button(action: onSubscribe) {
                    Group {
                        if viewModel.isLoading {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text("Continue")
                                .font(.system(size: 17, weight: .semibold))
                        }
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Color.black)
                    .cornerRadius(28)
                }
                .disabled(viewModel.isLoading)
                .padding(.bottom, 4)

                // Trial text
                Text(viewModel.selectedPlan.trialText)
                    .font(.system(size: 13))
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.bottom, 20)

                // Why does it cost this much?
                Button {
                    showingWhyCost = true
                } label: {
                    HStack {
                        Text("Why does Gourmet AI cost this much?")
                            .font(.system(size: 15))
                            .foregroundColor(.black)
                        Spacer()
                        Image(systemName: "arrow.right")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                    }
                    .padding(.vertical, 14)
                    .padding(.horizontal, 16)
                    .background(Color(white: 0.96))
                    .cornerRadius(12)
                }
                .padding(.bottom, 16)

                // Promo code section
                VStack(spacing: 8) {
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            viewModel.showPromoInput.toggle()
                            viewModel.promoCodeMessage = nil
                        }
                    } label: {
                        HStack {
                            Text("Have a promo code?")
                                .font(.system(size: 15))
                                .foregroundColor(.black)
                            Spacer()
                            Image(systemName: viewModel.showPromoInput ? "chevron.up" : "chevron.down")
                                .font(.system(size: 14))
                                .foregroundColor(.gray)
                        }
                        .padding(.vertical, 14)
                        .padding(.horizontal, 16)
                        .background(Color(white: 0.96))
                        .cornerRadius(12)
                    }

                    if viewModel.showPromoInput {
                        HStack(spacing: 10) {
                            TextField("Enter code", text: $viewModel.promoCodeText)
                                .font(.system(size: 15))
                                .textInputAutocapitalization(.characters)
                                .autocorrectionDisabled()
                                .padding(.horizontal, 14)
                                .padding(.vertical, 12)
                                .background(Color(white: 0.96))
                                .cornerRadius(10)

                            Button {
                                viewModel.applyPromoCode()
                            } label: {
                                Text("Apply")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 12)
                                    .background(Color.black)
                                    .cornerRadius(10)
                            }
                            .disabled(viewModel.promoCodeText.trimmingCharacters(in: .whitespaces).isEmpty)
                        }

                        if let message = viewModel.promoCodeMessage {
                            Text(message)
                                .font(.system(size: 13))
                                .foregroundColor(viewModel.promoCodeSuccess ? .green : .red)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
                .padding(.bottom, 16)

                // Restore subscription
                Button {
                    Task {
                        await SubscriptionService.shared.refreshStatus()
                    }
                } label: {
                    Text("Restore subscription")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .overlay(
                            RoundedRectangle(cornerRadius: 24)
                                .stroke(Color.black, lineWidth: 1.5)
                        )
                }
                .padding(.bottom, 16)

                // Error message
                if let error = viewModel.errorMessage {
                    Text(error)
                        .font(.system(size: 13))
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.bottom, 8)
                }

                // Privacy + Terms
                HStack(spacing: 4) {
                    Spacer()
                    Button("Privacy Policy") {}
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                    Text("  ·  ")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                    Button("Terms of Service") {}
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                    Spacer()
                }
                .padding(.bottom, 24)
            }
            .padding(.horizontal, 24)
        }
    }
}

// MARK: - Feature Check Row

struct FeatureCheckRow: View {
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 20))
                .foregroundColor(.black)
            Text(text)
                .font(.system(size: 15))
                .foregroundColor(.black)
        }
    }
}

// MARK: - Plan Card

struct PlanCard: View {
    let plan: SubscriptionPlan
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                if let badge = plan.savingsLabel {
                    Text(badge)
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.black)
                        .cornerRadius(4)
                } else {
                    Spacer()
                        .frame(height: 16)
                }

                Text(plan.displayPrice)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.black)

                Text(plan.period)
                    .font(.system(size: 13))
                    .foregroundColor(.gray)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(isSelected ? Color.white : Color(white: 0.97))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.black : Color(white: 0.85), lineWidth: isSelected ? 2 : 1)
            )
        }
    }
}

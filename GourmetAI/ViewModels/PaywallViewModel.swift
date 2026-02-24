//
//  PaywallViewModel.swift
//  ChefAI
//

import Foundation
import UIKit
import Combine
import Auth

@MainActor
class PaywallViewModel: ObservableObject {
    @Published var selectedPlan: SubscriptionPlan = .yearly
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var promoCodeText: String = ""
    @Published var promoCodeMessage: String?
    @Published var promoCodeSuccess: Bool = false
    @Published var showPromoInput: Bool = false

    private var pollingTimer: Timer?
    private var pollingCount = 0

    // MARK: - Checkout

    func startCheckout() async {
        guard let userId = UserDefaults.standard.string(forKey: StorageKeys.currentUserId) else {
            errorMessage = "Please sign in first"
            return
        }

        let email = SupabaseManager.shared.currentUser?.email

        isLoading = true
        errorMessage = nil

        do {
            let checkoutUrl = try await APIClient.shared.createCheckoutSession(
                userId: userId,
                plan: selectedPlan.rawValue,
                email: email
            )

            guard let url = URL(string: checkoutUrl) else {
                errorMessage = "Invalid checkout URL"
                isLoading = false
                return
            }

            await UIApplication.shared.open(url)
            isLoading = false

            // Start polling for subscription activation
            startPolling()
        } catch {
            errorMessage = "Failed to start checkout: \(error.localizedDescription)"
            isLoading = false
        }
    }

    // MARK: - Free Trial

    func startFreeTrial() async -> Bool {
        guard let userId = UserDefaults.standard.string(forKey: StorageKeys.currentUserId) else {
            return false
        }

        isLoading = true
        defer { isLoading = false }

        do {
            let expiresAt = try await APIClient.shared.startFreeTrial(userId: userId)

            // Cache locally for instant access
            UserDefaults.standard.set(expiresAt, forKey: StorageKeys.freeTrialExpiry)
            SubscriptionService.shared.hasAccess = true

            return true
        } catch {
            // Backend unavailable — grant trial locally so users aren't blocked
            let formatter = ISO8601DateFormatter()
            let expiry = Calendar.current.date(byAdding: .day, value: 3, to: Date()) ?? Date().addingTimeInterval(3 * 86400)
            UserDefaults.standard.set(formatter.string(from: expiry), forKey: StorageKeys.freeTrialExpiry)
            SubscriptionService.shared.hasAccess = true
            return true
        }
    }

    // MARK: - Promo Code

    func applyPromoCode() {
        let code = promoCodeText.trimmingCharacters(in: .whitespaces)
        guard !code.isEmpty else {
            promoCodeMessage = "Enter a promo code"
            promoCodeSuccess = false
            return
        }

        let result = SubscriptionService.shared.applyPromoCode(code)
        promoCodeMessage = result.message
        promoCodeSuccess = result.success

        if result.success && SubscriptionService.shared.hasAccess {
            // Promo granted full access — no checkout needed
            promoCodeText = ""
        }
    }

    // MARK: - Polling

    func startPolling() {
        pollingCount = 0
        pollingTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { [weak self] timer in
            Task { @MainActor [weak self] in
                guard let self = self else {
                    timer.invalidate()
                    return
                }

                self.pollingCount += 1
                if self.pollingCount > 20 { // 60 seconds max
                    timer.invalidate()
                    return
                }

                await SubscriptionService.shared.refreshStatus()
                if SubscriptionService.shared.hasAccess {
                    timer.invalidate()
                }
            }
        }
    }

    func stopPolling() {
        pollingTimer?.invalidate()
        pollingTimer = nil
    }

    deinit {
        pollingTimer?.invalidate()
    }
}

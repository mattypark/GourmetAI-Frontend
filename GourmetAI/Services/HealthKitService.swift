//
//  HealthKitService.swift
//  ChefAI
//

import Foundation
import HealthKit
import Combine

@MainActor
final class HealthKitService: ObservableObject {
    static let shared = HealthKitService()

    private let healthStore: HKHealthStore?
    private let userDefaults = UserDefaults.standard

    // MARK: - Published Properties

    @Published var isAvailable: Bool = false
    @Published var isAuthorized: Bool = false
    @Published var latestWeight: Double?
    @Published var latestHeight: Double?
    @Published var todaySteps: Int?
    @Published var todayActiveCalories: Double?
    @Published var todayRestingEnergy: Double?

    // MARK: - Settings (UserDefaults-backed)

    @Published var isEnabled: Bool {
        didSet { userDefaults.set(isEnabled, forKey: StorageKeys.healthKitEnabled) }
    }
    @Published var sendCalories: Bool {
        didSet { userDefaults.set(sendCalories, forKey: StorageKeys.healthKitSendCalories) }
    }
    @Published var sendMacros: Bool {
        didSet { userDefaults.set(sendMacros, forKey: StorageKeys.healthKitSendMacros) }
    }
    @Published var readBurnedCaloriesEnabled: Bool {
        didSet { userDefaults.set(readBurnedCaloriesEnabled, forKey: StorageKeys.healthKitReadBurnedCalories) }
    }
    @Published var readRestingEnergyEnabled: Bool {
        didSet { userDefaults.set(readRestingEnergyEnabled, forKey: StorageKeys.healthKitReadRestingEnergy) }
    }
    @Published var readStepsEnabled: Bool {
        didSet { userDefaults.set(readStepsEnabled, forKey: StorageKeys.healthKitReadSteps) }
    }
    @Published var readWorkoutsEnabled: Bool {
        didSet { userDefaults.set(readWorkoutsEnabled, forKey: StorageKeys.healthKitReadWorkouts) }
    }

    // MARK: - HK Types

    private var readTypes: Set<HKObjectType> {
        var types: Set<HKObjectType> = []
        if let t = HKObjectType.quantityType(forIdentifier: .bodyMass) { types.insert(t) }
        if let t = HKObjectType.quantityType(forIdentifier: .height) { types.insert(t) }
        if let t = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned) { types.insert(t) }
        if let t = HKObjectType.quantityType(forIdentifier: .basalEnergyBurned) { types.insert(t) }
        if let t = HKObjectType.quantityType(forIdentifier: .stepCount) { types.insert(t) }
        if let t = HKObjectType.quantityType(forIdentifier: .dietaryEnergyConsumed) { types.insert(t) }
        if let t = HKObjectType.quantityType(forIdentifier: .dietaryProtein) { types.insert(t) }
        if let t = HKObjectType.quantityType(forIdentifier: .dietaryCarbohydrates) { types.insert(t) }
        if let t = HKObjectType.quantityType(forIdentifier: .dietaryFatTotal) { types.insert(t) }
        if let t = HKObjectType.quantityType(forIdentifier: .dietaryFiber) { types.insert(t) }
        if let t = HKObjectType.quantityType(forIdentifier: .dietarySodium) { types.insert(t) }
        if let t = HKObjectType.quantityType(forIdentifier: .dietarySugar) { types.insert(t) }
        types.insert(HKObjectType.workoutType())
        if let t = HKObjectType.characteristicType(forIdentifier: .biologicalSex) { types.insert(t) }
        if let t = HKObjectType.characteristicType(forIdentifier: .dateOfBirth) { types.insert(t) }
        return types
    }

    private var writeTypes: Set<HKSampleType> {
        var types: Set<HKSampleType> = []
        if let t = HKSampleType.quantityType(forIdentifier: .bodyMass) { types.insert(t) }
        if let t = HKSampleType.quantityType(forIdentifier: .dietaryEnergyConsumed) { types.insert(t) }
        if let t = HKSampleType.quantityType(forIdentifier: .dietaryProtein) { types.insert(t) }
        if let t = HKSampleType.quantityType(forIdentifier: .dietaryCarbohydrates) { types.insert(t) }
        if let t = HKSampleType.quantityType(forIdentifier: .dietaryFatTotal) { types.insert(t) }
        if let t = HKSampleType.quantityType(forIdentifier: .dietaryFiber) { types.insert(t) }
        if let t = HKSampleType.quantityType(forIdentifier: .dietarySodium) { types.insert(t) }
        if let t = HKSampleType.quantityType(forIdentifier: .dietarySugar) { types.insert(t) }
        return types
    }

    // MARK: - Init

    private init() {
        // Load settings from UserDefaults
        isEnabled = userDefaults.bool(forKey: StorageKeys.healthKitEnabled)
        sendCalories = userDefaults.object(forKey: StorageKeys.healthKitSendCalories) as? Bool ?? true
        sendMacros = userDefaults.bool(forKey: StorageKeys.healthKitSendMacros)
        readBurnedCaloriesEnabled = userDefaults.object(forKey: StorageKeys.healthKitReadBurnedCalories) as? Bool ?? true
        readRestingEnergyEnabled = userDefaults.object(forKey: StorageKeys.healthKitReadRestingEnergy) as? Bool ?? true
        readStepsEnabled = userDefaults.object(forKey: StorageKeys.healthKitReadSteps) as? Bool ?? true
        readWorkoutsEnabled = userDefaults.object(forKey: StorageKeys.healthKitReadWorkouts) as? Bool ?? true

        if HKHealthStore.isHealthDataAvailable() {
            healthStore = HKHealthStore()
            isAvailable = true
        } else {
            healthStore = nil
            isAvailable = false
        }
    }

    // MARK: - Authorization

    func requestAuthorization() async -> Bool {
        guard let healthStore = healthStore else { return false }

        do {
            try await healthStore.requestAuthorization(toShare: writeTypes, read: readTypes)
            isAuthorized = true
            isEnabled = true
            return true
        } catch {
            print("HealthKit authorization failed: \(error.localizedDescription)")
            isAuthorized = false
            return false
        }
    }

    // MARK: - Read Methods

    func readWeight(unit: WeightUnit = .lbs) async -> Double? {
        guard let healthStore = healthStore, isEnabled else { return nil }
        guard let type = HKQuantityType.quantityType(forIdentifier: .bodyMass) else { return nil }

        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(sampleType: type, predicate: nil, limit: 1,
                                       sortDescriptors: [sortDescriptor]) { _, samples, _ in
                guard let sample = samples?.first as? HKQuantitySample else {
                    continuation.resume(returning: nil)
                    return
                }
                let hkUnit: HKUnit = unit == .kg ? .gramUnit(with: .kilo) : .pound()
                let value = sample.quantity.doubleValue(for: hkUnit)
                continuation.resume(returning: value)
            }
            healthStore.execute(query)
        }
    }

    func readHeight(unit: HeightUnit = .inches) async -> Double? {
        guard let healthStore = healthStore, isEnabled else { return nil }
        guard let type = HKQuantityType.quantityType(forIdentifier: .height) else { return nil }

        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(sampleType: type, predicate: nil, limit: 1,
                                       sortDescriptors: [sortDescriptor]) { _, samples, _ in
                guard let sample = samples?.first as? HKQuantitySample else {
                    continuation.resume(returning: nil)
                    return
                }
                let hkUnit: HKUnit = unit == .cm ? .meterUnit(with: .centi) : .inch()
                let value = sample.quantity.doubleValue(for: hkUnit)
                continuation.resume(returning: value)
            }
            healthStore.execute(query)
        }
    }

    func readDateOfBirth() -> Date? {
        guard let healthStore = healthStore else { return nil }
        do {
            let components = try healthStore.dateOfBirthComponents()
            return Calendar.current.date(from: components)
        } catch {
            return nil
        }
    }

    func readBiologicalSex() -> Gender? {
        guard let healthStore = healthStore else { return nil }
        do {
            let biologicalSex = try healthStore.biologicalSex().biologicalSex
            switch biologicalSex {
            case .male: return .male
            case .female: return .female
            case .other: return .other
            case .notSet: return nil
            @unknown default: return nil
            }
        } catch {
            return nil
        }
    }

    func readActiveCaloriesBurned(for date: Date) async -> Double? {
        guard readBurnedCaloriesEnabled else { return nil }
        return await readDailySumQuantity(identifier: .activeEnergyBurned, unit: .kilocalorie(), for: date)
    }

    func readRestingEnergyValue(for date: Date) async -> Double? {
        guard readRestingEnergyEnabled else { return nil }
        return await readDailySumQuantity(identifier: .basalEnergyBurned, unit: .kilocalorie(), for: date)
    }

    func readStepCount(for date: Date) async -> Int? {
        guard readStepsEnabled else { return nil }
        guard let value = await readDailySumQuantity(identifier: .stepCount, unit: .count(), for: date) else { return nil }
        return Int(value)
    }

    func readWorkouts(for date: Date) async -> [HKWorkout] {
        guard let healthStore = healthStore, isEnabled, readWorkoutsEnabled else { return [] }

        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else { return [] }
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: endOfDay, options: .strictStartDate)

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(sampleType: .workoutType(), predicate: predicate,
                                       limit: HKObjectQueryNoLimit,
                                       sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]) { _, samples, _ in
                let workouts = (samples as? [HKWorkout]) ?? []
                continuation.resume(returning: workouts)
            }
            healthStore.execute(query)
        }
    }

    // MARK: - Write Methods

    func logMeal(calories: Double, protein: Double? = nil, carbs: Double? = nil,
                 fat: Double? = nil, fiber: Double? = nil, sodium: Double? = nil,
                 sugar: Double? = nil, date: Date = Date()) async throws {
        guard let healthStore = healthStore, isEnabled else { return }

        var samples: [HKQuantitySample] = []

        if sendCalories {
            if let type = HKQuantityType.quantityType(forIdentifier: .dietaryEnergyConsumed) {
                let quantity = HKQuantity(unit: .kilocalorie(), doubleValue: calories)
                samples.append(HKQuantitySample(type: type, quantity: quantity, start: date, end: date))
            }
        }

        if sendMacros {
            if let p = protein, let type = HKQuantityType.quantityType(forIdentifier: .dietaryProtein) {
                samples.append(HKQuantitySample(type: type, quantity: HKQuantity(unit: .gram(), doubleValue: p), start: date, end: date))
            }
            if let c = carbs, let type = HKQuantityType.quantityType(forIdentifier: .dietaryCarbohydrates) {
                samples.append(HKQuantitySample(type: type, quantity: HKQuantity(unit: .gram(), doubleValue: c), start: date, end: date))
            }
            if let f = fat, let type = HKQuantityType.quantityType(forIdentifier: .dietaryFatTotal) {
                samples.append(HKQuantitySample(type: type, quantity: HKQuantity(unit: .gram(), doubleValue: f), start: date, end: date))
            }
            if let fb = fiber, let type = HKQuantityType.quantityType(forIdentifier: .dietaryFiber) {
                samples.append(HKQuantitySample(type: type, quantity: HKQuantity(unit: .gram(), doubleValue: fb), start: date, end: date))
            }
            if let s = sodium, let type = HKQuantityType.quantityType(forIdentifier: .dietarySodium) {
                samples.append(HKQuantitySample(type: type, quantity: HKQuantity(unit: .gram(), doubleValue: s / 1000.0), start: date, end: date))
            }
            if let su = sugar, let type = HKQuantityType.quantityType(forIdentifier: .dietarySugar) {
                samples.append(HKQuantitySample(type: type, quantity: HKQuantity(unit: .gram(), doubleValue: su), start: date, end: date))
            }
        }

        guard !samples.isEmpty else { return }
        try await healthStore.save(samples)
    }

    func writeWeight(_ weight: Double, unit: WeightUnit, date: Date = Date()) async throws {
        guard let healthStore = healthStore, isEnabled else { return }
        guard let type = HKQuantityType.quantityType(forIdentifier: .bodyMass) else { return }

        let hkUnit: HKUnit = unit == .kg ? .gramUnit(with: .kilo) : .pound()
        let quantity = HKQuantity(unit: hkUnit, doubleValue: weight)
        let sample = HKQuantitySample(type: type, quantity: quantity, start: date, end: date)
        try await healthStore.save(sample)
    }

    // MARK: - Refresh Today's Data

    func refreshTodayData() async {
        guard isEnabled else { return }
        let today = Date()

        let profile = StorageService.shared.loadUserProfile()
        let weightUnit = profile.weightUnit ?? .lbs
        let heightUnit = profile.heightUnit ?? .inches

        latestWeight = await readWeight(unit: weightUnit)
        latestHeight = await readHeight(unit: heightUnit)
        todaySteps = await readStepCount(for: today)
        todayActiveCalories = await readActiveCaloriesBurned(for: today)
        todayRestingEnergy = await readRestingEnergyValue(for: today)
    }

    // MARK: - Clear (for sign-out)

    func clearHealthKitSettings() {
        isEnabled = false
        sendCalories = true
        sendMacros = false
        readBurnedCaloriesEnabled = true
        readRestingEnergyEnabled = true
        readStepsEnabled = true
        readWorkoutsEnabled = true
        latestWeight = nil
        latestHeight = nil
        todaySteps = nil
        todayActiveCalories = nil
        todayRestingEnergy = nil
    }

    // MARK: - Helpers

    private func readDailySumQuantity(identifier: HKQuantityTypeIdentifier, unit: HKUnit, for date: Date) async -> Double? {
        guard let healthStore = healthStore, isEnabled else { return nil }
        guard let type = HKQuantityType.quantityType(forIdentifier: identifier) else { return nil }

        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else { return nil }
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: endOfDay, options: .strictStartDate)

        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: predicate,
                                           options: .cumulativeSum) { _, statistics, _ in
                guard let sum = statistics?.sumQuantity() else {
                    continuation.resume(returning: nil)
                    return
                }
                continuation.resume(returning: sum.doubleValue(for: unit))
            }
            healthStore.execute(query)
        }
    }
}

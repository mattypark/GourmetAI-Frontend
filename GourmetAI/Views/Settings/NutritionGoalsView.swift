//
//  NutritionGoalsView.swift
//  ChefAI
//

import SwiftUI

struct NutritionGoalsView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var calorieTarget: Double
    @State private var proteinPercent: Double
    @State private var carbsPercent: Double
    @State private var fatPercent: Double

    private let userDefaults = UserDefaults.standard

    init() {
        let profile = StorageService.shared.loadUserProfile()
        let defaultCals = Double(profile.recommendedCalories ?? 2000)

        _calorieTarget = State(initialValue: UserDefaults.standard.object(forKey: StorageKeys.nutritionGoalCalories) as? Double ?? defaultCals)
        _proteinPercent = State(initialValue: UserDefaults.standard.object(forKey: StorageKeys.nutritionGoalProteinPercent) as? Double ?? 30)
        _carbsPercent = State(initialValue: UserDefaults.standard.object(forKey: StorageKeys.nutritionGoalCarbsPercent) as? Double ?? 40)
        _fatPercent = State(initialValue: UserDefaults.standard.object(forKey: StorageKeys.nutritionGoalFatPercent) as? Double ?? 30)
    }

    // Computed macro grams
    private var proteinGrams: Int { Int(calorieTarget * proteinPercent / 100 / 4) }
    private var carbsGrams: Int { Int(calorieTarget * carbsPercent / 100 / 4) }
    private var fatGrams: Int { Int(calorieTarget * fatPercent / 100 / 9) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Calorie Target
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Daily Calorie Target")
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(.gray)
                            .textCase(.uppercase)
                            .padding(.leading, 4)

                        VStack(spacing: 16) {
                            Text("\(Int(calorieTarget))")
                                .font(.system(size: 48, weight: .bold))
                                .foregroundColor(.black)

                            Text("calories per day")
                                .font(.system(size: 14))
                                .foregroundColor(.gray)

                            Slider(value: $calorieTarget, in: 1000...4000, step: 50)
                                .tint(.black)
                                .padding(.horizontal, 8)

                            HStack {
                                Text("1,000")
                                    .font(.system(size: 12))
                                    .foregroundColor(.gray)
                                Spacer()
                                Text("4,000")
                                    .font(.system(size: 12))
                                    .foregroundColor(.gray)
                            }
                            .padding(.horizontal, 8)
                        }
                        .padding(20)
                        .background(Color.theme.background)
                        .cornerRadius(12)
                    }

                    // Macro Split
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Macro Split")
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(.gray)
                            .textCase(.uppercase)
                            .padding(.leading, 4)

                        VStack(spacing: 20) {
                            macroSlider(
                                name: "Protein",
                                color: .red,
                                percent: $proteinPercent,
                                grams: proteinGrams,
                                unit: "g (4 cal/g)"
                            )

                            Divider()

                            macroSlider(
                                name: "Carbs",
                                color: .blue,
                                percent: $carbsPercent,
                                grams: carbsGrams,
                                unit: "g (4 cal/g)"
                            )

                            Divider()

                            macroSlider(
                                name: "Fat",
                                color: .yellow,
                                percent: $fatPercent,
                                grams: fatGrams,
                                unit: "g (9 cal/g)"
                            )
                        }
                        .padding(20)
                        .background(Color.theme.background)
                        .cornerRadius(12)
                    }

                    // Total percentage indicator
                    let totalPercent = proteinPercent + carbsPercent + fatPercent
                    if abs(totalPercent - 100) > 1 {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                                .font(.system(size: 14))
                            Text("Macro percentages total \(Int(totalPercent))% (should be 100%)")
                                .font(.system(size: 14))
                                .foregroundColor(.orange)
                        }
                        .padding(.horizontal, 4)
                    }
                }
                .padding(16)
            }
            .background(Color(hex: "F2F2F7").ignoresSafeArea())
            .navigationTitle("Nutrition Goals")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        save()
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(.black)
                }
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.gray)
                }
            }
        }
    }

    private func macroSlider(name: String, color: Color, percent: Binding<Double>, grams: Int, unit: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                HStack(spacing: 6) {
                    Circle()
                        .fill(color)
                        .frame(width: 10, height: 10)
                    Text(name)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.black)
                }

                Spacer()

                Text("\(Int(percent.wrappedValue))%")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.black)
                    .frame(width: 44, alignment: .trailing)
            }

            Slider(value: percent, in: 5...70, step: 5)
                .tint(color)

            Text("\(grams)\(unit)")
                .font(.system(size: 13))
                .foregroundColor(.gray)
        }
    }

    private func save() {
        userDefaults.set(calorieTarget, forKey: StorageKeys.nutritionGoalCalories)
        userDefaults.set(proteinPercent, forKey: StorageKeys.nutritionGoalProteinPercent)
        userDefaults.set(carbsPercent, forKey: StorageKeys.nutritionGoalCarbsPercent)
        userDefaults.set(fatPercent, forKey: StorageKeys.nutritionGoalFatPercent)
        dismiss()
    }
}

#Preview {
    NutritionGoalsView()
}

//
//  OnboardingQuestionView.swift
//  ChefAI
//
//  Created by Claude on 2025-01-28.
//

import SwiftUI

struct OnboardingQuestionView: View {
    let question: OnboardingQuestion
    @ObservedObject var viewModel: OnboardingViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Title and subtitle (except for summary page)
            if question.id != 23 {
                VStack(alignment: .leading, spacing: 8) {
                    Text(question.title)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                        .fixedSize(horizontal: false, vertical: true)

                    if let subtitle = question.subtitle {
                        Text(subtitle)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                }

                Spacer()
                    .frame(height: 24)
            }

            // Question content based on type
            questionContent

            if question.id != 23 {
                Spacer()
            }
        }
        .padding(.horizontal, 24)
    }

    @ViewBuilder
    private var questionContent: some View {
        switch question.id {
        case 0:
            // Name input
            NameInputView(name: $viewModel.userName)

        case 1:
            // Gender selection
            ScrollView {
                GenderSelectionView(selectedGender: $viewModel.selectedGender)
            }

        case 2:
            // Birthday picker
            AgePickerView(birthDate: $viewModel.birthDate)

        case 3:
            // Weight and Height picker
            WeightHeightPickerView(
                weight: $viewModel.userWeight,
                height: $viewModel.userHeight,
                weightUnit: $viewModel.weightUnit,
                heightUnit: $viewModel.heightUnit,
                useMetricSystem: $viewModel.useMetricSystem
            )

        case 4:
            // Physique goal
            ScrollView {
                MultipleChoiceSelector(
                    items: PhysiqueGoal.allCases,
                    selected: $viewModel.selectedPhysiqueGoal,
                    iconProvider: { $0.icon }
                )
            }

        case 5:
            // Organic vs Processed
            OrganicProcessedView(selection: $viewModel.eatsOrganic)

        case 6:
            // Processed food impact
            ScrollView {
                TagPicker(
                    items: ProcessedFoodImpact.allCases,
                    selectedItems: $viewModel.selectedProcessedImpacts,
                    iconProvider: { $0.icon }
                )
            }

        case 7:
            // Have you tried changing diet?
            YesNoSelectionView(selection: $viewModel.hasTriedDietChange)

        case 8:
            // Diet barriers
            ScrollView {
                TagPicker(
                    items: DietBarrier.allCases,
                    selectedItems: $viewModel.selectedDietBarriers,
                    iconProvider: { $0.icon }
                )
            }

        case 9:
            // Organic goals
            ScrollView {
                TagPicker(
                    items: OrganicGoal.allCases,
                    selectedItems: $viewModel.selectedOrganicGoals,
                    iconProvider: { $0.icon }
                )
            }

        case 10:
            // Aspirational goals
            ScrollView {
                TagPicker(
                    items: AspirationalGoal.allCases,
                    selectedItems: $viewModel.selectedAspirationalGoals,
                    iconProvider: { $0.icon }
                )
            }

        case 11:
            // Main goal
            ScrollView {
                MultipleChoiceSelector(
                    items: MainGoal.allCases,
                    selected: $viewModel.selectedMainGoal,
                    iconProvider: { $0.icon }
                )
            }

        case 12:
            // Cooking motivation
            ScrollView {
                TagPicker(
                    items: CookingMotivation.allCases,
                    selectedItems: $viewModel.selectedMotivations,
                    iconProvider: { $0.icon }
                )
            }

        case 13:
            // Days per week
            DaysPerWeekPicker(days: $viewModel.cookingDaysPerWeek)

        case 14:
            // Skill level
            ScrollView {
                MultipleChoiceSelector(
                    items: SkillLevel.allCases,
                    selected: $viewModel.selectedSkillLevel,
                    iconProvider: { $0.icon }
                )
            }

        case 15:
            // Cooking time of day
            ScrollView {
                TagPicker(
                    items: CookingTimeOfDay.allCases,
                    selectedItems: $viewModel.selectedCookingTimes,
                    iconProvider: { $0.icon }
                )
            }

        case 16:
            // Dietary restrictions
            ScrollView {
                TagPicker(
                    items: ExtendedDietaryRestriction.allCases,
                    selectedItems: $viewModel.selectedRestrictions,
                    iconProvider: { $0.icon }
                )
            }

        case 17:
            // Meal preferences
            ScrollView {
                TagPicker(
                    items: MealPreference.allCases,
                    selectedItems: $viewModel.selectedMealPreferences,
                    iconProvider: { $0.icon }
                )
            }

        case 18:
            // Time availability
            ScrollView {
                MultipleChoiceSelector(
                    items: TimeAvailability.allCases,
                    selected: $viewModel.selectedTimeAvailability,
                    iconProvider: { $0.icon }
                )
            }

        case 19:
            // Cooking equipment
            ScrollView {
                TagPicker(
                    items: CookingEquipment.allCases,
                    selectedItems: $viewModel.selectedEquipment,
                    iconProvider: { $0.icon }
                )
            }

        case 20:
            // Cooking struggles
            ScrollView {
                TagPicker(
                    items: CookingStruggle.allCases,
                    selectedItems: $viewModel.selectedStruggles,
                    iconProvider: { $0.icon }
                )
            }

        case 21:
            // Adventure level
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(AdventureLevel.allCases, id: \.self) { level in
                        AdventureLevelCard(
                            level: level,
                            isSelected: viewModel.selectedAdventureLevel == level,
                            onTap: {
                                viewModel.selectedAdventureLevel = level
                            }
                        )
                    }
                }
            }

        case 22:
            // Acquisition source
            ScrollView {
                MultipleChoiceSelector(
                    items: AcquisitionSource.allCases,
                    selected: $viewModel.selectedAcquisitionSource,
                    iconProvider: { $0.icon }
                )
            }

        case 23:
            // Summary
            OnboardingSummaryView(viewModel: viewModel)

        default:
            EmptyView()
        }
    }
}

// MARK: - Name Input View

struct NameInputView: View {
    @Binding var name: String
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            TextField("Your name", text: $name)
                .font(.system(size: 24, weight: .medium))
                .foregroundColor(.black)
                .focused($isFocused)
                .textContentType(.name)
                .autocapitalization(.words)
                .padding(.vertical, 16)
                .padding(.horizontal, 20)
                .background(Color.black.opacity(0.05))
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(isFocused ? Color.black : Color.clear, lineWidth: 2)
                )

            Text("This is how we'll address you in the app")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isFocused = true
            }
        }
    }
}

// MARK: - Gender Selection View

struct GenderSelectionView: View {
    @Binding var selectedGender: Gender?

    var body: some View {
        VStack(spacing: 12) {
            ForEach(Gender.allCases, id: \.self) { gender in
                Button(action: { selectedGender = gender }) {
                    HStack(spacing: 16) {
                        Image(systemName: gender.icon)
                            .font(.title2)
                            .foregroundColor(selectedGender == gender ? .white : .black)
                            .frame(width: 44, height: 44)
                            .background(selectedGender == gender ? Color.black : Color.black.opacity(0.05))
                            .cornerRadius(12)

                        Text(gender.rawValue)
                            .font(.headline)
                            .foregroundColor(.black)

                        Spacer()

                        if selectedGender == gender {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                                .font(.title2)
                        }
                    }
                    .padding()
                    .background(selectedGender == gender ? Color.black.opacity(0.05) : Color.black.opacity(0.02))
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(selectedGender == gender ? Color.black.opacity(0.2) : Color.black.opacity(0.1), lineWidth: 1)
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
}

// MARK: - Physical Stats View

struct PhysicalStatsView: View {
    @Binding var age: Int
    @Binding var weight: Double
    @Binding var height: Double
    @Binding var weightUnit: WeightUnit
    @Binding var heightUnit: HeightUnit

    var body: some View {
        VStack(spacing: 32) {
            // Age picker
            VStack(alignment: .leading, spacing: 12) {
                Text("Age")
                    .font(.headline)
                    .foregroundColor(.black)

                HStack {
                    Picker("Age", selection: $age) {
                        ForEach(13...100, id: \.self) { year in
                            Text("\(year)").tag(year)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(height: 120)

                    Text("years")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
            }

            // Weight picker
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Weight")
                        .font(.headline)
                        .foregroundColor(.black)

                    Spacer()

                    // Unit toggle
                    Picker("Unit", selection: $weightUnit) {
                        Text("lbs").tag(WeightUnit.lbs)
                        Text("kg").tag(WeightUnit.kg)
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 100)
                    .onChange(of: weightUnit) { _, newValue in
                        // Convert weight when unit changes
                        if newValue == .kg {
                            weight = weight * 0.453592
                        } else {
                            weight = weight / 0.453592
                        }
                    }
                }

                HStack {
                    Picker("Weight", selection: Binding(
                        get: { Int(weight) },
                        set: { weight = Double($0) }
                    )) {
                        ForEach(weightUnit == .lbs ? 80...400 : 36...181, id: \.self) { w in
                            Text("\(w)").tag(w)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(height: 120)

                    Text(weightUnit.rawValue)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
            }

            // Height picker
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Height")
                        .font(.headline)
                        .foregroundColor(.black)

                    Spacer()

                    // Unit toggle
                    Picker("Unit", selection: $heightUnit) {
                        Text("ft/in").tag(HeightUnit.inches)
                        Text("cm").tag(HeightUnit.cm)
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 100)
                    .onChange(of: heightUnit) { _, newValue in
                        // Convert height when unit changes
                        if newValue == .cm {
                            height = height * 2.54
                        } else {
                            height = height / 2.54
                        }
                    }
                }

                if heightUnit == .inches {
                    // Feet and inches pickers
                    HStack {
                        Picker("Feet", selection: Binding(
                            get: { Int(height) / 12 },
                            set: { height = Double($0 * 12 + Int(height) % 12) }
                        )) {
                            ForEach(4...7, id: \.self) { ft in
                                Text("\(ft) ft").tag(ft)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(height: 120)

                        Picker("Inches", selection: Binding(
                            get: { Int(height) % 12 },
                            set: { height = Double((Int(height) / 12) * 12 + $0) }
                        )) {
                            ForEach(0...11, id: \.self) { inch in
                                Text("\(inch) in").tag(inch)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(height: 120)
                    }
                } else {
                    HStack {
                        Picker("Height", selection: Binding(
                            get: { Int(height) },
                            set: { height = Double($0) }
                        )) {
                            ForEach(120...220, id: \.self) { cm in
                                Text("\(cm)").tag(cm)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(height: 120)

                        Text("cm")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                }
            }
        }
    }
}

// MARK: - Organic/Processed Selection View

struct OrganicProcessedView: View {
    @Binding var selection: Bool?

    var body: some View {
        VStack(spacing: 16) {
            SelectionButton(
                title: "Mostly organic",
                subtitle: "Whole foods, fresh ingredients",
                icon: "leaf.fill",
                isSelected: selection == true,
                onTap: { selection = true }
            )

            SelectionButton(
                title: "Mix of both",
                subtitle: "A balance of organic and processed",
                icon: "arrow.left.arrow.right",
                isSelected: selection == nil,
                onTap: { selection = nil }
            )

            SelectionButton(
                title: "Mostly processed",
                subtitle: "Packaged and convenience foods",
                icon: "bag.fill",
                isSelected: selection == false,
                onTap: { selection = false }
            )

            Text("No judgment here! We just want to help you eat better.")
                .font(.caption)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.top, 8)
        }
    }
}

struct SelectionButton: View {
    let title: String
    let subtitle: String
    let icon: String
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(isSelected ? .white : .black)
                    .frame(width: 44, height: 44)
                    .background(isSelected ? Color.black : Color.black.opacity(0.05))
                    .cornerRadius(12)

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.black)

                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.gray)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.title2)
                }
            }
            .padding()
            .background(isSelected ? Color.black.opacity(0.05) : Color.black.opacity(0.02))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.black.opacity(0.2) : Color.black.opacity(0.1), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Yes/No Selection View

struct YesNoSelectionView: View {
    @Binding var selection: Bool?

    var body: some View {
        VStack(spacing: 16) {
            Button(action: { selection = true }) {
                HStack {
                    Text("Yes")
                        .font(.headline)
                        .foregroundColor(.black)

                    Spacer()

                    if selection == true {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.title2)
                    }
                }
                .padding()
                .background(selection == true ? Color.black.opacity(0.05) : Color.black.opacity(0.02))
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(selection == true ? Color.black.opacity(0.2) : Color.black.opacity(0.1), lineWidth: 1)
                )
            }
            .buttonStyle(PlainButtonStyle())

            Button(action: { selection = false }) {
                HStack {
                    Text("No")
                        .font(.headline)
                        .foregroundColor(.black)

                    Spacer()

                    if selection == false {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.title2)
                    }
                }
                .padding()
                .background(selection == false ? Color.black.opacity(0.05) : Color.black.opacity(0.02))
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(selection == false ? Color.black.opacity(0.2) : Color.black.opacity(0.1), lineWidth: 1)
                )
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
}

// MARK: - Days Per Week Picker

struct DaysPerWeekPicker: View {
    @Binding var days: Int

    var body: some View {
        VStack(spacing: 24) {
            // Large number display
            Text("\(days)")
                .font(.system(size: 72, weight: .bold))
                .foregroundColor(.black)

            Text(days == 1 ? "day per week" : "days per week")
                .font(.title3)
                .foregroundColor(.gray)

            // Slider
            Slider(value: Binding(
                get: { Double(days) },
                set: { days = Int($0) }
            ), in: 0...7, step: 1)
            .accentColor(.black)
            .padding(.horizontal)

            // Day labels
            HStack {
                ForEach(0...7, id: \.self) { day in
                    Text("\(day)")
                        .font(.caption)
                        .foregroundColor(days == day ? .black : .gray)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 32)
    }
}

// MARK: - Adventure Level Card

struct AdventureLevelCard: View {
    let level: AdventureLevel
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                Image(systemName: level.icon)
                    .font(.title2)
                    .foregroundColor(isSelected ? .white : .black)
                    .frame(width: 44, height: 44)
                    .background(isSelected ? Color.black : Color.black.opacity(0.05))
                    .cornerRadius(12)

                VStack(alignment: .leading, spacing: 4) {
                    Text(level.rawValue)
                        .font(.headline)
                        .foregroundColor(.black)

                    Text(level.description)
                        .font(.caption)
                        .foregroundColor(.gray)
                        .lineLimit(2)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.title2)
                }
            }
            .padding()
            .background(isSelected ? Color.black.opacity(0.05) : Color.black.opacity(0.02))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.black.opacity(0.2) : Color.black.opacity(0.1), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Birthday Picker View (Date style)

struct AgePickerView: View {
    @Binding var birthDate: Date

    @State private var selectedMonth: Int = 1
    @State private var selectedDay: Int = 1
    @State private var selectedYear: Int = 2000

    private let months = ["January", "February", "March", "April", "May", "June",
                          "July", "August", "September", "October", "November", "December"]

    var body: some View {
        VStack(spacing: 24) {
            // Three-column date picker
            HStack(spacing: 0) {
                // Month picker
                Picker("Month", selection: $selectedMonth) {
                    ForEach(1...12, id: \.self) { month in
                        Text(months[month - 1])
                            .tag(month)
                    }
                }
                .pickerStyle(.wheel)
                .frame(maxWidth: .infinity)
                .clipped()

                // Day picker
                Picker("Day", selection: $selectedDay) {
                    ForEach(1...31, id: \.self) { day in
                        Text("\(day)")
                            .tag(day)
                    }
                }
                .pickerStyle(.wheel)
                .frame(width: 60)
                .clipped()

                // Year picker
                Picker("Year", selection: $selectedYear) {
                    ForEach((1920...2015).reversed(), id: \.self) { year in
                        Text("\(year)")
                            .tag(year)
                    }
                }
                .pickerStyle(.wheel)
                .frame(width: 80)
                .clipped()
            }
            .frame(height: 200)
        }
        .onAppear {
            let calendar = Calendar.current
            selectedMonth = calendar.component(.month, from: birthDate)
            selectedDay = calendar.component(.day, from: birthDate)
            selectedYear = calendar.component(.year, from: birthDate)
        }
        .onChange(of: selectedMonth) { _, _ in updateBirthDate() }
        .onChange(of: selectedDay) { _, _ in updateBirthDate() }
        .onChange(of: selectedYear) { _, _ in updateBirthDate() }
    }

    private func updateBirthDate() {
        var components = DateComponents()
        components.year = selectedYear
        components.month = selectedMonth
        components.day = min(selectedDay, daysInMonth(month: selectedMonth, year: selectedYear))
        if let date = Calendar.current.date(from: components) {
            birthDate = date
        }
    }

    private func daysInMonth(month: Int, year: Int) -> Int {
        var components = DateComponents()
        components.year = year
        components.month = month + 1
        components.day = 0
        return Calendar.current.date(from: components)?.dayOfMonth ?? 31
    }
}

private extension Date {
    var dayOfMonth: Int {
        Calendar.current.component(.day, from: self)
    }
}

// MARK: - Height & Weight Picker View (Imperial/Metric toggle)

struct WeightHeightPickerView: View {
    @Binding var weight: Double
    @Binding var height: Double
    @Binding var weightUnit: WeightUnit
    @Binding var heightUnit: HeightUnit
    @Binding var useMetricSystem: Bool

    // Local state for picker values
    @State private var heightFeet: Int = 5
    @State private var heightInches: Int = 8
    @State private var heightCm: Int = 170
    @State private var weightLbs: Int = 155
    @State private var weightKg: Int = 70

    var body: some View {
        VStack(spacing: 32) {
            // Imperial / Metric Toggle
            HStack(spacing: 16) {
                Text("Imperial")
                    .font(.system(size: 16, weight: useMetricSystem ? .regular : .semibold))
                    .foregroundColor(useMetricSystem ? .gray : .black)

                Toggle("", isOn: $useMetricSystem)
                    .labelsHidden()
                    .tint(.gray)
                    .onChange(of: useMetricSystem) { _, isMetric in
                        if isMetric {
                            weightUnit = .kg
                            heightUnit = .cm
                            // Convert values
                            weightKg = Int(Double(weightLbs) * 0.453592)
                            heightCm = Int(Double(heightFeet * 12 + heightInches) * 2.54)
                        } else {
                            weightUnit = .lbs
                            heightUnit = .inches
                            // Convert values
                            weightLbs = Int(Double(weightKg) / 0.453592)
                            let totalInches = Int(Double(heightCm) / 2.54)
                            heightFeet = totalInches / 12
                            heightInches = totalInches % 12
                        }
                        updateValues()
                    }

                Text("Metric")
                    .font(.system(size: 16, weight: useMetricSystem ? .semibold : .regular))
                    .foregroundColor(useMetricSystem ? .black : .gray)
            }

            // Height and Weight labels
            HStack {
                Text("Height")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text("Weight")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 20)
            }

            // Pickers
            HStack(spacing: 0) {
                if useMetricSystem {
                    // Metric: Height in cm
                    Picker("Height", selection: $heightCm) {
                        ForEach(100...250, id: \.self) { cm in
                            Text("\(cm) cm")
                                .tag(cm)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(maxWidth: .infinity)
                    .clipped()
                    .onChange(of: heightCm) { _, _ in updateValues() }

                    // Weight in kg
                    Picker("Weight", selection: $weightKg) {
                        ForEach(30...200, id: \.self) { kg in
                            Text("\(kg) kg")
                                .tag(kg)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(maxWidth: .infinity)
                    .clipped()
                    .onChange(of: weightKg) { _, _ in updateValues() }
                } else {
                    // Imperial: Height in ft/in
                    Picker("Feet", selection: $heightFeet) {
                        ForEach(3...8, id: \.self) { ft in
                            Text("\(ft) ft")
                                .tag(ft)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(width: 70)
                    .clipped()
                    .onChange(of: heightFeet) { _, _ in updateValues() }

                    Picker("Inches", selection: $heightInches) {
                        ForEach(0...11, id: \.self) { inch in
                            Text("\(inch) in")
                                .tag(inch)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(width: 70)
                    .clipped()
                    .onChange(of: heightInches) { _, _ in updateValues() }

                    // Weight in lbs
                    Picker("Weight", selection: $weightLbs) {
                        ForEach(80...400, id: \.self) { lb in
                            Text("\(lb) lb")
                                .tag(lb)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(maxWidth: .infinity)
                    .clipped()
                    .onChange(of: weightLbs) { _, _ in updateValues() }
                }
            }
            .frame(height: 200)
        }
        .onAppear {
            // Initialize local state from bindings
            if heightUnit == .cm {
                useMetricSystem = true
                heightCm = Int(height)
                weightKg = Int(weight)
            } else {
                useMetricSystem = false
                heightFeet = Int(height) / 12
                heightInches = Int(height) % 12
                weightLbs = Int(weight)
            }
        }
    }

    private func updateValues() {
        if useMetricSystem {
            height = Double(heightCm)
            weight = Double(weightKg)
        } else {
            height = Double(heightFeet * 12 + heightInches)
            weight = Double(weightLbs)
        }
    }
}

#Preview {
    @Previewable @StateObject var viewModel = OnboardingViewModel()

    ZStack {
        Color.white.ignoresSafeArea()
        OnboardingQuestionView(
            question: viewModel.questions[0],
            viewModel: viewModel
        )
    }
}

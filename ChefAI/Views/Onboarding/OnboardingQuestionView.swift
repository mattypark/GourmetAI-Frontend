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
        // Pages with their own centered layout (name=0, gender=1, birthday=2, height=3, weight=4)
        if question.id == 0 {
            NameInputView(name: $viewModel.userName)
        } else if question.id == 1 {
            GenderSelectionView(selectedGender: $viewModel.selectedGender)
        } else if question.id == 2 {
            AgePickerView(birthDate: $viewModel.birthDate)
        } else if question.id == 3 {
            HeightPickerView(
                height: $viewModel.userHeight,
                heightUnit: $viewModel.heightUnit,
                useMetricSystem: $viewModel.useMetricSystem
            )
        } else if question.id == 4 {
            CurrentWeightPickerView(
                weight: $viewModel.userWeight,
                weightUnit: $viewModel.weightUnit,
                useMetricSystem: $viewModel.useMetricSystem
            )
        } else {
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
            // Height picker (new style)
            HeightPickerView(
                height: $viewModel.userHeight,
                heightUnit: $viewModel.heightUnit,
                useMetricSystem: $viewModel.useMetricSystem
            )

        case 4:
            // Weight picker (new style with current, goal, target date)
            WeightGoalPickerView(
                currentWeight: $viewModel.userWeight,
                goalWeight: $viewModel.goalWeight,
                targetDate: $viewModel.targetDate,
                weightUnit: $viewModel.weightUnit,
                useMetricSystem: $viewModel.useMetricSystem
            )

        case 5:
            // Activity level
            ActivityLevelPickerView(selectedLevel: $viewModel.selectedActivityLevel)

        case 6:
            // Calorie bias slider
            CalorieBiasPickerView(selectedBias: $viewModel.selectedCalorieBias)

        case 7:
            // Physique goal
            ScrollView {
                MultipleChoiceSelector(
                    items: PhysiqueGoal.allCases,
                    selected: $viewModel.selectedPhysiqueGoal,
                    iconProvider: { $0.icon }
                )
            }

        case 8:
            // Organic vs Processed
            OrganicProcessedView(selection: $viewModel.foodPreference)

        case 9:
            // Processed food impact
            ScrollView {
                TagPicker(
                    items: ProcessedFoodImpact.allCases,
                    selectedItems: $viewModel.selectedProcessedImpacts,
                    iconProvider: { $0.icon }
                )
            }

        case 10:
            // Have you tried changing diet?
            YesNoSelectionView(selection: $viewModel.hasTriedDietChange)

        case 11:
            // Diet barriers
            ScrollView {
                TagPicker(
                    items: DietBarrier.allCases,
                    selectedItems: $viewModel.selectedDietBarriers,
                    iconProvider: { $0.icon }
                )
            }

        case 12:
            // Organic goals
            ScrollView {
                TagPicker(
                    items: OrganicGoal.allCases,
                    selectedItems: $viewModel.selectedOrganicGoals,
                    iconProvider: { $0.icon }
                )
            }

        case 13:
            // Aspirational goals
            ScrollView {
                TagPicker(
                    items: AspirationalGoal.allCases,
                    selectedItems: $viewModel.selectedAspirationalGoals,
                    iconProvider: { $0.icon }
                )
            }

        case 14:
            // Main goal
            ScrollView {
                MultipleChoiceSelector(
                    items: MainGoal.allCases,
                    selected: $viewModel.selectedMainGoal,
                    iconProvider: { $0.icon }
                )
            }

        case 15:
            // Cooking motivation
            ScrollView {
                TagPicker(
                    items: CookingMotivation.allCases,
                    selectedItems: $viewModel.selectedMotivations,
                    iconProvider: { $0.icon }
                )
            }

        case 16:
            // Days per week
            DaysPerWeekPicker(days: $viewModel.cookingDaysPerWeek)

        case 17:
            // Skill level
            ScrollView {
                MultipleChoiceSelector(
                    items: SkillLevel.allCases,
                    selected: $viewModel.selectedSkillLevel,
                    iconProvider: { $0.icon }
                )
            }

        case 18:
            // Cooking time of day
            ScrollView {
                TagPicker(
                    items: CookingTimeOfDay.allCases,
                    selectedItems: $viewModel.selectedCookingTimes,
                    iconProvider: { $0.icon }
                )
            }

        case 19:
            // Dietary restrictions
            ScrollView {
                TagPicker(
                    items: ExtendedDietaryRestriction.allCases,
                    selectedItems: $viewModel.selectedRestrictions,
                    iconProvider: { $0.icon }
                )
            }

        case 20:
            // Meal preferences
            ScrollView {
                TagPicker(
                    items: MealPreference.allCases,
                    selectedItems: $viewModel.selectedMealPreferences,
                    iconProvider: { $0.icon }
                )
            }

        case 21:
            // Time availability
            ScrollView {
                MultipleChoiceSelector(
                    items: TimeAvailability.allCases,
                    selected: $viewModel.selectedTimeAvailability,
                    iconProvider: { $0.icon }
                )
            }

        case 22:
            // Cooking equipment
            ScrollView {
                TagPicker(
                    items: CookingEquipment.allCases,
                    selectedItems: $viewModel.selectedEquipment,
                    iconProvider: { $0.icon }
                )
            }

        case 23:
            // Cooking struggles
            ScrollView {
                TagPicker(
                    items: CookingStruggle.allCases,
                    selectedItems: $viewModel.selectedStruggles,
                    iconProvider: { $0.icon }
                )
            }

        case 24:
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

        case 25:
            // Acquisition source
            ScrollView {
                MultipleChoiceSelector(
                    items: AcquisitionSource.allCases,
                    selected: $viewModel.selectedAcquisitionSource,
                    iconProvider: { $0.icon }
                )
            }

        case 26:
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
        VStack(spacing: 0) {
            Spacer()

            // Centered content
            VStack(spacing: 12) {
                // Title
                Text("What's your name?")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.black)

                // Subtitle
                Text("We'll use this to personalize your experience")
                    .font(.system(size: 15))
                    .foregroundColor(.gray)

                // Text field
                TextField("Your name", text: $name)
                    .font(.system(size: 17))
                    .foregroundColor(.black)
                    .multilineTextAlignment(.center)
                    .focused($isFocused)
                    .textContentType(.name)
                    .autocapitalization(.words)
                    .padding(.vertical, 16)
                    .padding(.horizontal, 24)
                    .background(Color(white: 0.93))
                    .cornerRadius(30)
                    .padding(.top, 20)
            }
            .padding(.horizontal, 24)

            Spacer()
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
        VStack(spacing: 0) {
            Spacer()

            // Centered content
            VStack(alignment: .leading, spacing: 12) {
                // Title
                Text("What's your gender?")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.black)

                // Subtitle
                Text("This helps us calculate accurate calorie and macro goals")
                    .font(.system(size: 15))
                    .foregroundColor(.gray)
                    .padding(.bottom, 20)

                // Gender options
                VStack(spacing: 16) {
                    ForEach(Gender.allCases, id: \.self) { gender in
                        GenderOptionButton(
                            gender: gender,
                            isSelected: selectedGender == gender,
                            onTap: { selectedGender = gender }
                        )
                    }
                }
            }
            .padding(.horizontal, 24)

            Spacer()
        }
    }
}

struct GenderOptionButton: View {
    let gender: Gender
    let isSelected: Bool
    let onTap: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Icon on left
                Image(systemName: gender.icon)
                    .font(.system(size: 20))
                    .foregroundColor(isSelected ? .black : .black.opacity(0.6))
                    .frame(width: 24)

                // Gender text
                Text(gender.rawValue)
                    .font(.system(size: 17))
                    .foregroundColor(.black)

                Spacer()

                // Checkmark on right when selected
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(.black)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 18)
            .background(Color(white: 0.96))
            .cornerRadius(30)
            .overlay(
                RoundedRectangle(cornerRadius: 30)
                    .stroke(isSelected ? Color.black : Color.clear, lineWidth: 2)
            )
            .scaleEffect(isPressed ? 0.98 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0, pressing: { pressing in
            withAnimation(.easeInOut(duration: 0.15)) {
                isPressed = pressing
            }
        }, perform: {})
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
    @Binding var selection: FoodPreference?

    var body: some View {
        VStack(spacing: 16) {
            SelectionButton(
                title: "Mostly organic",
                subtitle: "Whole foods, fresh ingredients",
                icon: "leaf.fill",
                isSelected: selection == .organic,
                onTap: { selection = .organic }
            )

            SelectionButton(
                title: "Mix of both",
                subtitle: "A balance of organic and processed",
                icon: "arrow.left.arrow.right",
                isSelected: selection == .mixed,
                onTap: { selection = .mixed }
            )

            SelectionButton(
                title: "Mostly processed",
                subtitle: "Packaged and convenience foods",
                icon: "bag.fill",
                isSelected: selection == .processed,
                onTap: { selection = .processed }
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

    @State private var isPressed = false

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
                        .foregroundColor(.black)
                        .font(.title2)
                }
            }
            .padding()
            .background(isSelected ? Color.black.opacity(0.05) : Color.black.opacity(0.02))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.black : Color.black.opacity(0.1), lineWidth: isSelected ? 2 : 1)
            )
            .scaleEffect(isPressed ? 0.98 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0, pressing: { pressing in
            withAnimation(.easeInOut(duration: 0.15)) {
                isPressed = pressing
            }
        }, perform: {})
    }
}

// MARK: - Yes/No Selection View

struct YesNoSelectionView: View {
    @Binding var selection: Bool?

    @State private var yesPressed = false
    @State private var noPressed = false

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
                            .foregroundColor(.black)
                            .font(.title2)
                    }
                }
                .padding()
                .background(selection == true ? Color.black.opacity(0.05) : Color.black.opacity(0.02))
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(selection == true ? Color.black : Color.black.opacity(0.1), lineWidth: selection == true ? 2 : 1)
                )
                .scaleEffect(yesPressed ? 0.98 : 1.0)
            }
            .buttonStyle(PlainButtonStyle())
            .onLongPressGesture(minimumDuration: 0, pressing: { pressing in
                withAnimation(.easeInOut(duration: 0.15)) {
                    yesPressed = pressing
                }
            }, perform: {})

            Button(action: { selection = false }) {
                HStack {
                    Text("No")
                        .font(.headline)
                        .foregroundColor(.black)

                    Spacer()

                    if selection == false {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.black)
                            .font(.title2)
                    }
                }
                .padding()
                .background(selection == false ? Color.black.opacity(0.05) : Color.black.opacity(0.02))
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(selection == false ? Color.black : Color.black.opacity(0.1), lineWidth: selection == false ? 2 : 1)
                )
                .scaleEffect(noPressed ? 0.98 : 1.0)
            }
            .buttonStyle(PlainButtonStyle())
            .onLongPressGesture(minimumDuration: 0, pressing: { pressing in
                withAnimation(.easeInOut(duration: 0.15)) {
                    noPressed = pressing
                }
            }, perform: {})
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

    @State private var isPressed = false

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
                        .foregroundColor(.black)
                        .font(.title2)
                }
            }
            .padding()
            .background(isSelected ? Color.black.opacity(0.05) : Color.black.opacity(0.02))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.black : Color.black.opacity(0.1), lineWidth: isSelected ? 2 : 1)
            )
            .scaleEffect(isPressed ? 0.98 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0, pressing: { pressing in
            withAnimation(.easeInOut(duration: 0.15)) {
                isPressed = pressing
            }
        }, perform: {})
    }
}

// MARK: - Birthday Picker View (Date style)

struct AgePickerView: View {
    @Binding var birthDate: Date

    @State private var showingPicker = false
    @State private var selectedMonth: Int = 10
    @State private var selectedDay: Int = 2
    @State private var selectedYear: Int = 2000

    private let months = ["January", "February", "March", "April", "May", "June",
                          "July", "August", "September", "October", "November", "December"]

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: birthDate)
    }

    private var ageString: String {
        let calendar = Calendar.current
        let ageComponents = calendar.dateComponents([.year], from: birthDate, to: Date())
        let age = ageComponents.year ?? 0
        return "\(age) years old"
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Centered content
            VStack(alignment: .leading, spacing: 12) {
                // Title
                Text("When's your birthday?")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.black)

                // Subtitle
                Text("We'll only use this to calculate your age for health metrics and goals. Your birthday data is kept private and secure")
                    .font(.system(size: 15))
                    .foregroundColor(.gray)
                    .padding(.bottom, 20)

                // Birthday label
                Text("Birthday")
                    .font(.system(size: 15))
                    .foregroundColor(.black)

                // Date display box (tappable)
                Button(action: { showingPicker = true }) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(formattedDate)
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.black)

                        Text(ageString)
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    .background(Color(white: 0.93))
                    .cornerRadius(16)
                }
                .buttonStyle(PlainButtonStyle())

                // Privacy note
                HStack(spacing: 8) {
                    Image(systemName: "lock")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)

                    Text("Your data is private and secure")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                }
                .padding(.top, 16)
            }
            .padding(.horizontal, 24)

            Spacer()
        }
        .onAppear {
            initializeFromDate()
        }
        .sheet(isPresented: $showingPicker) {
            BirthdayPickerSheet(
                selectedMonth: $selectedMonth,
                selectedDay: $selectedDay,
                selectedYear: $selectedYear,
                months: months,
                onDone: {
                    updateBirthDate()
                    showingPicker = false
                }
            )
            .presentationDetents([.height(350)])
            .presentationDragIndicator(.visible)
        }
    }

    private func initializeFromDate() {
        let calendar = Calendar.current
        selectedMonth = calendar.component(.month, from: birthDate)
        selectedDay = calendar.component(.day, from: birthDate)
        selectedYear = calendar.component(.year, from: birthDate)
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

// MARK: - Birthday Picker Sheet

struct BirthdayPickerSheet: View {
    @Binding var selectedMonth: Int
    @Binding var selectedDay: Int
    @Binding var selectedYear: Int
    let months: [String]
    let onDone: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Spacer()

                Text("Select Birthday")
                    .font(.system(size: 17, weight: .semibold))

                Spacer()

                Button("Done") {
                    onDone()
                }
                .font(.system(size: 17, weight: .semibold))
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 10)

            // Three-column wheel picker
            HStack(spacing: 0) {
                // Month picker
                Picker("Month", selection: $selectedMonth) {
                    ForEach(1...12, id: \.self) { month in
                        Text(months[month - 1]).tag(month)
                    }
                }
                .pickerStyle(.wheel)
                .frame(maxWidth: .infinity)

                // Day picker
                Picker("Day", selection: $selectedDay) {
                    ForEach(1...31, id: \.self) { day in
                        Text("\(day)").tag(day)
                    }
                }
                .pickerStyle(.wheel)
                .frame(width: 70)

                // Year picker
                Picker("Year", selection: $selectedYear) {
                    ForEach((1920...2024).reversed(), id: \.self) { year in
                        Text(String(year)).tag(year)
                    }
                }
                .pickerStyle(.wheel)
                .frame(maxWidth: .infinity)
            }
            .frame(height: 200)

            Spacer()
        }
    }
}

private extension Date {
    var dayOfMonth: Int {
        Calendar.current.component(.day, from: self)
    }
}

// MARK: - Height Picker View (New Style with Bottom Sheet)

struct HeightPickerView: View {
    @Binding var height: Double
    @Binding var heightUnit: HeightUnit
    @Binding var useMetricSystem: Bool

    @State private var showingPicker = false
    @State private var heightFeet: Int = 5
    @State private var heightInches: Int = 10
    @State private var heightCm: Int = 178

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Centered content
            VStack(alignment: .leading, spacing: 16) {
                // Title
                Text("What's your height?")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.black)

                // Imperial / Metric Toggle
                HStack(spacing: 0) {
                    Button(action: {
                        withAnimation {
                            useMetricSystem = false
                            heightUnit = .inches
                            convertToImperial()
                        }
                    }) {
                        Text("Imperial")
                            .font(.system(size: 15, weight: useMetricSystem ? .regular : .semibold))
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(useMetricSystem ? Color.clear : Color.white)
                            .cornerRadius(25)
                    }

                    Button(action: {
                        withAnimation {
                            useMetricSystem = true
                            heightUnit = .cm
                            convertToMetric()
                        }
                    }) {
                        Text("Metric")
                            .font(.system(size: 15, weight: useMetricSystem ? .semibold : .regular))
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(useMetricSystem ? Color.white : Color.clear)
                            .cornerRadius(25)
                    }
                }
                .background(Color(white: 0.85))
                .cornerRadius(25)

                // Big Display Box
                Button(action: { showingPicker = true }) {
                    VStack(spacing: 12) {
                        // Large height display
                        if useMetricSystem {
                            Text("\(heightCm) cm")
                                .font(.system(size: 64, weight: .heavy))
                                .italic()
                                .foregroundColor(.black)
                        } else {
                            Text("\(heightFeet)' \(heightInches)\"")
                                .font(.system(size: 64, weight: .heavy))
                                .italic()
                                .foregroundColor(.black)
                        }

                        // Tap to change
                        HStack(spacing: 6) {
                            Text("Tap to change")
                                .font(.system(size: 15))
                                .foregroundColor(.gray)
                            Image(systemName: "chevron.right.2")
                                .font(.system(size: 12))
                                .foregroundColor(.gray)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 50)
                    .background(Color.white)
                    .cornerRadius(20)
                    .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.top, 16)
            }
            .padding(.horizontal, 24)

            Spacer()
        }
        .onAppear {
            initializeValues()
        }
        .sheet(isPresented: $showingPicker) {
            HeightPickerSheet(
                heightFeet: $heightFeet,
                heightInches: $heightInches,
                heightCm: $heightCm,
                useMetricSystem: useMetricSystem,
                onDone: {
                    updateHeight()
                    showingPicker = false
                }
            )
            .presentationDetents([.height(350)])
            .presentationDragIndicator(.visible)
        }
    }

    private func initializeValues() {
        if heightUnit == .cm || useMetricSystem {
            heightCm = Int(height)
            let totalInches = Int(Double(heightCm) / 2.54)
            heightFeet = totalInches / 12
            heightInches = totalInches % 12
        } else {
            heightFeet = Int(height) / 12
            heightInches = Int(height) % 12
            heightCm = Int(Double(heightFeet * 12 + heightInches) * 2.54)
        }
    }

    private func convertToMetric() {
        heightCm = Int(Double(heightFeet * 12 + heightInches) * 2.54)
        height = Double(heightCm)
    }

    private func convertToImperial() {
        let totalInches = Int(Double(heightCm) / 2.54)
        heightFeet = totalInches / 12
        heightInches = totalInches % 12
        height = Double(heightFeet * 12 + heightInches)
    }

    private func updateHeight() {
        if useMetricSystem {
            height = Double(heightCm)
        } else {
            height = Double(heightFeet * 12 + heightInches)
        }
    }
}

// MARK: - Height Picker Bottom Sheet

struct HeightPickerSheet: View {
    @Binding var heightFeet: Int
    @Binding var heightInches: Int
    @Binding var heightCm: Int
    let useMetricSystem: Bool
    let onDone: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Spacer()

                Text("Select Height")
                    .font(.system(size: 17, weight: .semibold))

                Spacer()

                Button("Done") {
                    onDone()
                }
                .font(.system(size: 17, weight: .semibold))
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 10)

            // Pickers
            if useMetricSystem {
                Picker("Height", selection: $heightCm) {
                    ForEach(100...250, id: \.self) { cm in
                        Text("\(cm) cm").tag(cm)
                    }
                }
                .pickerStyle(.wheel)
                .frame(height: 200)
            } else {
                HStack(spacing: 0) {
                    Picker("Feet", selection: $heightFeet) {
                        ForEach(3...8, id: \.self) { ft in
                            Text("\(ft)'").tag(ft)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(maxWidth: .infinity)

                    Picker("Inches", selection: $heightInches) {
                        ForEach(0...11, id: \.self) { inch in
                            Text("\(inch)\"").tag(inch)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(maxWidth: .infinity)
                }
                .frame(height: 200)
            }

            Spacer()
        }
    }
}

// MARK: - Current Weight Picker View (Horizontal Drag Ruler)

struct CurrentWeightPickerView: View {
    @Binding var weight: Double
    @Binding var weightUnit: WeightUnit
    @Binding var useMetricSystem: Bool

    // Ruler configuration
    private let rulerSpacing: CGFloat = 8  // Space between tick marks
    private let minWeight: Double = 50
    private let maxWeight: Double = 400

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Title
            Text("What's your weight?")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.black)
                .padding(.bottom, 80)

            // Current Weight label and value
            VStack(spacing: 8) {
                Text("Current Weight")
                    .font(.system(size: 15))
                    .foregroundColor(.gray)

                Text(String(format: "%.1f %@", weight, useMetricSystem ? "kg" : "lbs"))
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(.black)
            }
            .padding(.bottom, 40)

            // Horizontal Ruler
            WeightRulerView(
                weight: $weight,
                minWeight: minWeight,
                maxWeight: maxWeight,
                rulerSpacing: rulerSpacing
            )
            .frame(height: 60)

            Spacer()
        }
        .padding(.horizontal, 24)
    }
}

// MARK: - Weight Ruler View (Horizontal Drag)

struct WeightRulerView: View {
    @Binding var weight: Double
    let minWeight: Double
    let maxWeight: Double
    let rulerSpacing: CGFloat

    @State private var baseWeight: Double = 0
    @State private var dragOffset: CGFloat = 0

    private var tickCount: Int {
        Int((maxWeight - minWeight) * 2) + 1  // 0.5 lb increments
    }

    // Calculate the displayed weight based on drag offset
    private func displayedWeight(centerX: CGFloat) -> Double {
        let weightChange = -dragOffset / rulerSpacing * 0.5
        var newWeight = baseWeight + weightChange
        newWeight = max(minWeight, min(maxWeight, newWeight))
        return (newWeight * 2).rounded() / 2
    }

    var body: some View {
        GeometryReader { geometry in
            let centerX = geometry.size.width / 2
            let currentDisplayWeight = displayedWeight(centerX: centerX)

            ZStack {
                // Ruler ticks
                Canvas { context, size in
                    let weightOffset = (currentDisplayWeight - minWeight) * 2 * rulerSpacing
                    let startX = centerX - weightOffset

                    for i in 0..<tickCount {
                        let x = startX + CGFloat(i) * rulerSpacing
                        let tickWeight = minWeight + Double(i) * 0.5

                        // Only draw if visible
                        guard x > -50 && x < size.width + 50 else { continue }

                        let isMajorTick = tickWeight.truncatingRemainder(dividingBy: 10) == 0
                        let isMediumTick = tickWeight.truncatingRemainder(dividingBy: 5) == 0
                        let isMinorTick = tickWeight.truncatingRemainder(dividingBy: 1) == 0

                        let tickHeight: CGFloat
                        let tickWidth: CGFloat
                        let opacity: Double

                        if isMajorTick {
                            tickHeight = 40
                            tickWidth = 2
                            opacity = 1.0
                        } else if isMediumTick {
                            tickHeight = 30
                            tickWidth = 1.5
                            opacity = 0.7
                        } else if isMinorTick {
                            tickHeight = 20
                            tickWidth = 1
                            opacity = 0.5
                        } else {
                            tickHeight = 12
                            tickWidth = 0.5
                            opacity = 0.3
                        }

                        // Calculate fade based on distance from center
                        let distanceFromCenter = abs(x - centerX)
                        let fadeStart = size.width * 0.3
                        let fadeFactor = max(0, 1 - max(0, distanceFromCenter - fadeStart) / (size.width * 0.25))

                        let rect = CGRect(
                            x: x - tickWidth / 2,
                            y: (size.height - tickHeight) / 2,
                            width: tickWidth,
                            height: tickHeight
                        )

                        context.fill(
                            Path(roundedRect: rect, cornerRadius: tickWidth / 2),
                            with: .color(.black.opacity(opacity * fadeFactor))
                        )
                    }
                }

                // Center indicator line
                Rectangle()
                    .fill(Color.black)
                    .frame(width: 3, height: 50)
                    .position(x: centerX, y: 30)
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture()
                    .onChanged { value in
                        dragOffset = value.translation.width
                        // Update weight in real-time
                        weight = displayedWeight(centerX: centerX)
                    }
                    .onEnded { value in
                        // Finalize weight and reset drag state
                        weight = displayedWeight(centerX: centerX)
                        baseWeight = weight
                        dragOffset = 0
                    }
            )
            .onAppear {
                baseWeight = weight
            }
        }
    }
}

// MARK: - Weight Goal Picker View (for Goal Weight - kept for later use)

struct WeightGoalPickerView: View {
    @Binding var currentWeight: Double
    @Binding var goalWeight: Double
    @Binding var targetDate: Date?
    @Binding var weightUnit: WeightUnit
    @Binding var useMetricSystem: Bool

    @State private var showingCurrentWeightPicker = false
    @State private var showingGoalWeightPicker = false
    @State private var showingDatePicker = false
    @State private var currentWeightInt: Int = 154
    @State private var goalWeightInt: Int = 143
    @State private var selectedDate: Date = Calendar.current.date(byAdding: .month, value: 2, to: Date()) ?? Date()

    var body: some View {
        VStack(spacing: 16) {
            // Current Weight
            VStack(alignment: .leading, spacing: 8) {
                Text("Current Weight")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.black)

                Button(action: { showingCurrentWeightPicker = true }) {
                    HStack {
                        Text("\(currentWeightInt) \(weightUnit.rawValue)")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.black)
                        Spacer()
                        Image(systemName: "pencil")
                            .foregroundColor(.gray)
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                }
                .buttonStyle(PlainButtonStyle())
            }

            // Goal Weight
            VStack(alignment: .leading, spacing: 8) {
                Text("Goal Weight")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.black)

                Button(action: { showingGoalWeightPicker = true }) {
                    HStack {
                        Text("\(goalWeightInt) \(weightUnit.rawValue)")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.black)
                        Spacer()
                        Image(systemName: "pencil")
                            .foregroundColor(.gray)
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                }
                .buttonStyle(PlainButtonStyle())
            }

            // Target Date (Optional)
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Target Date")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.black)
                    Text("(Optional)")
                        .font(.system(size: 13))
                        .foregroundColor(.gray)
                }

                Button(action: { showingDatePicker = true }) {
                    HStack {
                        if let date = targetDate {
                            Text(date.formatted(date: .abbreviated, time: .omitted))
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.black)
                        } else {
                            Text("Set target date")
                                .font(.system(size: 17))
                                .foregroundColor(.black)
                        }
                        Spacer()
                        Image(systemName: "calendar")
                            .foregroundColor(.gray)
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .onAppear {
            currentWeightInt = Int(currentWeight)
            goalWeightInt = Int(goalWeight)
            if let date = targetDate {
                selectedDate = date
            }
        }
        .sheet(isPresented: $showingCurrentWeightPicker) {
            WeightPickerSheet(
                weightValue: $currentWeightInt,
                weightUnit: weightUnit,
                title: "Current Weight",
                onDone: {
                    currentWeight = Double(currentWeightInt)
                    showingCurrentWeightPicker = false
                }
            )
            .presentationDetents([.height(350)])
        }
        .sheet(isPresented: $showingGoalWeightPicker) {
            WeightPickerSheet(
                weightValue: $goalWeightInt,
                weightUnit: weightUnit,
                title: "Goal Weight",
                onDone: {
                    goalWeight = Double(goalWeightInt)
                    showingGoalWeightPicker = false
                }
            )
            .presentationDetents([.height(350)])
        }
        .sheet(isPresented: $showingDatePicker) {
            TargetDatePickerSheet(
                selectedDate: $selectedDate,
                targetDate: $targetDate,
                onDone: {
                    showingDatePicker = false
                },
                onClear: {
                    targetDate = nil
                    showingDatePicker = false
                }
            )
            .presentationDetents([.height(450)])
        }
    }
}

// MARK: - Weight Picker Bottom Sheet

struct WeightPickerSheet: View {
    @Binding var weightValue: Int
    let weightUnit: WeightUnit
    let title: String
    let onDone: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text(title)
                    .font(.system(size: 17, weight: .semibold))
                Spacer()
                Button("Done") {
                    onDone()
                }
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.black)
            }
            .padding()
            .background(Color(UIColor.systemBackground))

            Divider()

            // Picker
            Picker("Weight", selection: $weightValue) {
                if weightUnit == .lbs {
                    ForEach(80...400, id: \.self) { lb in
                        Text("\(lb) lbs").tag(lb)
                    }
                } else {
                    ForEach(30...200, id: \.self) { kg in
                        Text("\(kg) kg").tag(kg)
                    }
                }
            }
            .pickerStyle(.wheel)
        }
        .background(Color(UIColor.systemBackground))
    }
}

// MARK: - Target Date Picker Sheet

struct TargetDatePickerSheet: View {
    @Binding var selectedDate: Date
    @Binding var targetDate: Date?
    let onDone: () -> Void
    let onClear: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button("Clear") {
                    onClear()
                }
                .font(.system(size: 17))
                .foregroundColor(.gray)

                Spacer()

                Text("Target Date")
                    .font(.system(size: 17, weight: .semibold))

                Spacer()

                Button("Done") {
                    targetDate = selectedDate
                    onDone()
                }
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.black)
            }
            .padding()
            .background(Color(UIColor.systemBackground))

            Divider()

            // Date Picker
            DatePicker(
                "Target Date",
                selection: $selectedDate,
                in: Date()...,
                displayedComponents: .date
            )
            .datePickerStyle(.graphical)
            .padding()
        }
        .background(Color(UIColor.systemBackground))
    }
}

// MARK: - Activity Level Picker View

struct ActivityLevelPickerView: View {
    @Binding var selectedLevel: ActivityLevel?

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                ForEach(ActivityLevel.allCases, id: \.self) { level in
                    ActivityLevelButton(
                        level: level,
                        isSelected: selectedLevel == level,
                        onTap: { selectedLevel = level }
                    )
                }
            }
        }
    }
}

struct ActivityLevelButton: View {
    let level: ActivityLevel
    let isSelected: Bool
    let onTap: () -> Void

    @State private var isPressed = false

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
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.black)
                        .font(.title2)
                }
            }
            .padding()
            .background(isSelected ? Color.black.opacity(0.05) : Color.white)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.black : Color.black.opacity(0.1), lineWidth: isSelected ? 2 : 1)
            )
            .scaleEffect(isPressed ? 0.98 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0, pressing: { pressing in
            withAnimation(.easeInOut(duration: 0.15)) {
                isPressed = pressing
            }
        }, perform: {})
    }
}

// MARK: - Calorie Bias Picker View

struct CalorieBiasPickerView: View {
    @Binding var selectedBias: CalorieBias

    private let biasValues: [CalorieBias] = [.underMore, .under, .noBias, .over, .overMore]

    var body: some View {
        VStack(spacing: 32) {
            // Info Card
            VStack(spacing: 12) {
                Text(selectedBias.title)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.black)

                HStack {
                    Circle()
                        .fill(Color.black)
                        .frame(width: 8, height: 8)
                    Text(selectedBias.description)
                        .font(.system(size: 15))
                        .foregroundColor(.gray)
                }

                HStack {
                    Text("🍔")
                    Text(selectedBias.example)
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                }
            }
            .padding(20)
            .frame(maxWidth: .infinity)
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)

            // Slider
            VStack(spacing: 16) {
                // Custom slider
                GeometryReader { geometry in
                    let stepWidth = geometry.size.width / CGFloat(biasValues.count - 1)
                    let currentIndex = biasValues.firstIndex(of: selectedBias) ?? 2

                    ZStack(alignment: .leading) {
                        // Track
                        Rectangle()
                            .fill(Color.black.opacity(0.2))
                            .frame(height: 4)
                            .frame(maxWidth: .infinity)

                        // Thumb
                        Circle()
                            .fill(Color.white)
                            .frame(width: 32, height: 32)
                            .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
                            .offset(x: CGFloat(currentIndex) * stepWidth - 16)
                            .gesture(
                                DragGesture()
                                    .onChanged { value in
                                        let newIndex = Int(round(value.location.x / stepWidth))
                                        let clampedIndex = max(0, min(biasValues.count - 1, newIndex))
                                        selectedBias = biasValues[clampedIndex]
                                    }
                            )
                    }
                }
                .frame(height: 32)

                // Labels
                HStack {
                    ForEach(biasValues, id: \.self) { bias in
                        VStack(spacing: 4) {
                            Circle()
                                .fill(colorForBias(bias))
                                .frame(width: 8, height: 8)
                            Text(bias.title.replacingOccurrences(of: " ", with: "\n"))
                                .font(.system(size: 11))
                                .foregroundColor(selectedBias == bias ? .black : .gray)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .onTapGesture {
                            withAnimation {
                                selectedBias = bias
                            }
                        }
                    }
                }
            }
            .padding(.horizontal)
        }
    }

    private func colorForBias(_ bias: CalorieBias) -> Color {
        switch bias {
        case .underMore, .under:
            return Color.blue.opacity(0.6)
        case .noBias:
            return Color.black
        case .over, .overMore:
            return Color.orange.opacity(0.6)
        }
    }
}

// MARK: - Height & Weight Picker View (Imperial/Metric toggle) - LEGACY

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

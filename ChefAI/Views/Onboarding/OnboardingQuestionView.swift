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
        // Pages with their own centered layout (name=0, gender=1, birthday=2, height=3, weight=4, desired weight=5)
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
        } else if question.id == 5 {
            DesiredWeightPickerView(
                weight: $viewModel.desiredWeight,
                weightUnit: $viewModel.weightUnit,
                useMetricSystem: $viewModel.useMetricSystem
            )
        } else {
            VStack(alignment: .leading, spacing: 24) {
                // Title and subtitle
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

                // Question content based on type
                questionContent

                Spacer()
            }
            .padding(.horizontal, 24)
        }
    }

    @ViewBuilder
    private var questionContent: some View {
        switch question.id {
        // These cases are handled by the special layout above, but kept for completeness
        case 0:
            NameInputView(name: $viewModel.userName)
        case 1:
            ScrollView {
                GenderSelectionView(selectedGender: $viewModel.selectedGender)
            }
        case 2:
            AgePickerView(birthDate: $viewModel.birthDate)
        case 3:
            HeightPickerView(
                height: $viewModel.userHeight,
                heightUnit: $viewModel.heightUnit,
                useMetricSystem: $viewModel.useMetricSystem
            )
        case 4:
            CurrentWeightPickerView(
                weight: $viewModel.userWeight,
                weightUnit: $viewModel.weightUnit,
                useMetricSystem: $viewModel.useMetricSystem
            )
        case 5:
            DesiredWeightPickerView(
                weight: $viewModel.desiredWeight,
                weightUnit: $viewModel.weightUnit,
                useMetricSystem: $viewModel.useMetricSystem
            )

        case 6:
            // Activity level
            ActivityLevelPickerView(selectedLevel: $viewModel.selectedActivityLevel)

        case 7:
            // Days per week
            DaysPerWeekPicker(days: $viewModel.cookingDaysPerWeek)

        case 8:
            // Biggest struggle with eating healthy
            ScrollView {
                TagPicker(
                    items: CookingStruggle.allCases,
                    selectedItems: $viewModel.selectedStruggles,
                    iconProvider: { $0.icon }
                )
            }

        case 9:
            // Time availability
            ScrollView {
                MultipleChoiceSelector(
                    items: TimeAvailability.allCases,
                    selected: $viewModel.selectedTimeAvailability,
                    iconProvider: { $0.icon }
                )
            }

        case 10:
            // Dietary restrictions
            ScrollView {
                TagPicker(
                    items: ExtendedDietaryRestriction.allCases,
                    selectedItems: $viewModel.selectedRestrictions,
                    iconProvider: { $0.icon }
                )
            }

        case 11:
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

        case 12:
            // Have you tried dieting before?
            YesNoSelectionView(selection: $viewModel.hasTriedDietChange)

        case 13:
            // What stopped you last time?
            ScrollView {
                TagPicker(
                    items: DietBarrier.allCases,
                    selectedItems: $viewModel.selectedDietBarriers,
                    iconProvider: { $0.icon }
                )
            }

        case 14:
            // How would eating healthier improve your life?
            ScrollView {
                TagPicker(
                    items: HealthImprovementGoal.allCases,
                    selectedItems: $viewModel.selectedHealthGoals,
                    iconProvider: { $0.icon }
                )
            }

        case 15:
            // What matters most to you right now?
            ScrollView {
                MultipleChoiceSelector(
                    items: CommitmentPriority.allCases,
                    selected: $viewModel.selectedCommitmentPriority,
                    iconProvider: { $0.icon }
                )
            }

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

// MARK: - Selection Button (reusable)

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
    private let rulerSpacing: CGFloat = 8
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

// MARK: - Desired Weight Picker View (Same ruler style as Current Weight)

struct DesiredWeightPickerView: View {
    @Binding var weight: Double
    @Binding var weightUnit: WeightUnit
    @Binding var useMetricSystem: Bool

    // Ruler configuration
    private let rulerSpacing: CGFloat = 8
    private let minWeight: Double = 50
    private let maxWeight: Double = 400

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Title
            Text("What's your desired weight?")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.black)
                .padding(.bottom, 12)

            // Subtitle
            Text("We'll help you get there")
                .font(.system(size: 15))
                .foregroundColor(.gray)
                .padding(.bottom, 60)

            // Desired Weight label and value
            VStack(spacing: 8) {
                Text("Desired Weight")
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

//
//  UserPreferences.swift
//  ChefAI
//
//  Created by Claude on 2025-01-30.
//

import Foundation

// MARK: - Main Goal

enum MainGoal: String, Codable, CaseIterable {
    case loseWeight = "Lose weight"
    case gainMuscle = "Gain muscle"
    case maintainWeight = "Maintain weight"
    case eatHealthier = "Eat healthier"
    case saveTime = "Save time"
    case saveMoney = "Save money"
    case eatMoreProtein = "Eat more protein"

    var icon: String {
        switch self {
        case .loseWeight: return "arrow.down.circle.fill"
        case .gainMuscle: return "figure.strengthtraining.traditional"
        case .maintainWeight: return "equal.circle.fill"
        case .eatHealthier: return "leaf.fill"
        case .saveTime: return "clock.fill"
        case .saveMoney: return "dollarsign.circle.fill"
        case .eatMoreProtein: return "flame.fill"
        }
    }

    var description: String {
        switch self {
        case .loseWeight: return "Focus on lower calorie, filling meals"
        case .gainMuscle: return "High protein, calorie-dense recipes"
        case .maintainWeight: return "Balanced, nutritious meals"
        case .eatHealthier: return "Whole foods and nutritious ingredients"
        case .saveTime: return "Quick and easy recipes"
        case .saveMoney: return "Budget-friendly ingredients"
        case .eatMoreProtein: return "Protein-packed meals"
        }
    }

    /// Primary goals shown on first onboarding screen (only 3 options)
    static var primaryOptions: [MainGoal] {
        [.eatHealthier, .saveTime, .saveMoney]
    }
}

// MARK: - Extended Dietary Restriction

enum ExtendedDietaryRestriction: String, Codable, CaseIterable {
    case vegetarian = "Vegetarian"
    case vegan = "Vegan"
    case pescatarian = "Pescatarian"
    case dairyFree = "Dairy-free"
    case glutenFree = "Gluten-free"
    case nutAllergy = "Nut allergy"
    case none = "None"

    var icon: String {
        switch self {
        case .vegetarian: return "leaf.fill"
        case .vegan: return "leaf.circle.fill"
        case .pescatarian: return "fish.fill"
        case .dairyFree: return "d.circle.fill"
        case .glutenFree: return "g.circle.fill"
        case .nutAllergy: return "exclamationmark.triangle.fill"
        case .none: return "checkmark.circle.fill"
        }
    }

    var description: String {
        switch self {
        case .vegetarian: return "No meat or fish"
        case .vegan: return "No animal products"
        case .pescatarian: return "Fish but no meat"
        case .dairyFree: return "No dairy products"
        case .glutenFree: return "No gluten-containing foods"
        case .nutAllergy: return "Avoid all nuts"
        case .none: return "No dietary restrictions"
        }
    }
}

// MARK: - Meal Preference

enum MealPreference: String, Codable, CaseIterable {
    case quickEasy = "Quick & easy"
    case highProtein = "High protein"
    case cheapMeals = "Cheap meals"
    case mealPrep = "Meal prep"
    case healthyComfort = "Healthy comfort food"
    case restaurantStyle = "Restaurant-style"

    var icon: String {
        switch self {
        case .quickEasy: return "bolt.fill"
        case .highProtein: return "flame.fill"
        case .cheapMeals: return "dollarsign.circle.fill"
        case .mealPrep: return "tray.full.fill"
        case .healthyComfort: return "heart.fill"
        case .restaurantStyle: return "star.fill"
        }
    }

    var description: String {
        switch self {
        case .quickEasy: return "Ready in 30 minutes or less"
        case .highProtein: return "Packed with protein"
        case .cheapMeals: return "Budget-friendly options"
        case .mealPrep: return "Great for batch cooking"
        case .healthyComfort: return "Nutritious comfort classics"
        case .restaurantStyle: return "Impressive, fancy dishes"
        }
    }
}

// MARK: - Time Availability

enum TimeAvailability: String, Codable, CaseIterable {
    case under10 = "Under 10 minutes"
    case tenTo20 = "10-20 minutes"
    case twentyTo40 = "20-40 minutes"
    case fortyPlus = "40+ minutes"

    var icon: String {
        switch self {
        case .under10: return "hare.fill"
        case .tenTo20: return "clock.fill"
        case .twentyTo40: return "timer"
        case .fortyPlus: return "tortoise.fill"
        }
    }

    var maxMinutes: Int {
        switch self {
        case .under10: return 10
        case .tenTo20: return 20
        case .twentyTo40: return 40
        case .fortyPlus: return 999 // No limit
        }
    }

    var description: String {
        switch self {
        case .under10: return "Super quick recipes only"
        case .tenTo20: return "Fast but flexible"
        case .twentyTo40: return "Standard cooking time"
        case .fortyPlus: return "I have time to cook"
        }
    }
}

// MARK: - Cooking Equipment

enum CookingEquipment: String, Codable, CaseIterable {
    case oven = "Oven"
    case airFryer = "Air fryer"
    case stove = "Stove"
    case microwave = "Microwave"
    case blender = "Blender"
    case knifeSet = "Knife set"
    case cuttingBoard = "Cutting board"
    case measuringCups = "Measuring cups"

    var icon: String {
        switch self {
        case .oven: return "oven.fill"
        case .airFryer: return "fan.fill"
        case .stove: return "flame"
        case .microwave: return "microwave.fill"
        case .blender: return "blender.fill"
        case .knifeSet: return "scissors"
        case .cuttingBoard: return "rectangle.fill"
        case .measuringCups: return "cup.and.saucer.fill"
        }
    }
}

// MARK: - Cooking Struggle

enum CookingStruggle: String, Codable, CaseIterable {
    case dontKnowWhatToCook = "Don't know what to cook"
    case noTime = "No time"
    case notConfident = "Not confident at cooking"
    case wastingIngredients = "Wasting ingredients"
    case eatingHealthier = "Eating healthier"
    case savingMoney = "Saving money"

    var icon: String {
        switch self {
        case .dontKnowWhatToCook: return "questionmark.circle.fill"
        case .noTime: return "clock.badge.exclamationmark.fill"
        case .notConfident: return "person.fill.questionmark"
        case .wastingIngredients: return "trash.fill"
        case .eatingHealthier: return "leaf.fill"
        case .savingMoney: return "dollarsign.circle.fill"
        }
    }

    var helpText: String {
        switch self {
        case .dontKnowWhatToCook: return "We'll suggest creative recipes based on what you have"
        case .noTime: return "We'll prioritize quick, efficient recipes"
        case .notConfident: return "We'll include detailed step-by-step instructions"
        case .wastingIngredients: return "We'll help you use up what you have"
        case .eatingHealthier: return "We'll focus on nutritious, whole-food recipes"
        case .savingMoney: return "We'll suggest budget-friendly alternatives"
        }
    }
}

// MARK: - Adventure Level

enum AdventureLevel: String, Codable, CaseIterable {
    case simpleBasics = "Simple basics"
    case sometimesAdventurous = "Sometimes adventurous"
    case surpriseMe = "Surprise me"

    var icon: String {
        switch self {
        case .simpleBasics: return "house.fill"
        case .sometimesAdventurous: return "map.fill"
        case .surpriseMe: return "sparkles"
        }
    }

    var description: String {
        switch self {
        case .simpleBasics: return "Classic, familiar recipes with common ingredients"
        case .sometimesAdventurous: return "A mix of familiar and new flavors"
        case .surpriseMe: return "Bring on the exotic ingredients and bold flavors!"
        }
    }

    var recipeComplexity: String {
        switch self {
        case .simpleBasics: return "basic"
        case .sometimesAdventurous: return "moderate"
        case .surpriseMe: return "creative"
        }
    }
}

// MARK: - NEW: Physical Stats & Personal Info

enum WeightUnit: String, Codable, CaseIterable {
    case lbs = "lbs"
    case kg = "kg"
}

enum HeightUnit: String, Codable, CaseIterable {
    case inches = "inches"
    case cm = "cm"
}

// MARK: - NEW: Gender

enum Gender: String, Codable, CaseIterable {
    case male = "Male"
    case female = "Female"
    case other = "Other"
    case preferNotToSay = "Prefer not to say"

    var icon: String {
        switch self {
        case .male: return "figure.stand"
        case .female: return "figure.stand.dress"
        case .other: return "figure.2"
        case .preferNotToSay: return "questionmark.circle"
        }
    }
}

// MARK: - NEW: Physique Goal (Optional)

enum PhysiqueGoal: String, Codable, CaseIterable {
    case buildMuscle = "Build muscle"
    case loseFat = "Lose fat"
    case maintainCurrent = "Maintain current physique"
    case toneUp = "Tone up"
    case preferNotToSay = "Prefer not to say"

    var icon: String {
        switch self {
        case .buildMuscle: return "figure.strengthtraining.traditional"
        case .loseFat: return "figure.walk"
        case .maintainCurrent: return "figure.stand"
        case .toneUp: return "figure.arms.open"
        case .preferNotToSay: return "hand.raised.fill"
        }
    }

    var description: String {
        switch self {
        case .buildMuscle: return "Focus on protein-rich, calorie-dense meals"
        case .loseFat: return "Emphasize lower-calorie, filling foods"
        case .maintainCurrent: return "Balanced nutrition for stability"
        case .toneUp: return "Lean protein with moderate calories"
        case .preferNotToSay: return "We'll provide general balanced recommendations"
        }
    }
}

// MARK: - NEW: Processed Food Impact

enum ProcessedFoodImpact: String, Codable, CaseIterable {
    case lowEnergy = "Low energy"
    case weightGain = "Weight gain"
    case poorDigestion = "Poor digestion"
    case guilt = "Feel guilty after eating"
    case expensiveHabit = "Spending too much"
    case none = "No negative impact"

    var icon: String {
        switch self {
        case .lowEnergy: return "battery.25"
        case .weightGain: return "arrow.up.circle"
        case .poorDigestion: return "stomach"
        case .guilt: return "face.dashed"
        case .expensiveHabit: return "dollarsign.arrow.circlepath"
        case .none: return "checkmark.circle.fill"
        }
    }
}

// MARK: - NEW: Organic Cooking Goals

enum OrganicGoal: String, Codable, CaseIterable {
    case consistency = "Cook organic consistently"
    case variety = "Try new organic recipes"
    case budgetOrganic = "Organic on a budget"
    case familyOrganic = "Get family to eat organic"

    var icon: String {
        switch self {
        case .consistency: return "calendar.badge.checkmark"
        case .variety: return "sparkles"
        case .budgetOrganic: return "leaf.circle"
        case .familyOrganic: return "person.3.fill"
        }
    }
}

// MARK: - NEW: Cooking Frequency

enum CookingFrequency: String, Codable, CaseIterable {
    case rarely = "Rarely (0-1 times/week)"
    case sometimes = "Sometimes (2-3 times/week)"
    case often = "Often (4-5 times/week)"
    case daily = "Daily (6-7 times/week)"

    var icon: String {
        switch self {
        case .rarely: return "1.circle"
        case .sometimes: return "2.circle"
        case .often: return "4.circle"
        case .daily: return "7.circle.fill"
        }
    }
}

// MARK: - NEW: Cooking Time of Day

enum CookingTimeOfDay: String, Codable, CaseIterable {
    case morning = "Morning (6-11am)"
    case lunch = "Lunch (11am-2pm)"
    case afternoon = "Afternoon (2-6pm)"
    case dinner = "Dinner (6-9pm)"
    case lateNight = "Late night (9pm+)"

    var icon: String {
        switch self {
        case .morning: return "sunrise.fill"
        case .lunch: return "sun.max.fill"
        case .afternoon: return "sun.haze.fill"
        case .dinner: return "sunset.fill"
        case .lateNight: return "moon.stars.fill"
        }
    }
}

// MARK: - NEW: Diet Change Barriers

enum DietBarrier: String, Codable, CaseIterable {
    case noTime = "No time"
    case tooExpensive = "Too expensive"
    case dontKnowHow = "Don't know how to cook healthy"
    case familyResistance = "Family doesn't like healthy food"
    case lackMotivation = "Lack of motivation"
    case confusingInfo = "Too much conflicting info"

    var icon: String {
        switch self {
        case .noTime: return "clock.badge.xmark"
        case .tooExpensive: return "dollarsign.circle"
        case .dontKnowHow: return "book.closed"
        case .familyResistance: return "person.2.slash"
        case .lackMotivation: return "figure.stand"
        case .confusingInfo: return "questionmark.circle"
        }
    }
}

// MARK: - NEW: Cooking Motivation

enum CookingMotivation: String, Codable, CaseIterable {
    case healthGoals = "Achieve health goals"
    case saveMoney = "Save money on food"
    case familyHealth = "Improve family's health"
    case newSkill = "Learn a new skill"
    case stressRelief = "Cooking is relaxing"
    case socialMedia = "Share on social media"

    var icon: String {
        switch self {
        case .healthGoals: return "heart.text.square.fill"
        case .saveMoney: return "dollarsign.circle.fill"
        case .familyHealth: return "figure.2.and.child.holdinghands"
        case .newSkill: return "graduationcap.fill"
        case .stressRelief: return "leaf.fill"
        case .socialMedia: return "camera.fill"
        }
    }
}

// MARK: - NEW: Acquisition Source

enum AcquisitionSource: String, Codable, CaseIterable {
    case instagram = "Instagram"
    case tiktok = "TikTok"
    case youtube = "YouTube"
    case friendFamily = "Friend or family"
    case googleSearch = "Google search"
    case appStore = "App Store search"
    case other = "Other"

    var icon: String {
        switch self {
        case .instagram: return "photo.fill"
        case .tiktok: return "video.fill"
        case .youtube: return "play.rectangle.fill"
        case .friendFamily: return "person.2.fill"
        case .googleSearch: return "magnifyingglass"
        case .appStore: return "app.badge.fill"
        case .other: return "ellipsis.circle.fill"
        }
    }
}

// MARK: - NEW: Aspirational Goals

enum AspirationalGoal: String, Codable, CaseIterable {
    case moreFocused = "More focused & energized"
    case betterSleep = "Better sleep"
    case clearerSkin = "Clearer skin"
    case strongerBody = "Stronger & fitter"
    case happierMood = "Happier mood"
    case familyHealth = "Healthier family"

    var icon: String {
        switch self {
        case .moreFocused: return "bolt.fill"
        case .betterSleep: return "bed.double.fill"
        case .clearerSkin: return "sparkles"
        case .strongerBody: return "figure.strengthtraining.traditional"
        case .happierMood: return "face.smiling.fill"
        case .familyHealth: return "heart.circle.fill"
        }
    }
}

// MARK: - NEW: Activity Level

enum ActivityLevel: String, Codable, CaseIterable {
    case sedentary = "Sedentary"
    case lightlyActive = "Lightly Active"
    case moderatelyActive = "Moderately Active"
    case veryActive = "Very Active"

    var icon: String {
        switch self {
        case .sedentary: return "chair.lounge.fill"
        case .lightlyActive: return "figure.walk"
        case .moderatelyActive: return "figure.run"
        case .veryActive: return "figure.highintensity.intervaltraining"
        }
    }

    var description: String {
        switch self {
        case .sedentary: return "Little to no exercise, desk job"
        case .lightlyActive: return "Light exercise 1-3 days/week"
        case .moderatelyActive: return "Moderate exercise 3-5 days/week"
        case .veryActive: return "Intense exercise 6-7 days/week"
        }
    }

    var multiplier: Double {
        switch self {
        case .sedentary: return 1.2
        case .lightlyActive: return 1.375
        case .moderatelyActive: return 1.55
        case .veryActive: return 1.725
        }
    }
}

// MARK: - NEW: Calorie Bias

enum CalorieBias: Int, Codable, CaseIterable {
    case underMore = -2
    case under = -1
    case noBias = 0
    case over = 1
    case overMore = 2

    var title: String {
        switch self {
        case .underMore: return "Under More"
        case .under: return "Under"
        case .noBias: return "No Bias"
        case .over: return "Over"
        case .overMore: return "Over More"
        }
    }

    var description: String {
        switch self {
        case .underMore: return "Aggressive underestimate for weight loss"
        case .under: return "Slight underestimate for weight loss"
        case .noBias: return "Balanced approach for precise tracking"
        case .over: return "Slight overestimate for muscle gain"
        case .overMore: return "Aggressive overestimate for bulking"
        }
    }

    var example: String {
        switch self {
        case .underMore: return "500-700 cal meal -> logs as 500 cal"
        case .under: return "500-700 cal meal -> logs as 550 cal"
        case .noBias: return "500-700 cal meal -> logs as 600 cal"
        case .over: return "500-700 cal meal -> logs as 650 cal"
        case .overMore: return "500-700 cal meal -> logs as 700 cal"
        }
    }
}

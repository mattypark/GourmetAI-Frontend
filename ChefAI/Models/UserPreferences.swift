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

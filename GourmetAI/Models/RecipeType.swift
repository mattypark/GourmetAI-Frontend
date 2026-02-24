//
//  RecipeType.swift
//  ChefAI
//

import Foundation

enum RecipeType: String, CaseIterable, Identifiable, Codable {
    case quickAndEasy = "Quick & Easy"
    case healthyAndLight = "Healthy & Light"
    case comfortFood = "Comfort Food"
    case dessertsAndBaking = "Desserts & Baking"
    case highProtein = "High Protein"
    case budgetFriendly = "Budget Friendly"
    case onePotMeals = "One-Pot Meals"
    case mealPrep = "Meal Prep"
    case custom = "Custom"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .quickAndEasy: return "bolt.fill"
        case .healthyAndLight: return "leaf.fill"
        case .comfortFood: return "house.fill"
        case .dessertsAndBaking: return "birthday.cake.fill"
        case .highProtein: return "dumbbell.fill"
        case .budgetFriendly: return "dollarsign.circle.fill"
        case .onePotMeals: return "frying.pan.fill"
        case .mealPrep: return "clock.fill"
        case .custom: return "pencil.circle.fill"
        }
    }

    var subtitle: String {
        switch self {
        case .quickAndEasy: return "Under 30 minutes"
        case .healthyAndLight: return "Low calorie, nutritious"
        case .comfortFood: return "Warm and satisfying"
        case .dessertsAndBaking: return "Sweet treats"
        case .highProtein: return "Protein-packed meals"
        case .budgetFriendly: return "Affordable ingredients"
        case .onePotMeals: return "Minimal cleanup"
        case .mealPrep: return "Make ahead for the week"
        case .custom: return "Type your own search"
        }
    }

    /// Preset types only (excludes .custom)
    static var presets: [RecipeType] {
        allCases.filter { $0 != .custom }
    }
}

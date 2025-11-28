//
//  UserProfile.swift
//  ChefAI
//
//  Created by Claude on 2025-01-28.
//

import Foundation

struct UserProfile: Codable {
    var id: UUID
    var mainGoal: CookingGoal?
    var dietaryRestrictions: [DietaryRestriction]
    var cookingSkillLevel: SkillLevel?
    var createdAt: Date
    var updatedAt: Date

    init() {
        self.id = UUID()
        self.dietaryRestrictions = []
        self.createdAt = Date()
        self.updatedAt = Date()
    }

    var isOnboardingComplete: Bool {
        mainGoal != nil && cookingSkillLevel != nil
    }
}

// MARK: - Cooking Goal

enum CookingGoal: String, Codable, CaseIterable {
    case healthy = "Healthy"
    case highProtein = "High-Protein"
    case budgetFriendly = "Budget-Friendly"
    case quickMeals = "Quick Meals"
    case gourmet = "Gourmet"
    case familyFriendly = "Family-Friendly"

    var icon: String {
        switch self {
        case .healthy: return "leaf.fill"
        case .highProtein: return "flame.fill"
        case .budgetFriendly: return "dollarsign.circle.fill"
        case .quickMeals: return "clock.fill"
        case .gourmet: return "star.fill"
        case .familyFriendly: return "person.3.fill"
        }
    }
}

// MARK: - Dietary Restriction

enum DietaryRestriction: String, Codable, CaseIterable {
    case vegetarian = "Vegetarian"
    case vegan = "Vegan"
    case glutenFree = "Gluten-Free"
    case dairyFree = "Dairy-Free"
    case nutFree = "Nut-Free"
    case kosher = "Kosher"
    case halal = "Halal"
    case lowCarb = "Low-Carb"

    var icon: String {
        switch self {
        case .vegetarian, .vegan: return "leaf"
        case .glutenFree: return "g.circle"
        case .dairyFree: return "d.circle.fill"
        case .nutFree: return "n.circle.fill"
        case .kosher, .halal: return "checkmark.seal"
        case .lowCarb: return "c.circle"
        }
    }
}

// MARK: - Skill Level

enum SkillLevel: String, Codable, CaseIterable {
    case beginner = "Beginner"
    case intermediate = "Intermediate"
    case advanced = "Advanced"
    case professional = "Professional"

    var description: String {
        switch self {
        case .beginner: return "Just starting out"
        case .intermediate: return "Comfortable with basics"
        case .advanced: return "Confident in the kitchen"
        case .professional: return "Expert level"
        }
    }
}

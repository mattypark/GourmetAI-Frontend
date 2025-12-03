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
    var cookingStyle: CookingStyle?
    var cuisinePreferences: [CuisineType]
    var createdAt: Date
    var updatedAt: Date

    init() {
        self.id = UUID()
        self.dietaryRestrictions = []
        self.cuisinePreferences = []
        self.createdAt = Date()
        self.updatedAt = Date()
    }

    var isOnboardingComplete: Bool {
        mainGoal != nil && cookingSkillLevel != nil
    }

    // Custom decoder to handle migration from old profiles without new fields
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        mainGoal = try container.decodeIfPresent(CookingGoal.self, forKey: .mainGoal)
        dietaryRestrictions = try container.decodeIfPresent([DietaryRestriction].self, forKey: .dietaryRestrictions) ?? []
        cookingSkillLevel = try container.decodeIfPresent(SkillLevel.self, forKey: .cookingSkillLevel)
        // New fields - default to nil/empty if not present in old data
        cookingStyle = try container.decodeIfPresent(CookingStyle.self, forKey: .cookingStyle)
        cuisinePreferences = try container.decodeIfPresent([CuisineType].self, forKey: .cuisinePreferences) ?? []
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
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

// MARK: - Cooking Style

enum CookingStyle: String, Codable, CaseIterable {
    case organic = "Organic"
    case grassFed = "Grass-Fed"
    case raw = "Raw"
    case farmToTable = "Farm-to-Table"
    case sustainable = "Sustainable"
    case traditional = "Traditional"

    var icon: String {
        switch self {
        case .organic: return "leaf.fill"
        case .grassFed: return "hare.fill"
        case .raw: return "carrot.fill"
        case .farmToTable: return "house.and.flag.fill"
        case .sustainable: return "globe.americas.fill"
        case .traditional: return "frying.pan.fill"
        }
    }
}

// MARK: - Cuisine Type

enum CuisineType: String, Codable, CaseIterable {
    case korean = "Korean"
    case french = "French"
    case italian = "Italian"
    case chinese = "Chinese"
    case japanese = "Japanese"
    case mexican = "Mexican"
    case indian = "Indian"
    case thai = "Thai"
    case american = "American"
    case mediterranean = "Mediterranean"

    var icon: String {
        switch self {
        case .korean: return "fork.knife"
        case .french: return "wineglass.fill"
        case .italian: return "takeoutbag.and.cup.and.straw.fill"
        case .chinese: return "bowl.fill"
        case .japanese: return "fish.fill"
        case .mexican: return "flame.fill"
        case .indian: return "leaf.arrow.triangle.circlepath"
        case .thai: return "leaf.fill"
        case .american: return "star.fill"
        case .mediterranean: return "drop.fill"
        }
    }
}

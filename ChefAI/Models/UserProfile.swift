//
//  UserProfile.swift
//  ChefAI
//
//  Created by Claude on 2025-01-28.
//

import Foundation

struct UserProfile: Codable {
    var id: UUID
    var createdAt: Date
    var updatedAt: Date

    // Primary onboarding fields (new enums)
    var mainGoal: MainGoal?
    var dietaryRestrictions: [ExtendedDietaryRestriction]
    var cookingSkillLevel: SkillLevel?
    var mealPreferences: [MealPreference]
    var timeAvailability: TimeAvailability?
    var cookingEquipment: [CookingEquipment]
    var cookingStruggles: [CookingStruggle]
    var adventureLevel: AdventureLevel?

    // Legacy/additional fields (kept for backward compatibility)
    var cookingStyle: CookingStyle?
    var cuisinePreferences: [CuisineType]

    init() {
        self.id = UUID()
        self.dietaryRestrictions = []
        self.mealPreferences = []
        self.cookingEquipment = []
        self.cookingStruggles = []
        self.cuisinePreferences = []
        self.createdAt = Date()
        self.updatedAt = Date()
    }

    var isOnboardingComplete: Bool {
        mainGoal != nil &&
        cookingSkillLevel != nil &&
        timeAvailability != nil &&
        adventureLevel != nil
    }

    // Custom decoder to handle migration from old profiles
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let legacyContainer = try? decoder.container(keyedBy: LegacyCodingKeys.self)

        id = try container.decode(UUID.self, forKey: .id)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)

        // New main goal - try to decode, or migrate from old CookingGoal
        if let newGoal = try? container.decodeIfPresent(MainGoal.self, forKey: .mainGoal) {
            mainGoal = newGoal
        } else if let legacyContainer = legacyContainer,
                  let oldGoal = try? legacyContainer.decodeIfPresent(CookingGoal.self, forKey: .mainGoal) {
            // Migrate old CookingGoal to new MainGoal
            mainGoal = MainGoal.migrateFrom(oldGoal)
        } else {
            mainGoal = nil
        }

        // New dietary restrictions - try to decode, or migrate from old
        if let newRestrictions = try? container.decodeIfPresent([ExtendedDietaryRestriction].self, forKey: .dietaryRestrictions) {
            dietaryRestrictions = newRestrictions
        } else if let legacyContainer = legacyContainer,
                  let oldRestrictions = try? legacyContainer.decodeIfPresent([DietaryRestriction].self, forKey: .dietaryRestrictions) {
            // Migrate old restrictions to new format
            dietaryRestrictions = oldRestrictions.map { ExtendedDietaryRestriction.migrateFrom($0) }
        } else {
            dietaryRestrictions = []
        }

        cookingSkillLevel = try container.decodeIfPresent(SkillLevel.self, forKey: .cookingSkillLevel)
        mealPreferences = try container.decodeIfPresent([MealPreference].self, forKey: .mealPreferences) ?? []
        timeAvailability = try container.decodeIfPresent(TimeAvailability.self, forKey: .timeAvailability)
        cookingEquipment = try container.decodeIfPresent([CookingEquipment].self, forKey: .cookingEquipment) ?? []
        cookingStruggles = try container.decodeIfPresent([CookingStruggle].self, forKey: .cookingStruggles) ?? []
        adventureLevel = try container.decodeIfPresent(AdventureLevel.self, forKey: .adventureLevel)

        // Legacy fields
        cookingStyle = try container.decodeIfPresent(CookingStyle.self, forKey: .cookingStyle)
        cuisinePreferences = try container.decodeIfPresent([CuisineType].self, forKey: .cuisinePreferences) ?? []
    }

    private enum CodingKeys: String, CodingKey {
        case id, createdAt, updatedAt
        case mainGoal, dietaryRestrictions, cookingSkillLevel
        case mealPreferences, timeAvailability, cookingEquipment
        case cookingStruggles, adventureLevel
        case cookingStyle, cuisinePreferences
    }

    // Legacy keys used only for migration decoding
    private enum LegacyCodingKeys: String, CodingKey {
        case mainGoal = "oldMainGoal"
        case dietaryRestrictions = "oldDietaryRestrictions"
    }
}

// MARK: - Legacy Cooking Goal (for migration)

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

// MARK: - Legacy Dietary Restriction (for migration)

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

    var description: String {
        switch self {
        case .beginner: return "Just starting out"
        case .intermediate: return "Comfortable with basics"
        case .advanced: return "Confident in the kitchen"
        }
    }

    var icon: String {
        switch self {
        case .beginner: return "1.circle.fill"
        case .intermediate: return "2.circle.fill"
        case .advanced: return "3.circle.fill"
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

// MARK: - Migration Helpers

extension MainGoal {
    static func migrateFrom(_ oldGoal: CookingGoal) -> MainGoal {
        switch oldGoal {
        case .healthy: return .eatHealthier
        case .highProtein: return .eatMoreProtein
        case .budgetFriendly: return .saveMoney
        case .quickMeals: return .saveTime
        case .gourmet: return .eatHealthier
        case .familyFriendly: return .maintainWeight
        }
    }
}

extension ExtendedDietaryRestriction {
    static func migrateFrom(_ oldRestriction: DietaryRestriction) -> ExtendedDietaryRestriction {
        switch oldRestriction {
        case .vegetarian: return .vegetarian
        case .vegan: return .vegan
        case .glutenFree: return .glutenFree
        case .dairyFree: return .dairyFree
        case .nutFree: return .nutAllergy
        case .kosher, .halal, .lowCarb: return .none
        }
    }
}

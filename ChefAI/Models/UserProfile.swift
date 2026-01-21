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

    // NEW: Personal information
    var userName: String?
    var userGender: Gender?
    var userAge: Int?
    var userWeight: Double? // in lbs or kg
    var userHeight: Double? // in inches or cm
    var weightUnit: WeightUnit?
    var heightUnit: HeightUnit?
    var physiqueGoal: PhysiqueGoal? // OPTIONAL

    // NEW: Onboarding questions
    var eatsOrganic: Bool? // true = organic, false = processed
    var processedFoodImpact: [ProcessedFoodImpact]?
    var organicCookingGoals: [OrganicGoal]?
    var cookingDaysPerWeek: Int? // 0-7
    var cookingFrequency: CookingFrequency?
    var cookingTimesOfDay: [CookingTimeOfDay]?
    var hasTriedDietChange: Bool?
    var dietChangeBarriers: [DietBarrier]?
    var motivationToCook: [CookingMotivation]?
    var acquisitionSource: AcquisitionSource?
    var aspirationalGoals: [AspirationalGoal]?

    // Primary onboarding fields (existing)
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
        // Check if minimum required fields are filled
        userName != nil &&
        userGender != nil &&
        mainGoal != nil &&
        cookingSkillLevel != nil &&
        timeAvailability != nil &&
        adventureLevel != nil
    }

    // MARK: - Calculated Fields

    /// Calculate BMI from weight and height
    var bmi: Double? {
        guard let weight = userWeight,
              let height = userHeight,
              let weightUnit = weightUnit,
              let heightUnit = heightUnit else {
            return nil
        }

        // Convert to metric (kg and meters)
        let weightInKg: Double
        let heightInMeters: Double

        switch weightUnit {
        case .lbs:
            weightInKg = weight * 0.453592
        case .kg:
            weightInKg = weight
        }

        switch heightUnit {
        case .inches:
            heightInMeters = height * 0.0254
        case .cm:
            heightInMeters = height / 100.0
        }

        return weightInKg / (heightInMeters * heightInMeters)
    }

    /// Calculate recommended daily calories based on age, weight, height, gender, and goal
    var recommendedCalories: Int? {
        guard let weight = userWeight,
              let height = userHeight,
              let age = userAge,
              let weightUnit = weightUnit,
              let heightUnit = heightUnit else {
            return nil
        }

        // Convert to metric
        let weightInKg: Double
        let heightInCm: Double

        switch weightUnit {
        case .lbs:
            weightInKg = weight * 0.453592
        case .kg:
            weightInKg = weight
        }

        switch heightUnit {
        case .inches:
            heightInCm = height * 2.54
        case .cm:
            heightInCm = height
        }

        // Mifflin-St Jeor Equation for BMR
        var bmr: Double

        if let gender = userGender {
            switch gender {
            case .male:
                bmr = (10 * weightInKg) + (6.25 * heightInCm) - (5 * Double(age)) + 5
            case .female:
                bmr = (10 * weightInKg) + (6.25 * heightInCm) - (5 * Double(age)) - 161
            case .other, .preferNotToSay:
                // Use average between male and female
                let maleBMR = (10 * weightInKg) + (6.25 * heightInCm) - (5 * Double(age)) + 5
                let femaleBMR = (10 * weightInKg) + (6.25 * heightInCm) - (5 * Double(age)) - 161
                bmr = (maleBMR + femaleBMR) / 2
            }
        } else {
            // No gender provided, use average
            let maleBMR = (10 * weightInKg) + (6.25 * heightInCm) - (5 * Double(age)) + 5
            let femaleBMR = (10 * weightInKg) + (6.25 * heightInCm) - (5 * Double(age)) - 161
            bmr = (maleBMR + femaleBMR) / 2
        }

        // Multiply by activity factor (assuming moderate activity)
        var tdee = bmr * 1.55

        // Adjust based on goal
        if let goal = mainGoal {
            switch goal {
            case .loseWeight:
                tdee *= 0.85 // 15% deficit
            case .gainMuscle:
                tdee *= 1.1 // 10% surplus
            case .maintainWeight:
                break // Keep as is
            case .eatHealthier, .saveTime, .saveMoney, .eatMoreProtein:
                break // Keep as is
            }
        }

        // Adjust based on physique goal if available
        if let physiqueGoal = physiqueGoal {
            switch physiqueGoal {
            case .loseFat:
                tdee *= 0.85 // 15% deficit
            case .buildMuscle:
                tdee *= 1.1 // 10% surplus
            case .maintainCurrent:
                break
            case .toneUp:
                tdee *= 0.95 // Slight deficit
            case .preferNotToSay:
                break
            }
        }

        return Int(tdee)
    }

    // Custom decoder to handle migration from old profiles
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let legacyContainer = try? decoder.container(keyedBy: LegacyCodingKeys.self)

        id = try container.decode(UUID.self, forKey: .id)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)

        // NEW: Personal information
        userName = try container.decodeIfPresent(String.self, forKey: .userName)
        userGender = try container.decodeIfPresent(Gender.self, forKey: .userGender)
        userAge = try container.decodeIfPresent(Int.self, forKey: .userAge)
        userWeight = try container.decodeIfPresent(Double.self, forKey: .userWeight)
        userHeight = try container.decodeIfPresent(Double.self, forKey: .userHeight)
        weightUnit = try container.decodeIfPresent(WeightUnit.self, forKey: .weightUnit)
        heightUnit = try container.decodeIfPresent(HeightUnit.self, forKey: .heightUnit)
        physiqueGoal = try container.decodeIfPresent(PhysiqueGoal.self, forKey: .physiqueGoal)

        // NEW: Onboarding questions
        eatsOrganic = try container.decodeIfPresent(Bool.self, forKey: .eatsOrganic)
        processedFoodImpact = try container.decodeIfPresent([ProcessedFoodImpact].self, forKey: .processedFoodImpact)
        organicCookingGoals = try container.decodeIfPresent([OrganicGoal].self, forKey: .organicCookingGoals)
        cookingDaysPerWeek = try container.decodeIfPresent(Int.self, forKey: .cookingDaysPerWeek)
        cookingFrequency = try container.decodeIfPresent(CookingFrequency.self, forKey: .cookingFrequency)
        cookingTimesOfDay = try container.decodeIfPresent([CookingTimeOfDay].self, forKey: .cookingTimesOfDay)
        hasTriedDietChange = try container.decodeIfPresent(Bool.self, forKey: .hasTriedDietChange)
        dietChangeBarriers = try container.decodeIfPresent([DietBarrier].self, forKey: .dietChangeBarriers)
        motivationToCook = try container.decodeIfPresent([CookingMotivation].self, forKey: .motivationToCook)
        acquisitionSource = try container.decodeIfPresent(AcquisitionSource.self, forKey: .acquisitionSource)
        aspirationalGoals = try container.decodeIfPresent([AspirationalGoal].self, forKey: .aspirationalGoals)

        // Existing fields - try to decode, or migrate from old
        if let newGoal = try? container.decodeIfPresent(MainGoal.self, forKey: .mainGoal) {
            mainGoal = newGoal
        } else if let legacyContainer = legacyContainer,
                  let oldGoal = try? legacyContainer.decodeIfPresent(CookingGoal.self, forKey: .mainGoal) {
            mainGoal = MainGoal.migrateFrom(oldGoal)
        } else {
            mainGoal = nil
        }

        if let newRestrictions = try? container.decodeIfPresent([ExtendedDietaryRestriction].self, forKey: .dietaryRestrictions) {
            dietaryRestrictions = newRestrictions
        } else if let legacyContainer = legacyContainer,
                  let oldRestrictions = try? legacyContainer.decodeIfPresent([DietaryRestriction].self, forKey: .dietaryRestrictions) {
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
        // NEW: Personal information
        case userName, userGender, userAge, userWeight, userHeight
        case weightUnit, heightUnit, physiqueGoal
        // NEW: Onboarding questions
        case eatsOrganic, processedFoodImpact, organicCookingGoals
        case cookingDaysPerWeek, cookingFrequency, cookingTimesOfDay
        case hasTriedDietChange, dietChangeBarriers, motivationToCook
        case acquisitionSource, aspirationalGoals
        // Existing fields
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

// MARK: - Food Preference (Organic/Processed)

enum FoodPreference: String, Codable, CaseIterable {
    case organic = "Mostly organic"
    case mixed = "Mix of both"
    case processed = "Mostly processed"

    /// Convert to Bool? for storage (legacy compatibility)
    var toBool: Bool? {
        switch self {
        case .organic: return true
        case .mixed: return nil
        case .processed: return false
        }
    }

    /// Create from Bool? (legacy compatibility)
    static func from(_ bool: Bool?) -> FoodPreference? {
        guard let value = bool else { return .mixed }
        return value ? .organic : .processed
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

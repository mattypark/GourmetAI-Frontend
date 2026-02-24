//
//  AppTab.swift
//  ChefAI
//
//  Bottom tab bar tab definitions
//

import SwiftUI

enum AppTab: String, CaseIterable {
    case home
    case calendar
    case explore
    case favorites

    var icon: String {
        switch self {
        case .home: return "house.fill"
        case .calendar: return "calendar"
        case .explore: return "safari"
        case .favorites: return "heart"
        }
    }

    var label: String {
        switch self {
        case .home: return "Home"
        case .calendar: return "Calendar"
        case .explore: return "Explore"
        case .favorites: return "Favorites"
        }
    }
}

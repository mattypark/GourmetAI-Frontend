//
//  Config.swift
//  ChefAI
//
//  Created by Claude on 2025-01-29.
//

import Foundation

struct Config {
    // MARK: - Backend Configuration
    // The iOS app communicates with the ChefAI Backend server hosted on Render
    // All AI API keys (Gemini, etc.) are stored securely on the server

    // Production backend URL (Render)
    static let backendBaseURL = "https://chefai-backend-z4o6.onrender.com"

    // Backend API Key (loaded from Info.plist via Secrets.xcconfig — never hardcode)
    static let backendAPIKey: String = {
        guard let key = Bundle.main.infoDictionary?["BackendAPIKey"] as? String,
              !key.isEmpty,
              key != "your-backend-api-key-here" else {
            #if DEBUG
            fatalError("BackendAPIKey not configured. Copy Secrets.xcconfig.template to Secrets.xcconfig and set your key.")
            #else
            return ""
            #endif
        }
        return key
    }()

    // MARK: - Supabase Configuration
    static let supabaseURL = "https://qencjmovexgzsuvktcny.supabase.co"
    static let supabaseAnonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFlbmNqbW92ZXhnenN1dmt0Y255Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjUwMDAxMjQsImV4cCI6MjA4MDU3NjEyNH0.FVC-sq_BWV0TpWh5H4G5IHE5ajFA-isTTJugZTvTETE"

    // MARK: - Google Sign-In
    static let googleClientID = "189666648950-smd8uel5jlbs497ticog41gtvdrht18c.apps.googleusercontent.com"

    // MARK: - Request Settings
    static let requestTimeout: TimeInterval = 90.0
    static let maxRetries: Int = 2
}

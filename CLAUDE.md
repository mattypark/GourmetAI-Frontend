# Gourmet AI - Project Context

## What This App Does

Gourmet AI is an iOS app that lets users photograph their fridge/pantry ingredients using their phone camera (or pick from gallery), sends those images to a backend for AI-powered ingredient detection, then generates personalized recipes based on what the user has on hand. Users can also photograph a fully cooked dish to have AI identify it and generate a detailed step-by-step recipe. The app includes a comprehensive onboarding flow that collects personal health data, dietary preferences, and cooking habits to personalize recipe recommendations.

## Architecture Overview

**Two separate repositories:**

1. **GourmetAI-iOS** (this repo) - SwiftUI iOS app, MVVM pattern
2. **GourmetAI-Backend** (sibling directory at `../GourmetAI-Backend`) - Vapor 4 Swift server

The iOS app sends images to the backend, which calls Gemini for ingredient detection, then searches for recipes via Tavily and generates them via Gemini.

## Tech Stack

### iOS App
- **Language:** Swift, SwiftUI
- **Architecture:** MVVM (Models / ViewModels / Views / Services)
- **Auth:** Supabase Auth (Google OAuth, Apple OAuth, email/password)
- **Local Storage:** JSON files in Documents directory via `StorageService`, `UserDefaults` for flags
- **Networking:** URLSession to backend API
- **Package Manager:** Swift Package Manager (SPM)

### Backend
- **Framework:** Vapor 4 (Swift server)
- **AI Model:** Gemini 2.5 Flash Lite (`gemini-2.5-flash-lite`)
- **Recipe Search:** Tavily API (web search with domain whitelisting)
- **HTML Parsing:** SwiftSoup
- **Deployment:** Docker on Render.com (free tier)
- **Health Check:** `GET /health`

## Environment Variables & Keys Used

### Backend (env vars in `render.yaml` / `.env`)
- `GEMINI_API_KEY` - Google Gemini API key
- `BACKEND_API_KEY` - Shared secret between iOS app and backend
- `TAVILY_API_KEY` - Tavily search API key
- `SUPABASE_URL` - Supabase project URL
- `SUPABASE_SERVICE_KEY` - Supabase service role key
- `PORT` - Server port (default 8080)

### iOS App (hardcoded in `Config.swift`)
- `backendBaseURL` - Backend URL on Render
- `backendAPIKey` - Matches backend's `BACKEND_API_KEY`
- `supabaseURL` - Supabase project URL
- `supabaseAnonKey` - Supabase anon/public key (JWT)
- `googleClientID` - Google OAuth client ID
- `requestTimeout` - 90 seconds
- `maxRetries` - 2

### Storage Keys (`StorageKeys.swift`)
- `hasCompletedOnboarding` - Global `@AppStorage` bool
- `userProfileKey` - UserProfile JSON path
- `currentUserId` - UUID string in UserDefaults
- `onboarding_complete_<userId>` - Per-user onboarding flag
- `settings.userName` - Display name for home screen

> **IMPORTANT:** Never read or output actual API key values, `.env` file contents, or credentials. Only reference key *names*.

## Backend API Endpoints

| Method | Path | Purpose |
|--------|------|---------|
| GET | `/health` | Health check (no auth) |
| POST | `/api/v1/analyze/image` | Image ingredient detection via Gemini |
| POST | `/api/v1/analyze/dish` | Dish identification + full detailed recipe via Gemini |
| POST | `/api/v1/recipes/generate` | Recipe generation (Gemini only, no web search) |
| POST | `/api/v1/recipes/generate-stream` | Recipe generation with Tavily web search + Gemini |

All endpoints except `/health` require `X-API-Key` header.

### Image Analysis Flow
1. iOS sends base64-encoded JPEG (resized to 512px, 0.3 compression quality)
2. Backend sends image to Gemini with prompt to identify food ingredients
3. Gemini returns JSON array of `{name, category, quantity, unit, confidence}`
4. Backend maps to `APIIngredient` objects and returns to iOS

### Dish Analysis Flow (new)
1. iOS sends base64-encoded JPEG of a cooked dish
2. Backend sends image to Gemini to identify the dish name + generate full recipe
3. Gemini returns dish name + recipe with 10-20 granular detailed steps
4. Returns `AnalyzeDishResponse` with dishName + full Recipe object to iOS

### Recipe Generation Flow
1. iOS sends ingredient names + optional user profile
2. Backend searches Tavily for recipes (whitelisted domains: allrecipes, foodnetwork, bonappetit, seriouseats, epicurious, simplyrecipes, delish, tasty.co, budgetbytes, thekitchn)
3. Backend sends search results + ingredients to Gemini for structured recipe generation
4. Returns `APIRecipe` objects with source attribution and Tavily images
5. All recipes now include `detailedSteps` array (10-20 granular steps with exact temps, times, technique tags)

### Known Backend Quirk: FlexibleString
Gemini sometimes returns numbers where strings are expected (e.g., `"quantity": 3` instead of `"3"`). The `FlexibleString` custom `Decodable` handles this by accepting both `String` and `Double` and converting to `String`.

## iOS App Structure

```
GourmetAI/
├── ChefAIApp.swift              # Entry point, routing, OAuth callbacks (file kept as-is)
├── Models/
│   ├── AnalysisResult.swift      # Image analysis result (multi-image support)
│   ├── Ingredient.swift          # Ingredient + NutritionInfo + IngredientCategory
│   ├── Recipe.swift              # Recipe + RecipeStep + RecipeIngredient + RecipeSource
│   ├── RecipeJob.swift           # SSE job tracking + status events
│   ├── UserProfile.swift         # Complete user data model (new + legacy fields)
│   ├── UserPreferences.swift     # All preference enums (30+ enums)
│   ├── OnboardingQuestion.swift  # Question type definitions
│   ├── OnboardingResponse.swift  # Response screen configs (after Q6, Q9, Q11, Q14)
│   ├── Inventory.swift           # Ingredient inventory management
│   ├── Subscription.swift        # Subscription tiers + premium features
│   └── CaptureMode.swift         # Camera capture types
├── ViewModels/
│   ├── CameraViewModel.swift     # Core: multi-image capture, dish scan, analysis pipeline
│   ├── OnboardingViewModel.swift # 16-question flow with conditional logic
│   ├── HomeViewModel.swift       # Home feed data
│   ├── CaptureViewModel.swift    # AVFoundation camera session
│   ├── RecipeListViewModel.swift # Recipe list management
│   ├── RecipeDetailViewModel.swift
│   └── SettingsViewModel.swift
├── Views/
│   ├── Onboarding/               # Splash, Welcome, Questions, Responses, Completion, LiquidGlassSplash
│   ├── Main/                     # MainTabView, FloatingPlusButton, CustomTabBar
│   ├── Home/                     # HomeView, AnalysisCardView, RecipeJobCardView
│   ├── Camera/                   # CaptureScreen, MultiImageReview, AnalysisResult,
│   │                             # CameraSheetView (mode selector), DishScanReviewView, RecipeTypeSelectionView
│   ├── Recipes/                  # RecipeList, RecipeDetail, RecipeCard, RecipeStep
│   ├── Detail/                   # AnalysisDetailView, IngredientListView
│   ├── Components/               # AnalysisLoadingView, WelcomeGradientOverlayView, SwipeToDeleteWrapper
│   ├── Authentication/           # AuthenticationView (Google, Apple, email)
│   ├── Settings/                 # Settings, ProfileEdit, AppSettings, PrivacyPolicy, NutritionGoals
│   ├── Profile/                  # ProfileView, ProfileMenuView
│   ├── Paywall/                  # PaywallPlanSelectorView, WhyCostView
│   ├── Favorites/                # Favorites views
│   └── Calendar/                 # Calendar views
├── Services/
│   ├── StorageService.swift      # Local JSON persistence (max 50 analyses)
│   ├── SupabaseManager.swift     # Auth + profiles + saved recipes + ingredient history
│   ├── RecipeJobService.swift    # SSE recipe job tracking
│   ├── FavoriteService.swift     # Favorite recipes management
│   ├── HealthKitService.swift    # HealthKit integration
│   ├── RecipeCategoryService.swift
│   ├── CameraService.swift       # Camera permissions
│   ├── InventoryService.swift
│   ├── SubscriptionService.swift
│   └── ImagePickerService.swift
├── Networking/
│   └── APIClient.swift           # HTTP client for backend communication
├── Utilities/
│   ├── Config.swift              # API keys and URLs
│   ├── Constants/
│   │   ├── AppConstants.swift    # App-wide constants (appName = "Gourmet AI")
│   │   └── StorageKeys.swift     # UserDefaults key names
│   └── Extensions/               # Color+Theme, View+Extensions, Date+Extensions
├── Components/                   # Reusable UI: Buttons, Cards, Forms, Common
└── Resources/
    └── MockData.swift
```

## App Constants (`AppConstants.swift`)
- `appName` = "Gourmet AI"
- `maxManualItems` = 20
- `imageCompressionQuality` = 0.7
- `maxImageSizeKB` = 1024
- `maxStoredAnalyses` = 50
- `maxCapturedImages` = 5

## User Flow

### First Launch
1. **Splash Screen** -> **Welcome Screen** -> **Authentication** (Google/Apple/Email)
2. **Onboarding** (16 questions) -> **Completion** -> **Home**

### Returning User
- App checks per-user onboarding flag (`onboarding_complete_<userId>`)
- If completed, goes directly to Home with WelcomeGradientOverlay (once per session)
- If different user logs in, checks their specific flag

### Main Usage Loop
1. Tap floating "+" button (bottom right) -> **CameraSheetView** mode selector
2. Choose **"Scan Ingredients"** or **"Identify a Dish"**
3. **Scan Ingredients:** Capture/select up to 5 photos -> Multi-image review -> Analyze -> ingredient list + recipes
4. **Identify a Dish:** Take photo of cooked meal -> AI identifies dish + generates full detailed recipe
5. View results: ingredients + recipe cards with detailed steps
6. Tap recipe for full detail (steps, ingredients, nutrition, tips, source link)

## Scan Mode (CameraViewModel)

```swift
enum ScanMode {
    case ingredients  // Multi-image fridge/pantry scan
    case dish         // Single image dish identification
}
```

- `scanMode` published property routes to either `MultiImageReviewView` or `DishScanReviewView`
- Dish scan calls `POST /api/v1/analyze/dish` → returns dish name + full recipe
- `DishScanResultView` shows recipe with Steps/Ingredients/Nutrition tabs

## Multi-Image Capture

- Users can capture up to 5 images of their fridge/pantry
- `CameraViewModel.analyzeMultipleImages()` uses `withTaskGroup` for parallel API calls
- Each image is analyzed independently; results are deduplicated by ingredient name
- Progress bar updates per-image: `0.05 + (completedCount / totalCount) * 0.45`
- Then recipe generation: `0.55` -> `0.90` -> `1.0`

## Analysis Pipeline (`CameraViewModel`)

```
AnalysisStatus enum:
  idle -> detectingIngredients -> ingredientsDetected -> generatingRecipes -> finished
```

- `analysisProgress: Double` (0.0 to 1.0) drives the real progress bar
- `AnalysisLoadingView` reads progress via `@ObservedObject var cameraViewModel`
- Loading view is vertically centered with Spacers, shows random food facts during wait

## Detailed Recipe Steps

All recipes now include `detailedSteps: [RecipeStep]` with 10-20 granular steps:
- Exact temperatures, times, visual cues
- Technique tags (e.g. "sauté", "deglaze")
- Much more specific than the original 1-8 broad steps

## Welcome Gradient Overlay

- `WelcomeGradientOverlayView` — animated blue gradient shown once per app launch
- `WelcomeOverlayManager` (singleton `ObservableObject`) — tracks if shown this session
- Shown when: user is onboarded + authenticated + has access
- Auto-dismisses after 2 seconds with fade animation

## Onboarding Flow (16 Questions)

### Section 1: Personal Info (Q0-Q6)
| Q# | Question | Type |
|----|----------|------|
| 0 | What's your name? | Text input |
| 1 | What gender are you? | Single choice |
| 2 | When were you born? | Date picker |
| 3 | What's your height? | Height picker (imperial/metric) |
| 4 | What's your weight? | Weight picker |
| 5 | What's your desired weight? | Weight picker |
| 6 | What's your activity level? | Single choice |

### Section 2: Cooking Habits (Q7-Q11)
| Q# | Question | Type |
|----|----------|------|
| 7 | How often do you cook per week? | Days slider (0-7) |
| 8 | Biggest struggle with eating healthy? | Multi-select |
| 9 | How much time can you spend cooking? | Single choice |
| 10 | Dietary restrictions? | Multi-select |
| 11 | How adventurous are you with food? | Single choice |

### Section 3: Motivation (Q12-Q14)
| Q# | Question | Type |
|----|----------|------|
| 12 | Have you tried dieting before? | Yes/No |
| 13 | What stopped you last time? | Multi-select (only if Q12=Yes) |
| 14 | How would eating healthier improve your life? | Multi-select |

### Section 4: Commitment (Q15)
| Q# | Question | Type |
|----|----------|------|
| 15 | What matters most to you right now? | Single choice |

*Response screens shown after Q6, Q9, Q11, Q14*

## Data Models

### UserProfile
- Personal: name, gender, age, weight, desiredWeight, height, units, activityLevel, physiqueGoal
- Cooking: cookingDaysPerWeek, eatingStruggles, timeAvailability, dietaryRestrictions, adventureLevel
- Motivation: hasTriedDietChange, dietChangeBarriers, healthImprovementGoals, commitmentPriority
- Computed: `bmi`, `recommendedCalories` (Mifflin-St Jeor equation)

### AnalysisResult
- `imagesData: [Data]` - Multiple captured images
- `extractedIngredients: [Ingredient]`
- `suggestedRecipes: [Recipe]`
- `manuallyAddedItems: [String]`

### Recipe
- Full data: name, description, instructions, detailedSteps, ingredients, image, tags
- Nutrition: calories, protein, carbs, fat per serving
- Source attribution: name, URL, author
- Difficulty: easy, medium, hard, expert

### Ingredient
- Properties: name, brandName, quantity, unit, category, confidence, nutritionInfo
- Categories: Produce, Dairy, Meat, Seafood, Grains, Pantry Staples, Condiments, Spices, Frozen, Beverages, Snacks, Bakery, Other

## Authentication

- **Supabase Auth** with three providers: Google OAuth, Apple OAuth, Email/Password
- Google Sign-In configured in `ChefAIApp.init()` with `GIDSignIn`
- OAuth callbacks handled via `onOpenURL` in app entry point
- Per-user state tracking ensures onboarding is per-account, not per-device

### Supabase Tables
- `profiles` - User profile data
- `saved_recipes` - Bookmarked recipes
- `ingredient_history` - Scan history

## iOS Dependencies (SPM)

- **supabase-swift** v2.40.0 - Database & Auth
- **GoogleSignIn-iOS** v9.1.0 - Google authentication
- **GoogleUtilities** v8.1.0
- **AppAuth-iOS** v2.0.0 - OAuth
- **GTMAppAuth** v5.0.0
- **swift-crypto** v4.2.0

## Backend Dependencies (SPM)

- **Vapor** v4.89.0+ - HTTP server framework
- **SwiftSoup** v2.6.0+ - HTML parsing

## Backend Deployment

- **Host:** Render.com (Docker, free tier)
- **Dockerfile:** Swift 5.9 multi-stage build (builder -> slim runtime)
- **Config:** `render.yaml` defines the web service with env vars
- **Health check:** `GET /health` returns "OK"
- **Max body size:** 10MB (for base64-encoded images)

## UI Design Patterns

- **Light theme only** - Explicit white/light gray backgrounds (not system-adaptive)
- **Black pill buttons** - Primary actions use black background, white text, 28pt radius, 56pt height
- **Floating action button** - Bottom-right "+" button
- **Full-screen covers** - Camera, multi-image review, and analysis results
- **Loading screen** - Vertically centered, real progress bar, random food facts
- **Close buttons** - Gray circle with "xmark" SF Symbol

## App Branding

- **App Name (display):** Gourmet AI
- **Bundle ID:** com.HMU.GourmetAI
- **App Store:** "Gourmet AI - AI Food Maker"
- **App Icon:** Green background with white fork & knife (greenchefai.png)
- **Internal Xcode target:** GourmetAI
- **Project file:** GourmetAI.xcodeproj
- **Source folder:** GourmetAI/

## Folder Structure on Disk

```
current-projects/
├── GourmetAI-iOS/          # iOS app (was ChefAI-iOS)
│   ├── GourmetAI/          # Source files (was ChefAI/)
│   └── GourmetAI.xcodeproj # Xcode project (was ChefAI.xcodeproj)
├── GourmetAI-Backend/      # Vapor backend (was ChefAI-Backend)
└── GourmetAI-Waitlist/     # Waitlist site (was ChefAI waitlist)
```

## Current State & Known Issues

- Backend runs on Render.com free tier (may sleep after inactivity, causing slow cold starts)
- Superwall paywall integration planned but not yet active
- `SubscriptionService` exists but gating is minimal
- Developer promo code is now `GOURMETAI-DEV` (was `CHEFAI-DEV`)
- Support email is `support@gourmetai.app` (was `support@chefai.app`)
- Build number is currently at 3 (version 1.0)
- After renaming, packages must be resolved via File → Packages → Resolve Package Versions

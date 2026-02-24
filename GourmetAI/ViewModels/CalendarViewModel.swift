//
//  CalendarViewModel.swift
//  ChefAI
//
//  ViewModel for the weekly calendar tab
//

import Foundation
import Combine

enum CalendarEntryType {
    case favorited  // red
    case analyzed   // black
    case saved      // green
}

struct CalendarEntry: Identifiable {
    let id: UUID
    let name: String
    let date: Date
    let type: CalendarEntryType
    let ingredientCount: Int?
    let thumbnailData: Data?
}

@MainActor
class CalendarViewModel: ObservableObject {
    @Published var selectedDate: Date = Date()
    @Published var currentWeekDates: [Date] = []
    @Published var entriesForSelectedDate: [CalendarEntry] = []

    private let calendar = Calendar.current
    private var cancellables = Set<AnyCancellable>()

    init() {
        loadWeek()
        loadEntries()

        // Re-load entries when completed jobs change
        RecipeJobService.shared.$completedJobs
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.loadEntries()
            }
            .store(in: &cancellables)
    }

    // MARK: - Week Calculation

    func loadWeek() {
        // Get Monday of the current week containing selectedDate
        var cal = calendar
        cal.firstWeekday = 2 // Monday
        guard let weekInterval = cal.dateInterval(of: .weekOfYear, for: selectedDate) else { return }
        let monday = weekInterval.start

        currentWeekDates = (0..<7).compactMap { offset in
            cal.date(byAdding: .day, value: offset, to: monday)
        }
    }

    func selectDate(_ date: Date) {
        selectedDate = date
        loadEntries()
    }

    func isToday(_ date: Date) -> Bool {
        calendar.isDateInToday(date)
    }

    func isSelected(_ date: Date) -> Bool {
        calendar.isDate(date, inSameDayAs: selectedDate)
    }

    func dayLetter(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEEE" // Single letter: M, T, W, etc.
        return formatter.string(from: date)
    }

    func dayNumber(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }

    // MARK: - Activity Detection

    func hasActivity(on date: Date) -> Bool {
        let analyses = StorageService.shared.loadAnalyses()
        let hasAnalysis = analyses.contains { calendar.isDate($0.date, inSameDayAs: date) }
        if hasAnalysis { return true }

        let jobs = RecipeJobService.shared.completedJobs
        return jobs.contains { calendar.isDate($0.createdAt, inSameDayAs: date) }
    }

    // MARK: - Load Entries

    func loadEntries() {
        var entries: [CalendarEntry] = []
        let date = selectedDate

        // Get completed recipe jobs for this day
        let jobs = RecipeJobService.shared.completedJobs.filter {
            calendar.isDate($0.createdAt, inSameDayAs: date)
        }

        // Get analyses for this day
        let analyses = StorageService.shared.loadAnalyses().filter {
            calendar.isDate($0.date, inSameDayAs: date)
        }

        // Track which analysis IDs have associated jobs
        let jobAnalysisIds = Set(jobs.map { $0.analysisId })

        // Add recipe entries from completed jobs (saved)
        for job in jobs {
            if job.status == .finished {
                for recipe in job.recipes {
                    entries.append(CalendarEntry(
                        id: recipe.id,
                        name: recipe.name.lowercased(),
                        date: job.createdAt,
                        type: .saved,
                        ingredientCount: nil,
                        thumbnailData: job.thumbnailData
                    ))
                }
            } else if job.status == .error {
                entries.append(CalendarEntry(
                    id: job.id,
                    name: job.ingredients.prefix(3).joined(separator: ", ").lowercased(),
                    date: job.createdAt,
                    type: .analyzed,
                    ingredientCount: job.ingredients.count,
                    thumbnailData: job.thumbnailData
                ))
            }
        }

        // Add scan entries for analyses without a recipe job (analyzed)
        for analysis in analyses where !jobAnalysisIds.contains(analysis.id) {
            let name = analysis.extractedIngredients.prefix(3)
                .map { $0.name.lowercased() }
                .joined(separator: ", ")
            entries.append(CalendarEntry(
                id: analysis.id,
                name: name.isEmpty ? "ingredient scan" : name,
                date: analysis.date,
                type: .analyzed,
                ingredientCount: analysis.extractedIngredients.count,
                thumbnailData: analysis.imageData
            ))
        }

        entriesForSelectedDate = entries
    }
}

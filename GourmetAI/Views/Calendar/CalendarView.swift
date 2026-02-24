//
//  CalendarView.swift
//  ChefAI
//
//  Weekly calendar showing scan and recipe activity
//

import SwiftUI

struct CalendarView: View {
    @StateObject private var viewModel = CalendarViewModel()

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Week day selector
                weekSelector
                    .padding(.top, 8)
                    .padding(.bottom, 20)
                    .staggerEntry(index: 0)

                // Legend
                legendRow
                    .padding(.bottom, 16)
                    .staggerEntry(index: 1)

                Divider()
                    .foregroundColor(.black.opacity(0.08))
                    .staggerEntry(index: 2)

                // Meal list
                if viewModel.entriesForSelectedDate.isEmpty {
                    emptyState
                        .staggerEntry(index: 3)
                } else {
                    mealList
                        .staggerEntry(index: 3)
                }

                Spacer()
            }
            .background(Color.theme.background.ignoresSafeArea())
            .navigationTitle("This week")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    // MARK: - Week Selector

    private var weekSelector: some View {
        HStack(spacing: 0) {
            ForEach(viewModel.currentWeekDates, id: \.self) { date in
                Button {
                    viewModel.selectDate(date)
                } label: {
                    VStack(spacing: 6) {
                        // Day letter
                        Text(viewModel.dayLetter(for: date))
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.gray)

                        // Date number
                        ZStack {
                            if viewModel.isSelected(date) {
                                Circle()
                                    .fill(Color.black)
                                    .frame(width: 36, height: 36)
                            }

                            Text(viewModel.dayNumber(for: date))
                                .font(.system(size: 15, weight: viewModel.isSelected(date) ? .bold : .regular))
                                .foregroundColor(viewModel.isSelected(date) ? .white : .black)
                        }
                        .frame(width: 36, height: 36)

                        // Activity dot
                        Circle()
                            .fill(Color.black)
                            .frame(width: 6, height: 6)
                            .opacity(viewModel.hasActivity(on: date) ? 1 : 0)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Legend

    private var legendRow: some View {
        HStack(spacing: 20) {
            HStack(spacing: 6) {
                Circle()
                    .fill(Color.red)
                    .frame(width: 8, height: 8)
                Text("Favorited")
                    .font(.system(size: 13))
                    .foregroundColor(.black)
            }

            HStack(spacing: 6) {
                Circle()
                    .fill(Color.black)
                    .frame(width: 8, height: 8)
                Text("Analyzed")
                    .font(.system(size: 13))
                    .foregroundColor(.black)
            }

            HStack(spacing: 6) {
                Circle()
                    .fill(Color.green)
                    .frame(width: 8, height: 8)
                Text("Saved")
                    .font(.system(size: 13))
                    .foregroundColor(.black)
            }

            Spacer()
        }
        .padding(.horizontal, 24)
    }

    // MARK: - Meal List

    private func entryColor(for type: CalendarEntryType) -> Color {
        switch type {
        case .favorited: return .red
        case .analyzed: return .black
        case .saved: return .green
        }
    }

    private var mealList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(viewModel.entriesForSelectedDate) { entry in
                    VStack(spacing: 0) {
                        HStack {
                            Circle()
                                .fill(entryColor(for: entry.type))
                                .frame(width: 8, height: 8)

                            Text(entry.name)
                                .font(.system(size: 17))
                                .foregroundColor(.black)

                            Spacer()

                            Text(entry.type == .favorited ? "Favorited" : entry.type == .analyzed ? "Analyzed" : "Saved")
                                .font(.system(size: 13))
                                .foregroundColor(.gray)
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 16)

                        Divider()
                            .padding(.leading, 24)
                    }
                }
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 12) {
            Spacer()

            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 40))
                .foregroundColor(.gray.opacity(0.4))

            Text("No activity on this day")
                .font(.system(size: 16))
                .foregroundColor(.gray)

            Text("Scan ingredients or generate recipes to see them here")
                .font(.system(size: 14))
                .foregroundColor(.gray.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Spacer()
        }
    }
}

#Preview {
    CalendarView()
}

//
//  RecurrenceBuilderView.swift
//  ChoreTracker
//
//  Created on 2025-12-16.
//

import SwiftUI

struct RecurrenceBuilderView: View {
    @Binding var recurrenceRule: RecurrenceRule?
    @Environment(\.dismiss) private var dismiss
    
    @State private var frequency: RecurrenceRule.Frequency = .weekly
    @State private var interval: Int = 1
    @State private var selectedDaysOfWeek: Set<Int> = []
    @State private var dayOfMonth: Int? = nil
    @State private var useDayOfMonthFallback: Bool = false
    @State private var fallbackDay: Int = 30
    @State private var useNthWeekday: Bool = false
    @State private var nthWeekday: Int = 1 // 1-7
    @State private var nth: Int = 1 // 1-5
    @State private var useLastWeekday: Bool = false
    @State private var lastWeekday: Int = 5 // Friday
    @State private var useLastDayOfMonth: Bool = false
    @State private var hasEndDate: Bool = false
    @State private var endDate: Date = Calendar.current.date(byAdding: .month, value: 1, to: Date()) ?? Date()
    @State private var hasOccurrenceCount: Bool = false
    @State private var occurrenceCount: Int = 10
    
    private let weekdays = [
        (1, "Sunday"),
        (2, "Monday"),
        (3, "Tuesday"),
        (4, "Wednesday"),
        (5, "Thursday"),
        (6, "Friday"),
        (7, "Saturday")
    ]
    
    private func getPatternType() -> Int {
        if useLastDayOfMonth { return 0 }
        if useLastWeekday { return 1 }
        if useNthWeekday { return 2 }
        if useDayOfMonthFallback { return 3 }
        return 4
    }
    
    private func setPatternType(_ value: Int) {
        useLastDayOfMonth = (value == 0)
        useLastWeekday = (value == 1)
        useNthWeekday = (value == 2)
        useDayOfMonthFallback = (value == 3)
        if value == 4 {
            useLastDayOfMonth = false
            useLastWeekday = false
            useNthWeekday = false
            useDayOfMonthFallback = false
        }
        updateRecurrenceRule()
    }
    
    var body: some View {
        NavigationStack {
            Form {
                // Frequency Section
                Section("Frequency") {
                    Picker("Repeat", selection: $frequency) {
                        Text("Daily").tag(RecurrenceRule.Frequency.daily)
                        Text("Weekly").tag(RecurrenceRule.Frequency.weekly)
                        Text("Monthly").tag(RecurrenceRule.Frequency.monthly)
                        Text("Yearly").tag(RecurrenceRule.Frequency.yearly)
                    }
                    .onChange(of: frequency) { _, _ in
                        updateRecurrenceRule()
                    }
                    
                    if frequency != .daily {
                        Stepper("Every \(interval) \(frequency == .weekly ? "week" : frequency == .monthly ? "month" : "year")\(interval == 1 ? "" : "s")",
                                value: $interval,
                                in: 1...52)
                        .onChange(of: interval) { _, _ in
                            updateRecurrenceRule()
                        }
                    }
                }
                
                // Weekly Options
                if frequency == .weekly {
                    Section("Days of Week") {
                        ForEach(weekdays, id: \.0) { weekday, name in
                            Toggle(name, isOn: Binding(
                                get: { selectedDaysOfWeek.contains(weekday) },
                                set: { isOn in
                                    if isOn {
                                        selectedDaysOfWeek.insert(weekday)
                                    } else {
                                        selectedDaysOfWeek.remove(weekday)
                                    }
                                    updateRecurrenceRule()
                                }
                            ))
                        }
                    }
                }
                
                // Monthly Options
                if frequency == .monthly {
                    MonthlyPatternSection(
                        useLastDayOfMonth: $useLastDayOfMonth,
                        useLastWeekday: $useLastWeekday,
                        lastWeekday: $lastWeekday,
                        useNthWeekday: $useNthWeekday,
                        nthWeekday: $nthWeekday,
                        nth: $nth,
                        useDayOfMonthFallback: $useDayOfMonthFallback,
                        fallbackDay: $fallbackDay,
                        dayOfMonth: $dayOfMonth,
                        weekdays: weekdays,
                        getPatternType: getPatternType,
                        setPatternType: setPatternType,
                        updateRecurrenceRule: updateRecurrenceRule
                    )
                }
                
                // End Conditions
                Section("End") {
                    Toggle("End date", isOn: $hasEndDate)
                        .onChange(of: hasEndDate) { _, _ in
                            updateRecurrenceRule()
                        }
                    
                    if hasEndDate {
                        DatePicker("End date", selection: $endDate, displayedComponents: .date)
                            .onChange(of: endDate) { _, _ in
                                updateRecurrenceRule()
                            }
                    }
                    
                    Toggle("After \(occurrenceCount) occurrences", isOn: $hasOccurrenceCount)
                        .onChange(of: hasOccurrenceCount) { _, _ in
                            updateRecurrenceRule()
                        }
                    
                    if hasOccurrenceCount {
                        Stepper("Occurrences", value: $occurrenceCount, in: 1...1000)
                            .onChange(of: occurrenceCount) { _, _ in
                                updateRecurrenceRule()
                            }
                    }
                }
                
                // Preview Section
                if let rule = recurrenceRule {
                    PreviewSection(rule: rule)
                }
            }
            .navigationTitle("Recurrence")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        recurrenceRule = nil
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        updateRecurrenceRule()
                        dismiss()
                    }
                }
            }
            .onAppear {
                loadExistingRule()
            }
        }
    }
    
    private func loadExistingRule() {
        guard let rule = recurrenceRule else { return }
        
        frequency = rule.frequency
        interval = rule.interval
        selectedDaysOfWeek = Set(rule.daysOfWeek ?? [])
        dayOfMonth = rule.dayOfMonth
        useDayOfMonthFallback = rule.dayOfMonthWithFallback != nil
        if let fallback = rule.dayOfMonthWithFallback {
            fallbackDay = fallback.day
        }
        useNthWeekday = rule.nthWeekdayOfMonth != nil
        if let nthWeekdayRule = rule.nthWeekdayOfMonth {
            nthWeekday = nthWeekdayRule.weekday
            nth = nthWeekdayRule.nth
        }
        useLastWeekday = rule.lastWeekdayOfMonth != nil
        if let lastWeekdayRule = rule.lastWeekdayOfMonth {
            lastWeekday = lastWeekdayRule.weekday
        }
        useLastDayOfMonth = rule.lastDayOfMonth
        hasEndDate = rule.endDate != nil
        endDate = rule.endDate ?? Calendar.current.date(byAdding: .month, value: 1, to: Date()) ?? Date()
        hasOccurrenceCount = rule.occurrenceCount != nil
        occurrenceCount = rule.occurrenceCount ?? 10
    }
    
    private func updateRecurrenceRule() {
        var rule = RecurrenceRule(frequency: frequency, interval: interval)
        
        // Weekly options
        if frequency == .weekly && !selectedDaysOfWeek.isEmpty {
            rule.daysOfWeek = Array(selectedDaysOfWeek).sorted()
        }
        
        // Monthly options
        if frequency == .monthly {
            if useLastDayOfMonth {
                rule.lastDayOfMonth = true
            } else if useLastWeekday {
                rule.lastWeekdayOfMonth = RecurrenceRule.LastWeekdayOfMonth(weekday: lastWeekday)
            } else if useNthWeekday {
                rule.nthWeekdayOfMonth = RecurrenceRule.NthWeekdayOfMonth(weekday: nthWeekday, nth: nth)
            } else if useDayOfMonthFallback {
                rule.dayOfMonthWithFallback = RecurrenceRule.DayOfMonthFallback(
                    day: fallbackDay,
                    fallbackToLastDay: true
                )
            } else if let day = dayOfMonth {
                rule.dayOfMonth = day
            }
        }
        
        // End conditions
        if hasEndDate {
            rule.endDate = endDate
        }
        
        if hasOccurrenceCount {
            rule.occurrenceCount = occurrenceCount
        }
        
        recurrenceRule = rule
    }
}

// MARK: - Subviews

private struct MonthlyPatternSection: View {
    @Binding var useLastDayOfMonth: Bool
    @Binding var useLastWeekday: Bool
    @Binding var lastWeekday: Int
    @Binding var useNthWeekday: Bool
    @Binding var nthWeekday: Int
    @Binding var nth: Int
    @Binding var useDayOfMonthFallback: Bool
    @Binding var fallbackDay: Int
    @Binding var dayOfMonth: Int?
    let weekdays: [(Int, String)]
    let getPatternType: () -> Int
    let setPatternType: (Int) -> Void
    let updateRecurrenceRule: () -> Void
    
    var body: some View {
        Section("Monthly Pattern") {
            Picker("Pattern Type", selection: Binding(
                get: getPatternType,
                set: setPatternType
            )) {
                Text("Last day of month").tag(0)
                Text("Last weekday of month").tag(1)
                Text("Nth weekday of month").tag(2)
                Text("Day of month (with fallback)").tag(3)
                Text("Specific day of month").tag(4)
            }
            
            if useLastWeekday {
                Picker("Weekday", selection: $lastWeekday) {
                    ForEach(weekdays, id: \.0) { weekday, name in
                        Text(name).tag(weekday)
                    }
                }
                .onChange(of: lastWeekday) { _, _ in
                    updateRecurrenceRule()
                }
            }
            
            if useNthWeekday {
                Picker("Weekday", selection: $nthWeekday) {
                    ForEach(weekdays, id: \.0) { weekday, name in
                        Text(name).tag(weekday)
                    }
                }
                .onChange(of: nthWeekday) { _, _ in updateRecurrenceRule() }
                
                Stepper("Occurrence", value: $nth, in: 1...5)
                    .onChange(of: nth) { _, _ in updateRecurrenceRule() }
                
                Text("\(["", "1st", "2nd", "3rd", "4th", "5th"][nth]) \(weekdays.first(where: { $0.0 == nthWeekday })?.1 ?? "")")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if useDayOfMonthFallback {
                Stepper("Day \(fallbackDay)", value: $fallbackDay, in: 1...31)
                    .onChange(of: fallbackDay) { _, _ in updateRecurrenceRule() }
                Toggle("Fallback to last day if month is shorter", isOn: Binding(
                    get: { useDayOfMonthFallback },
                    set: { _ in updateRecurrenceRule() }
                ))
            }
            
            if !useLastDayOfMonth && !useLastWeekday && !useNthWeekday && !useDayOfMonthFallback {
                Stepper("Day \(dayOfMonth ?? 1)", value: Binding(
                    get: { dayOfMonth ?? 1 },
                    set: { dayOfMonth = $0 }
                ), in: 1...31)
                .onChange(of: dayOfMonth) { _, _ in
                    updateRecurrenceRule()
                }
            }
        }
    }
}

private struct PreviewSection: View {
    let rule: RecurrenceRule
    
    private var previewDates: [Date] {
        RecurrenceEngine.generateNextOccurrences(
            rule: rule,
            startDate: Date(),
            count: 5
        )
    }
    
    var body: some View {
        Section("Preview") {
            Text(RecurrenceEngine.description(for: rule))
                .font(.caption)
                .foregroundColor(.secondary)
            
            if !previewDates.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Next occurrences:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    ForEach(previewDates, id: \.self) { date in
                        Text(date.formatted(date: .abbreviated, time: .omitted))
                            .font(.caption)
                    }
                }
            }
        }
    }
}


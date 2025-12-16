//
//  RecurrenceRule.swift
//  ChoreTracker
//
//  Created on 2025-12-16.
//

import Foundation

/// Represents a recurrence pattern for chore scheduling
struct RecurrenceRule: Codable {
    enum Frequency: String, Codable {
        case daily
        case weekly
        case monthly
        case yearly
        case custom
    }
    
    var frequency: Frequency
    var interval: Int // Every X days/weeks/months
    var daysOfWeek: [Int]? // 1-7 (Sunday-Saturday)
    var dayOfMonth: Int? // 1-31
    var dayOfMonthWithFallback: DayOfMonthFallback?
    var nthWeekdayOfMonth: NthWeekdayOfMonth?
    var lastWeekdayOfMonth: LastWeekdayOfMonth?
    var lastDayOfMonth: Bool
    var endDate: Date?
    var occurrenceCount: Int?
    var skipPattern: String?
    
    struct DayOfMonthFallback: Codable {
        var day: Int // Target day (e.g., 30)
        var fallbackToLastDay: Bool // Use last day if month is shorter
    }
    
    struct NthWeekdayOfMonth: Codable {
        var weekday: Int // 1-7 (Sunday-Saturday)
        var nth: Int // 1-5 (1st, 2nd, 3rd, 4th, 5th)
    }
    
    struct LastWeekdayOfMonth: Codable {
        var weekday: Int // 1-7 (Sunday-Saturday)
    }
    
    init(
        frequency: Frequency = .weekly,
        interval: Int = 1,
        daysOfWeek: [Int]? = nil,
        dayOfMonth: Int? = nil,
        dayOfMonthWithFallback: DayOfMonthFallback? = nil,
        nthWeekdayOfMonth: NthWeekdayOfMonth? = nil,
        lastWeekdayOfMonth: LastWeekdayOfMonth? = nil,
        lastDayOfMonth: Bool = false,
        endDate: Date? = nil,
        occurrenceCount: Int? = nil,
        skipPattern: String? = nil
    ) {
        self.frequency = frequency
        self.interval = interval
        self.daysOfWeek = daysOfWeek
        self.dayOfMonth = dayOfMonth
        self.dayOfMonthWithFallback = dayOfMonthWithFallback
        self.nthWeekdayOfMonth = nthWeekdayOfMonth
        self.lastWeekdayOfMonth = lastWeekdayOfMonth
        self.lastDayOfMonth = lastDayOfMonth
        self.endDate = endDate
        self.occurrenceCount = occurrenceCount
        self.skipPattern = skipPattern
    }
}


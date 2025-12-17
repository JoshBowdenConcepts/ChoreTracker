//
//  RecurrenceEngine.swift
//  ChoreTracker
//
//  Created on 2025-12-16.
//

import Foundation

/// Engine for calculating next occurrence dates from recurrence rules
class RecurrenceEngine {
    
    /// Generates the next occurrence date(s) based on a recurrence rule
    /// - Parameters:
    ///   - rule: The recurrence rule to apply
    ///   - startDate: The starting date (usually the template creation date or last occurrence)
    ///   - afterDate: Generate occurrences after this date (defaults to today)
    ///   - count: Number of occurrences to generate (defaults to 1)
    /// - Returns: Array of next occurrence dates
    static func generateNextOccurrences(
        rule: RecurrenceRule,
        startDate: Date,
        afterDate: Date = Date(),
        count: Int = 1
    ) -> [Date] {
        var occurrences: [Date] = []
        var currentDate = startDate
        let calendar = Calendar.current
        
        // Adjust currentDate to be after afterDate
        if currentDate <= afterDate {
            currentDate = calendar.date(byAdding: .day, value: 1, to: afterDate) ?? afterDate
        }
        
        // Check for end conditions
        if let endDate = rule.endDate, currentDate > endDate {
            return []
        }
        
        if let occurrenceCount = rule.occurrenceCount, occurrenceCount <= 0 {
            return []
        }
        
        while occurrences.count < count {
            // Check end conditions
            if let endDate = rule.endDate, currentDate > endDate {
                break
            }
            
            if let occurrenceCount = rule.occurrenceCount,
               occurrences.count >= occurrenceCount {
                break
            }
            
            // Generate next date based on frequency
            let nextDate = generateNextDate(
                rule: rule,
                from: currentDate,
                startDate: startDate
            )
            
            if let nextDate = nextDate {
                occurrences.append(nextDate)
                currentDate = calendar.date(byAdding: .day, value: 1, to: nextDate) ?? nextDate
            } else {
                break
            }
        }
        
        return occurrences
    }
    
    /// Generates the next single occurrence date
    private static func generateNextDate(
        rule: RecurrenceRule,
        from currentDate: Date,
        startDate: Date
    ) -> Date? {
        switch rule.frequency {
        case .daily:
            return generateDailyDate(rule: rule, from: currentDate, startDate: startDate)
            
        case .weekly:
            return generateWeeklyDate(rule: rule, from: currentDate, startDate: startDate)
            
        case .monthly:
            return generateMonthlyDate(rule: rule, from: currentDate, startDate: startDate)
            
        case .yearly:
            return generateYearlyDate(rule: rule, from: currentDate, startDate: startDate)
            
        case .custom:
            // Custom patterns would be handled here
            return nil
        }
    }
    
    // MARK: - Daily Patterns
    
    private static func generateDailyDate(
        rule: RecurrenceRule,
        from currentDate: Date,
        startDate: Date
    ) -> Date? {
        let calendar = Calendar.current
        let date = currentDate
        
        // Every X days
        let daysSinceStart = calendar.dateComponents([.day], from: startDate, to: date).day ?? 0
        
        if daysSinceStart % rule.interval == 0 {
            return date
        }
        
        // Find next valid date
        let remainder = daysSinceStart % rule.interval
        let daysToAdd = rule.interval - remainder
        
        return calendar.date(byAdding: .day, value: daysToAdd, to: date)
    }
    
    // MARK: - Weekly Patterns
    
    private static func generateWeeklyDate(
        rule: RecurrenceRule,
        from currentDate: Date,
        startDate: Date
    ) -> Date? {
        let calendar = Calendar.current
        let date = currentDate
        
        // If specific days of week are specified
        if let daysOfWeek = rule.daysOfWeek, !daysOfWeek.isEmpty {
            return findNextWeekday(rule: rule, from: date, daysOfWeek: daysOfWeek)
        }
        
        // Otherwise, every X weeks on the same weekday as start date
        let startWeekday = calendar.component(.weekday, from: startDate)
        let currentWeekday = calendar.component(.weekday, from: date)
        
        // Find next occurrence of the start weekday
        var daysToAdd = (startWeekday - currentWeekday + 7) % 7
        if daysToAdd == 0 {
            // Check if we need to skip to next interval
            let weeksSinceStart = calendar.dateComponents([.weekOfYear], from: startDate, to: date).weekOfYear ?? 0
            if weeksSinceStart % rule.interval != 0 {
                daysToAdd = 7 * rule.interval
            } else {
                daysToAdd = 7 * rule.interval
            }
        }
        
        if let nextDate = calendar.date(byAdding: .day, value: daysToAdd, to: date) {
            return nextDate
        }
        
        return nil
    }
    
    private static func findNextWeekday(
        rule: RecurrenceRule,
        from date: Date,
        daysOfWeek: [Int]
    ) -> Date? {
        let calendar = Calendar.current
        var currentDate = date
        
        // Check up to 2 weeks ahead
        for _ in 0..<14 {
            let weekday = calendar.component(.weekday, from: currentDate)
            
            if daysOfWeek.contains(weekday) {
                // Check if this matches the interval
                let weeksSinceStart = calendar.dateComponents([.weekOfYear], from: date, to: currentDate).weekOfYear ?? 0
                if weeksSinceStart % rule.interval == 0 {
                    return currentDate
                }
            }
            
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        }
        
        return nil
    }
    
    // MARK: - Monthly Patterns
    
    private static func generateMonthlyDate(
        rule: RecurrenceRule,
        from currentDate: Date,
        startDate: Date
    ) -> Date? {
        let calendar = Calendar.current
        
        // Last day of month
        if rule.lastDayOfMonth {
            return findNextLastDayOfMonth(from: currentDate, interval: rule.interval, startDate: startDate)
        }
        
        // Last weekday of month
        if let lastWeekday = rule.lastWeekdayOfMonth {
            return findNextLastWeekdayOfMonth(
                weekday: lastWeekday.weekday,
                from: currentDate,
                interval: rule.interval,
                startDate: startDate
            )
        }
        
        // Nth weekday of month (e.g., 3rd Monday)
        if let nthWeekday = rule.nthWeekdayOfMonth {
            return findNextNthWeekdayOfMonth(
                weekday: nthWeekday.weekday,
                nth: nthWeekday.nth,
                from: currentDate,
                interval: rule.interval,
                startDate: startDate
            )
        }
        
        // Day of month with fallback
        if let fallback = rule.dayOfMonthWithFallback {
            return findNextDayOfMonthWithFallback(
                day: fallback.day,
                fallbackToLastDay: fallback.fallbackToLastDay,
                from: currentDate,
                interval: rule.interval,
                startDate: startDate
            )
        }
        
        // Simple day of month
        if let dayOfMonth = rule.dayOfMonth {
            return findNextDayOfMonth(
                day: dayOfMonth,
                from: currentDate,
                interval: rule.interval,
                startDate: startDate
            )
        }
        
        // Default: same day of month as start date
        let startDay = calendar.component(.day, from: startDate)
        return findNextDayOfMonth(
            day: startDay,
            from: currentDate,
            interval: rule.interval,
            startDate: startDate
        )
    }
    
    private static func findNextDayOfMonth(
        day: Int,
        from currentDate: Date,
        interval: Int,
        startDate: Date
    ) -> Date? {
        let calendar = Calendar.current
        var date = currentDate
        
        // Check up to 12 months ahead
        for _ in 0..<12 {
            // Get the target month
            let components = calendar.dateComponents([.year, .month], from: date)
            guard let monthStart = calendar.date(from: components) else { break }
            
            // Get last day of month
            let range = calendar.range(of: .day, in: .month, for: monthStart)
            let lastDay = range?.count ?? 31
            let targetDay = min(day, lastDay)
            
            if let targetDate = calendar.date(bySetting: .day, value: targetDay, of: monthStart),
               targetDate >= currentDate {
                // Check interval
                let monthsSinceStart = calendar.dateComponents([.month], from: startDate, to: targetDate).month ?? 0
                if monthsSinceStart % interval == 0 {
                    return targetDate
                }
            }
            
            // Move to next month
            date = calendar.date(byAdding: .month, value: 1, to: date) ?? date
        }
        
        return nil
    }
    
    private static func findNextDayOfMonthWithFallback(
        day: Int,
        fallbackToLastDay: Bool,
        from currentDate: Date,
        interval: Int,
        startDate: Date
    ) -> Date? {
        let calendar = Calendar.current
        var date = currentDate
        
        for _ in 0..<12 {
            let components = calendar.dateComponents([.year, .month], from: date)
            guard let monthStart = calendar.date(from: components) else { break }
            
            let range = calendar.range(of: .day, in: .month, for: monthStart)
            let lastDay = range?.count ?? 31
            
            let targetDay: Int
            if day > lastDay && fallbackToLastDay {
                targetDay = lastDay
            } else if day <= lastDay {
                targetDay = day
            } else {
                // Month is too short and no fallback
                date = calendar.date(byAdding: .month, value: 1, to: date) ?? date
                continue
            }
            
            if let targetDate = calendar.date(bySetting: .day, value: targetDay, of: monthStart),
               targetDate >= currentDate {
                let monthsSinceStart = calendar.dateComponents([.month], from: startDate, to: targetDate).month ?? 0
                if monthsSinceStart % interval == 0 {
                    return targetDate
                }
            }
            
            date = calendar.date(byAdding: .month, value: 1, to: date) ?? date
        }
        
        return nil
    }
    
    private static func findNextLastDayOfMonth(
        from currentDate: Date,
        interval: Int,
        startDate: Date
    ) -> Date? {
        let calendar = Calendar.current
        var date = currentDate
        
        for _ in 0..<12 {
            let components = calendar.dateComponents([.year, .month], from: date)
            guard let monthStart = calendar.date(from: components) else { break }
            
            let range = calendar.range(of: .day, in: .month, for: monthStart)
            let lastDay = range?.count ?? 31
            
            if let lastDate = calendar.date(bySetting: .day, value: lastDay, of: monthStart),
               lastDate >= currentDate {
                let monthsSinceStart = calendar.dateComponents([.month], from: startDate, to: lastDate).month ?? 0
                if monthsSinceStart % interval == 0 {
                    return lastDate
                }
            }
            
            date = calendar.date(byAdding: .month, value: 1, to: date) ?? date
        }
        
        return nil
    }
    
    private static func findNextNthWeekdayOfMonth(
        weekday: Int,
        nth: Int,
        from currentDate: Date,
        interval: Int,
        startDate: Date
    ) -> Date? {
        let calendar = Calendar.current
        var date = currentDate
        
        for _ in 0..<12 {
            let components = calendar.dateComponents([.year, .month], from: date)
            guard let monthStart = calendar.date(from: components) else { break }
            
            // Find nth occurrence of weekday in month
            var foundCount = 0
            var currentDay = monthStart
            
            while let day = calendar.date(byAdding: .day, value: 1, to: currentDay),
                  calendar.component(.month, from: day) == calendar.component(.month, from: monthStart) {
                let dayWeekday = calendar.component(.weekday, from: day)
                if dayWeekday == weekday {
                    foundCount += 1
                    if foundCount == nth {
                        if day >= currentDate {
                            let monthsSinceStart = calendar.dateComponents([.month], from: startDate, to: day).month ?? 0
                            if monthsSinceStart % interval == 0 {
                                return day
                            }
                        }
                        break
                    }
                }
                currentDay = day
            }
            
            date = calendar.date(byAdding: .month, value: 1, to: date) ?? date
        }
        
        return nil
    }
    
    private static func findNextLastWeekdayOfMonth(
        weekday: Int,
        from currentDate: Date,
        interval: Int,
        startDate: Date
    ) -> Date? {
        let calendar = Calendar.current
        var date = currentDate
        
        for _ in 0..<12 {
            let components = calendar.dateComponents([.year, .month], from: date)
            guard let monthStart = calendar.date(from: components) else { break }
            
            let range = calendar.range(of: .day, in: .month, for: monthStart)
            let lastDay = range?.count ?? 31
            
            // Find last occurrence of weekday in month
            var lastWeekdayDate: Date?
            for day in 1...lastDay {
                if let dayDate = calendar.date(bySetting: .day, value: day, of: monthStart),
                   calendar.component(.weekday, from: dayDate) == weekday {
                    lastWeekdayDate = dayDate
                }
            }
            
            if let lastDate = lastWeekdayDate, lastDate >= currentDate {
                let monthsSinceStart = calendar.dateComponents([.month], from: startDate, to: lastDate).month ?? 0
                if monthsSinceStart % interval == 0 {
                    return lastDate
                }
            }
            
            date = calendar.date(byAdding: .month, value: 1, to: date) ?? date
        }
        
        return nil
    }
    
    // MARK: - Yearly Patterns
    
    private static func generateYearlyDate(
        rule: RecurrenceRule,
        from currentDate: Date,
        startDate: Date
    ) -> Date? {
        let calendar = Calendar.current
        var date = currentDate
        
        // Get start date components
        let startComponents = calendar.dateComponents([.month, .day], from: startDate)
        
        for _ in 0..<10 {
            let year = calendar.component(.year, from: date)
            
            if let targetDate = calendar.date(from: DateComponents(
                year: year,
                month: startComponents.month,
                day: startComponents.day
            )), targetDate >= currentDate {
                let yearsSinceStart = calendar.dateComponents([.year], from: startDate, to: targetDate).year ?? 0
                if yearsSinceStart % rule.interval == 0 {
                    return targetDate
                }
            }
            
            date = calendar.date(byAdding: .year, value: 1, to: date) ?? date
        }
        
        return nil
    }
    
    // MARK: - Helper Methods
    
    /// Gets a human-readable description of a recurrence rule
    static func description(for rule: RecurrenceRule) -> String {
        var parts: [String] = []
        
        switch rule.frequency {
        case .daily:
            if rule.interval == 1 {
                parts.append("Daily")
            } else {
                parts.append("Every \(rule.interval) days")
            }
            
        case .weekly:
            if let daysOfWeek = rule.daysOfWeek, !daysOfWeek.isEmpty {
                let dayNames = daysOfWeek.map { weekdayName($0) }.joined(separator: ", ")
                if rule.interval == 1 {
                    parts.append("Weekly on \(dayNames)")
                } else {
                    parts.append("Every \(rule.interval) weeks on \(dayNames)")
                }
            } else {
                if rule.interval == 1 {
                    parts.append("Weekly")
                } else {
                    parts.append("Every \(rule.interval) weeks")
                }
            }
            
        case .monthly:
            if rule.lastDayOfMonth {
                parts.append("Last day of every \(rule.interval == 1 ? "" : "\(rule.interval) ")month\(rule.interval == 1 ? "" : "s")")
            } else if let lastWeekday = rule.lastWeekdayOfMonth {
                parts.append("Last \(weekdayName(lastWeekday.weekday)) of every \(rule.interval == 1 ? "" : "\(rule.interval) ")month\(rule.interval == 1 ? "" : "s")")
            } else if let nthWeekday = rule.nthWeekdayOfMonth {
                let nth = ["", "1st", "2nd", "3rd", "4th", "5th"][nthWeekday.nth]
                parts.append("\(nth) \(weekdayName(nthWeekday.weekday)) of every \(rule.interval == 1 ? "" : "\(rule.interval) ")month\(rule.interval == 1 ? "" : "s")")
            } else if let fallback = rule.dayOfMonthWithFallback {
                parts.append("Day \(fallback.day) of every \(rule.interval == 1 ? "" : "\(rule.interval) ")month\(rule.interval == 1 ? "" : "s")")
                if fallback.fallbackToLastDay {
                    parts.append("(or last day if shorter)")
                }
            } else if let dayOfMonth = rule.dayOfMonth {
                parts.append("Day \(dayOfMonth) of every \(rule.interval == 1 ? "" : "\(rule.interval) ")month\(rule.interval == 1 ? "" : "s")")
            } else {
                parts.append("Monthly")
            }
            
        case .yearly:
            if rule.interval == 1 {
                parts.append("Yearly")
            } else {
                parts.append("Every \(rule.interval) years")
            }
            
        case .custom:
            parts.append("Custom pattern")
        }
        
        if let endDate = rule.endDate {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            parts.append("until \(formatter.string(from: endDate))")
        }
        
        if let occurrenceCount = rule.occurrenceCount {
            parts.append("(\(occurrenceCount) occurrences)")
        }
        
        return parts.joined(separator: " ")
    }
    
    private static func weekdayName(_ weekday: Int) -> String {
        let names = ["", "Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
        if weekday >= 0 && weekday < names.count {
            return names[weekday]
        }
        return "Day \(weekday)"
    }
}


//
//  DateExtensions.swift
//  ChoreTracker
//
//  Created on 2025-12-16.
//

import Foundation

extension Date {
    /// Formats date for display in chore lists
    func formattedForChoreList() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: self)
    }
    
    /// Formats date for display (date only)
    func formattedDateOnly() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: self)
    }
    
    /// Checks if date is today
    var isToday: Bool {
        Calendar.current.isDateInToday(self)
    }
    
    /// Checks if date is overdue
    var isOverdue: Bool {
        self < Date() && !isToday
    }
    
    /// Returns start of day
    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }
    
    /// Returns end of day
    var endOfDay: Date {
        var components = DateComponents()
        components.day = 1
        components.second = -1
        return Calendar.current.date(byAdding: components, to: startOfDay) ?? self
    }
}

extension TimeInterval {
    /// Formats time interval as human-readable string (e.g., "5 minutes", "1 hour")
    func formattedDuration() -> String {
        let hours = Int(self) / 3600
        let minutes = (Int(self) % 3600) / 60
        
        if hours > 0 {
            if minutes > 0 {
                return "\(hours)h \(minutes)m"
            }
            return "\(hours) hour\(hours == 1 ? "" : "s")"
        } else if minutes > 0 {
            return "\(minutes) minute\(minutes == 1 ? "" : "s")"
        } else {
            return "Less than a minute"
        }
    }
}


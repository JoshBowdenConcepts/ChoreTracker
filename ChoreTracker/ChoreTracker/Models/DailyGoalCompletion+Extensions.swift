//
//  DailyGoalCompletion+Extensions.swift
//  ChoreTracker
//
//  Created on 2025-12-16.
//

import Foundation
import CoreData

extension DailyGoalCompletion {
    
    // MARK: - Convenience Methods
    
    /// Creates a new DailyGoalCompletion instance
    public static func create(
        context: NSManagedObjectContext,
        user: User,
        date: Date,
        allChoresCompleted: Bool,
        totalChoresCount: Int,
        completedChoresCount: Int,
        totalTimeSpent: TimeInterval
    ) -> DailyGoalCompletion {
        let goal = DailyGoalCompletion(context: context)
        goal.id = UUID()
        goal.user = user
        goal.date = Calendar.current.startOfDay(for: date)
        goal.allChoresCompleted = allChoresCompleted
        goal.totalChoresCount = Int16(totalChoresCount)
        goal.completedChoresCount = Int16(completedChoresCount)
        goal.totalTimeSpent = totalTimeSpent
        goal.createdAt = Date()
        return goal
    }
}


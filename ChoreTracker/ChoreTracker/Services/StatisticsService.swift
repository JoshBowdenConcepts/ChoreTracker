//
//  StatisticsService.swift
//  ChoreTracker
//
//  Created on 2025-12-16.
//

import Foundation
import CoreData

/// Service for calculating statistics and tracking daily goals
/// All statistics are personal to the family, stored in iCloud, never sent externally
class StatisticsService {
    static let shared = StatisticsService()
    
    private init() {}
    
    // MARK: - Big Number Metrics
    
    /// Calculates total chores completed for a user
    func totalChoresCompleted(for user: User, context: NSManagedObjectContext) throws -> Int {
        let request: NSFetchRequest<ChoreInstance> = ChoreInstance.fetchRequest()
        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            NSPredicate(format: "status == %@", "completed"),
            NSPredicate(format: "completedBy == %@", user)
        ])
        return try context.count(for: request)
    }
    
    /// Calculates total time spent for a user
    func totalTimeSpent(for user: User, context: NSManagedObjectContext) throws -> TimeInterval {
        let request: NSFetchRequest<ChoreInstance> = ChoreInstance.fetchRequest()
        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            NSPredicate(format: "status == %@", "completed"),
            NSPredicate(format: "completedBy == %@", user)
        ])
        
        let instances = try context.fetch(request)
        return instances.reduce(0.0) { $0 + $1.actualDuration }
    }
    
    /// Gets current goal streak for a user
    func currentGoalStreak(for user: User) -> Int {
        return Int(user.currentGoalStreak)
    }
    
    /// Gets longest goal streak for a user
    func longestGoalStreak(for user: User) -> Int {
        return Int(user.longestGoalStreak)
    }
    
    // MARK: - Daily Goal Tracking
    
    /// Checks if all assigned chores for a date are completed and updates goal completion
    func checkAndUpdateDailyGoal(
        for user: User,
        date: Date,
        context: NSManagedObjectContext
    ) throws {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        // Get all chores assigned to user that are due on this date
        let request: NSFetchRequest<ChoreInstance> = ChoreInstance.fetchRequest()
        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            NSPredicate(format: "template.assignedTo == %@", user),
            NSPredicate(format: "dueDate >= %@", startOfDay as NSDate),
            NSPredicate(format: "dueDate < %@", endOfDay as NSDate)
        ])
        
        let instances = try context.fetch(request)
        let totalCount = instances.count
        let completedCount = instances.filter { $0.status == "completed" }.count
        let allCompleted = totalCount > 0 && completedCount == totalCount
        
        // Calculate total time spent
        let totalTime = instances
            .filter { $0.status == "completed" }
            .reduce(0.0) { $0 + $1.actualDuration }
        
        // Get or create DailyGoalCompletion for this date
        let goalRequest: NSFetchRequest<DailyGoalCompletion> = DailyGoalCompletion.fetchRequest()
        goalRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            NSPredicate(format: "user == %@", user),
            NSPredicate(format: "date >= %@", startOfDay as NSDate),
            NSPredicate(format: "date < %@", endOfDay as NSDate)
        ])
        
        let existingGoals = try context.fetch(goalRequest)
        let goal: DailyGoalCompletion
        
        if let existing = existingGoals.first {
            goal = existing
        } else {
            goal = DailyGoalCompletion(context: context)
            goal.id = UUID()
            goal.user = user
            goal.date = startOfDay
            goal.createdAt = Date()
        }
        
        goal.allChoresCompleted = allCompleted
        goal.totalChoresCount = Int16(totalCount)
        goal.completedChoresCount = Int16(completedCount)
        goal.totalTimeSpent = totalTime
        
        // Update streak if goal was achieved
        if allCompleted {
            updateStreak(for: user, date: date, context: context)
        } else {
            // Reset streak if goal was missed
            resetStreakIfNeeded(for: user, date: date, context: context)
        }
        
        try context.save()
    }
    
    // MARK: - Streak Management
    
    private func updateStreak(for user: User, date: Date, context: NSManagedObjectContext) {
        let calendar = Calendar.current
        let lastCompletionDate = user.lastGoalCompletionDate
        
        if let lastDate = lastCompletionDate {
            let daysSince = calendar.dateComponents([.day], from: calendar.startOfDay(for: lastDate), to: calendar.startOfDay(for: date)).day ?? 0
            
            if daysSince == 1 {
                // Consecutive day - increment streak
                user.currentGoalStreak += 1
            } else if daysSince > 1 {
                // Gap in streak - reset to 1
                user.currentGoalStreak = 1
            }
            // If daysSince == 0, same day - don't change streak
        } else {
            // First completion
            user.currentGoalStreak = 1
        }
        
        // Update longest streak if needed
        if user.currentGoalStreak > user.longestGoalStreak {
            user.longestGoalStreak = user.currentGoalStreak
        }
        
        user.lastGoalCompletionDate = calendar.startOfDay(for: date)
    }
    
    private func resetStreakIfNeeded(for user: User, date: Date, context: NSManagedObjectContext) {
        let calendar = Calendar.current
        let lastCompletionDate = user.lastGoalCompletionDate
        
        if let lastDate = lastCompletionDate {
            let daysSince = calendar.dateComponents([.day], from: calendar.startOfDay(for: lastDate), to: calendar.startOfDay(for: date)).day ?? 0
            
            // If it's been more than 1 day since last completion, reset streak
            if daysSince > 1 {
                user.currentGoalStreak = 0
            }
        }
    }
    
    // MARK: - Completion Rates
    
    /// Calculates completion rate for a user (percentage of completed chores)
    func completionRate(for user: User, context: NSManagedObjectContext) throws -> Double {
        let request: NSFetchRequest<ChoreInstance> = ChoreInstance.fetchRequest()
        request.predicate = NSPredicate(format: "template.assignedTo == %@", user)
        
        let instances = try context.fetch(request)
        guard !instances.isEmpty else { return 0.0 }
        
        let completed = instances.filter { $0.status == "completed" }.count
        return Double(completed) / Double(instances.count) * 100.0
    }
    
    /// Calculates average time to complete chores for a user
    func averageCompletionTime(for user: User, context: NSManagedObjectContext) throws -> TimeInterval {
        let request: NSFetchRequest<ChoreInstance> = ChoreInstance.fetchRequest()
        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            NSPredicate(format: "status == %@", "completed"),
            NSPredicate(format: "completedBy == %@", user),
            NSPredicate(format: "actualDuration > 0")
        ])
        
        let instances = try context.fetch(request)
        guard !instances.isEmpty else { return 0.0 }
        
        let totalTime = instances.reduce(0.0) { $0 + $1.actualDuration }
        return totalTime / Double(instances.count)
    }
    
    // MARK: - Goal Completion History
    
    /// Fetches goal completion history for a user within a date range
    func fetchGoalCompletions(
        for user: User,
        from startDate: Date,
        to endDate: Date,
        context: NSManagedObjectContext
    ) throws -> [DailyGoalCompletion] {
        let request: NSFetchRequest<DailyGoalCompletion> = DailyGoalCompletion.fetchRequest()
        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            NSPredicate(format: "user == %@", user),
            NSPredicate(format: "date >= %@", startDate as NSDate),
            NSPredicate(format: "date <= %@", endDate as NSDate)
        ])
        request.sortDescriptors = [NSSortDescriptor(keyPath: \DailyGoalCompletion.date, ascending: true)]
        return try context.fetch(request)
    }
}






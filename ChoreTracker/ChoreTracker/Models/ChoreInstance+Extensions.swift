//
//  ChoreInstance+Extensions.swift
//  ChoreTracker
//
//  Created on 2025-12-16.
//

import Foundation
import CoreData

extension ChoreInstance {
    
    // MARK: - Convenience Methods
    
    /// Creates a new ChoreInstance
    public static func create(context: NSManagedObjectContext, template: ChoreTemplate, dueDate: Date) -> ChoreInstance {
        let instance = ChoreInstance(context: context)
        instance.id = UUID()
        instance.template = template
        instance.dueDate = dueDate
        instance.status = "pending"
        instance.requiresReview = false
        instance.createdAt = Date()
        return instance
    }
    
    /// Marks the instance as complete
    func markComplete(by user: User, duration: TimeInterval? = nil) {
        completedAt = Date()
        completedBy = user
        status = requiresReview ? "pending_review" : "completed"
        actualDuration = duration ?? 0.0
    }
    
    /// Marks the instance as skipped
    func markSkipped() {
        status = "skipped"
        completedAt = nil
    }
    
    // MARK: - Computed Properties
    
    /// Checks if the instance is overdue
    var isOverdue: Bool {
        guard let dueDate = dueDate else { return false }
        return status == "pending" && dueDate < Date()
    }
    
    // MARK: - Helper Properties
    
    /// Convenience accessor for actualDuration as TimeInterval
    var actualDurationValue: TimeInterval? {
        get {
            return actualDuration
        }
        set {
            actualDuration = newValue ?? 0.0
        }
    }
}


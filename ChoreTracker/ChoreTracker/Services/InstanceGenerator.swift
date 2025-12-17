//
//  InstanceGenerator.swift
//  ChoreTracker
//
//  Created on 2025-12-16.
//

import Foundation
import CoreData

/// Service for automatically generating ChoreInstance records from ChoreTemplate recurrence rules
class InstanceGenerator {
    
    /// Generates ChoreInstance records for a template based on its recurrence rule
    /// - Parameters:
    ///   - template: The ChoreTemplate to generate instances for
    ///   - context: Core Data context
    ///   - lookAheadDays: How many days ahead to generate instances (default: 90)
    /// - Returns: Array of created ChoreInstance records
    @discardableResult
    static func generateInstances(
        for template: ChoreTemplate,
        context: NSManagedObjectContext,
        lookAheadDays: Int = 90
    ) throws -> [ChoreInstance] {
        // Check if template has a recurrence rule
        guard let recurrenceRule = template.recurrenceRule else {
            return []
        }
        
        // Get existing instances to avoid duplicates
        let existingInstances = template.instances?.allObjects as? [ChoreInstance] ?? []
        let existingDueDates = Set(existingInstances.compactMap { $0.dueDate })
        
        // Determine start date (use template creation date or today, whichever is later)
        let startDate = template.createdAt ?? Date()
        let today = Date()
        let afterDate = max(startDate, today)
        
        // Calculate end date for generation
        let calendar = Calendar.current
        guard let endDate = calendar.date(byAdding: .day, value: lookAheadDays, to: afterDate) else {
            return []
        }
        
        // Generate next occurrences
        var occurrences = RecurrenceEngine.generateNextOccurrences(
            rule: recurrenceRule,
            startDate: startDate,
            afterDate: afterDate,
            count: 1000 // Generate many, we'll filter by date
        )
        
        // Filter to only dates within lookAheadDays
        occurrences = occurrences.filter { $0 <= endDate }
        
        // Create instances for new dates only
        var createdInstances: [ChoreInstance] = []
        
        for occurrenceDate in occurrences {
            // Skip if instance already exists for this date
            if existingDueDates.contains(occurrenceDate) {
                continue
            }
            
            // Create new instance
            let instance = ChoreInstance.create(
                context: context,
                template: template,
                dueDate: occurrenceDate
            )
            
            // Schedule notification for the new instance
            let notificationService = NotificationService.shared
            notificationService.scheduleNotification(for: instance, reminderMinutesBefore: 60)
            
            createdInstances.append(instance)
        }
        
        // Save context
        if !createdInstances.isEmpty {
            try context.save()
        }
        
        return createdInstances
    }
    
    /// Generates instances for all active templates that have recurrence rules
    /// - Parameters:
    ///   - context: Core Data context
    ///   - lookAheadDays: How many days ahead to generate instances (default: 90)
    static func generateInstancesForAllTemplates(
        context: NSManagedObjectContext,
        lookAheadDays: Int = 90
    ) throws {
        let request: NSFetchRequest<ChoreTemplate> = ChoreTemplate.fetchRequest()
        request.predicate = NSPredicate(format: "isActive == YES")
        
        let templates = try context.fetch(request)
        
        for template in templates {
            if template.recurrenceRule != nil {
                try generateInstances(
                    for: template,
                    context: context,
                    lookAheadDays: lookAheadDays
                )
            }
        }
    }
    
    /// Checks if a template needs new instances generated
    /// - Parameter template: The ChoreTemplate to check
    /// - Returns: True if new instances should be generated
    static func needsInstanceGeneration(for template: ChoreTemplate) -> Bool {
        guard template.recurrenceRule != nil else {
            return false
        }
        
        let existingInstances = template.instances?.allObjects as? [ChoreInstance] ?? []
        let pendingInstances = existingInstances.filter { $0.status == "pending" }
        
        // If we have pending instances, we might not need to generate more yet
        // But if we're running low (less than 7 days of instances), generate more
        let calendar = Calendar.current
        let today = Date()
        let weekFromNow = calendar.date(byAdding: .day, value: 7, to: today) ?? today
        
        let upcomingInstances = pendingInstances.filter { instance in
            guard let dueDate = instance.dueDate else { return false }
            return dueDate >= today && dueDate <= weekFromNow
        }
        
        // If we have less than 3 upcoming instances, generate more
        return upcomingInstances.count < 3
    }
}


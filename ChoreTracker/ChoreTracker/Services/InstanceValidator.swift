//
//  InstanceValidator.swift
//  ChoreTracker
//
//  Created on 2025-12-16.
//

import Foundation
import CoreData

/// Service for validating and fixing chore instance schedules
class InstanceValidator {
    
    /// Validation result for a template's instances
    struct ValidationResult {
        let template: ChoreTemplate
        let expectedInstances: [Date]
        let actualInstances: [ChoreInstance]
        let missingDates: [Date]
        let duplicateDates: [Date]
        let extraInstances: [ChoreInstance]
        let isValid: Bool
    }
    
    /// Validates instances for a template against its recurrence rule
    static func validateInstances(
        for template: ChoreTemplate,
        context: NSManagedObjectContext,
        lookAheadDays: Int = 90
    ) -> ValidationResult {
        guard let recurrenceRule = template.recurrenceRule else {
            // No recurrence rule, so validation passes
            return ValidationResult(
                template: template,
                expectedInstances: [],
                actualInstances: [],
                missingDates: [],
                duplicateDates: [],
                extraInstances: [],
                isValid: true
            )
        }
        
        // Get all existing instances for this template
        let fetchRequest: NSFetchRequest<ChoreInstance> = ChoreInstance.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "template == %@", template)
        let existingInstances = (try? context.fetch(fetchRequest)) ?? []
        
        // Also check unsaved instances
        let insertedObjects = context.insertedObjects.compactMap { $0 as? ChoreInstance }
        let unsavedInstances = insertedObjects.filter { $0.template == template }
        let allInstances = existingInstances + unsavedInstances
        
        // Calculate what instances should exist
        let startDate = template.createdAt ?? Date()
        let today = Date()
        let afterDate = max(startDate, today)
        let calendar = Calendar.current
        guard let endDate = calendar.date(byAdding: .day, value: lookAheadDays, to: afterDate) else {
            return ValidationResult(
                template: template,
                expectedInstances: [],
                actualInstances: allInstances,
                missingDates: [],
                duplicateDates: [],
                extraInstances: [],
                isValid: true
            )
        }
        
        let expectedDates = RecurrenceEngine.generateNextOccurrences(
            rule: recurrenceRule,
            startDate: startDate,
            afterDate: afterDate,
            count: 1000
        ).filter { $0 <= endDate }
        
        // Normalize dates to day-level for comparison
        let expectedDays = Set(expectedDates.map { calendar.startOfDay(for: $0) })
        
        // Group instances by day
        var instancesByDay: [Date: [ChoreInstance]] = [:]
        for instance in allInstances {
            guard let dueDate = instance.dueDate else { continue }
            let day = calendar.startOfDay(for: dueDate)
            instancesByDay[day, default: []].append(instance)
        }
        
        // Find missing dates
        let actualDays = Set(instancesByDay.keys)
        let missingDays = expectedDays.subtracting(actualDays)
        let missingDates = Array(missingDays).sorted()
        
        // Find duplicates (days with more than one instance)
        var duplicateDays: [Date] = []
        for (day, instances) in instancesByDay {
            if instances.count > 1 {
                duplicateDays.append(day)
            }
        }
        duplicateDays.sort()
        
        // Find extra instances (instances for dates that shouldn't exist)
        let extraDays = actualDays.subtracting(expectedDays)
        let extraInstances = extraDays.flatMap { day in
            instancesByDay[day] ?? []
        }
        
        let isValid = missingDates.isEmpty && duplicateDays.isEmpty && extraInstances.isEmpty
        
        return ValidationResult(
            template: template,
            expectedInstances: expectedDates.sorted(),
            actualInstances: allInstances,
            missingDates: missingDates,
            duplicateDates: duplicateDays,
            extraInstances: extraInstances,
            isValid: isValid
        )
    }
    
    /// Fixes validation issues for a template
    static func fixValidationIssues(
        for template: ChoreTemplate,
        context: NSManagedObjectContext,
        lookAheadDays: Int = 90
    ) throws {
        let result = validateInstances(for: template, context: context, lookAheadDays: lookAheadDays)
        
        // Remove duplicate instances (keep the first one, delete the rest)
        let calendar = Calendar.current
        for duplicateDay in result.duplicateDates {
            let instances = result.actualInstances.filter { instance in
                guard let dueDate = instance.dueDate else { return false }
                let day = calendar.startOfDay(for: dueDate)
                return calendar.isDate(day, inSameDayAs: duplicateDay)
            }
            
            // Keep the first instance, delete the rest
            if instances.count > 1 {
                for instance in instances.dropFirst() {
                    context.delete(instance)
                }
            }
        }
        
        // Remove extra instances (instances for dates that shouldn't exist)
        for extraInstance in result.extraInstances {
            context.delete(extraInstance)
        }
        
        // Generate missing instances
        if !result.missingDates.isEmpty {
            for missingDate in result.missingDates {
                let instance = ChoreInstance.create(
                    context: context,
                    template: template,
                    dueDate: missingDate
                )
                
                // Schedule notification
                let notificationService = NotificationService.shared
                notificationService.scheduleNotification(for: instance, reminderMinutesBefore: 60)
            }
        }
        
        try context.save()
    }
    
    /// Validates all templates and returns results
    static func validateAllTemplates(
        context: NSManagedObjectContext,
        lookAheadDays: Int = 90
    ) -> [ValidationResult] {
        let fetchRequest: NSFetchRequest<ChoreTemplate> = ChoreTemplate.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "isActive == YES")
        
        guard let templates = try? context.fetch(fetchRequest) else {
            return []
        }
        
        return templates.map { template in
            validateInstances(for: template, context: context, lookAheadDays: lookAheadDays)
        }
    }
}






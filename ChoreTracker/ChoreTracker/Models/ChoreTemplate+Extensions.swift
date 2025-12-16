//
//  ChoreTemplate+Extensions.swift
//  ChoreTracker
//
//  Created on 2025-12-16.
//

import Foundation
import CoreData

extension ChoreTemplate {
    
    // MARK: - Convenience Methods
    
    /// Creates a new ChoreTemplate instance
    public static func create(context: NSManagedObjectContext, name: String, description: String? = nil, category: String = "General", createdBy: User) -> ChoreTemplate {
        let template = ChoreTemplate(context: context)
        template.id = UUID()
        template.name = name
        template.choreDescription = description
        template.category = category
        template.createdBy = createdBy
        template.createdAt = Date()
        template.isActive = true
        return template
    }
    
    // MARK: - Computed Properties
    
    /// Parsed recurrence rule from JSON
    var recurrenceRule: RecurrenceRule? {
        get {
            guard let json = recurrenceRuleJSON,
                  let data = json.data(using: .utf8) else {
                return nil
            }
            return try? JSONDecoder().decode(RecurrenceRule.self, from: data)
        }
        set {
            if let rule = newValue,
               let data = try? JSONEncoder().encode(rule),
               let json = String(data: data, encoding: .utf8) {
                recurrenceRuleJSON = json
            } else {
                recurrenceRuleJSON = nil
            }
        }
    }
    
    // MARK: - Helper Properties
    
    /// Convenience accessor for estimatedDuration as TimeInterval
    var estimatedDurationValue: TimeInterval? {
        get {
            // Return as optional - if estimatedDuration is non-optional Double, Swift wraps it
            return estimatedDuration
        }
        set {
            // Unwrap optional value - if nil, use default of 0.0
            estimatedDuration = newValue ?? 0.0
        }
    }
}


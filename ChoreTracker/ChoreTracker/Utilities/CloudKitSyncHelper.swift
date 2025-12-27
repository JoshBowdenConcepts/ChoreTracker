//
//  CloudKitSyncHelper.swift
//  ChoreTracker
//
//  Created on 2025-12-16.
//

import Foundation
import CoreData
import CloudKit

/// Helper utility to ensure CloudKit sync is working properly
class CloudKitSyncHelper {
    
    /// Forces a CloudKit sync by saving the context and processing changes
    static func forceSync(context: NSManagedObjectContext) throws {
        // Save any pending changes
        if context.hasChanges {
            try context.save()
        }
        
        // Process pending changes to trigger CloudKit sync
        context.processPendingChanges()
        
        // Refresh to pull in any CloudKit changes
        context.refreshAllObjects()
    }
    
    /// Verifies CloudKit is properly configured
    static func verifyCloudKitConfiguration(container: NSPersistentCloudKitContainer) -> Bool {
        guard let description = container.persistentStoreDescriptions.first else {
            print("❌ No persistent store description found")
            return false
        }
        
        let hasCloudKitOptions = description.cloudKitContainerOptions != nil
        let hasHistoryTracking = description.options[NSPersistentHistoryTrackingKey] as? Bool ?? false
        
        print("CloudKit Configuration:")
        print("  - Has CloudKit options: \(hasCloudKitOptions)")
        print("  - Has history tracking: \(hasHistoryTracking)")
        print("  - Store type: \(description.type)")
        
        if hasCloudKitOptions, let containerID = description.cloudKitContainerOptions?.containerIdentifier {
            print("  - Container ID: \(containerID)")
        }
        
        return hasCloudKitOptions && hasHistoryTracking
    }
    
    /// Checks if data exists in CloudKit by attempting to fetch
    static func checkCloudKitDataExists(context: NSManagedObjectContext) async -> (templates: Int, instances: Int, users: Int) {
        do {
            let templates = try context.fetch(ChoreTemplate.fetchRequest())
            let instances = try context.fetch(ChoreInstance.fetchRequest())
            let users = try context.fetch(User.fetchRequest())
            
            return (templates.count, instances.count, users.count)
        } catch {
            print("Error checking CloudKit data: \(error.localizedDescription)")
            return (0, 0, 0)
        }
    }
}






//
//  SyncStatusHelper.swift
//  ChoreTracker
//
//  Created on 2025-12-16.
//

import Foundation
import CoreData
import CloudKit
import SwiftUI

/// Helper to determine if a Core Data object has been synced to CloudKit
class SyncStatusHelper {
    
    /// Checks if an object is synced to CloudKit
    /// An object is considered synced if:
    /// - It's not newly inserted (has been saved)
    /// - It's not pending updates
    /// - It's not deleted
    static func isSynced(_ object: NSManagedObject) -> Bool {
        // If object is inserted but not saved, it's not synced
        if object.isInserted {
            return false
        }
        
        // If object has pending changes, it's not synced
        if object.isUpdated && object.hasChanges {
            return false
        }
        
        // If object is deleted, it's not synced (or sync is pending)
        if object.isDeleted {
            return false
        }
        
        // If object has a fault (not loaded), assume it's synced
        // (objects loaded from CloudKit are typically faults)
        if object.isFault {
            return true
        }
        
        // If object is not inserted, updated, or deleted, it's likely synced
        // This is a heuristic - with NSPersistentCloudKitContainer, we can't
        // directly check CloudKit record status without additional tracking
        return !object.isInserted && !object.isUpdated && !object.isDeleted
    }
    
    /// Gets a sync status icon and color
    static func syncStatusIcon(for object: NSManagedObject) -> (icon: String, color: Color) {
        if isSynced(object) {
            return ("checkmark.icloud.fill", .green)
        } else if object.isInserted {
            return ("icloud.and.arrow.up", .orange)
        } else if object.isUpdated {
            return ("icloud.and.arrow.up", .orange)
        } else {
            return ("icloud.slash", .gray)
        }
    }
}


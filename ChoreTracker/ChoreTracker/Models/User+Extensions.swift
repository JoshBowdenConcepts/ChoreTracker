//
//  User+Extensions.swift
//  ChoreTracker
//
//  Created on 2025-12-16.
//

import Foundation
import CoreData

extension User {
    
    // MARK: - Convenience Methods
    
    /// Creates a new User instance
    public static func create(
        context: NSManagedObjectContext,
        name: String,
        userType: String = "parent",
        email: String? = nil,
        parentId: UUID? = nil,
        isMinor: Bool = false,
        hasDevice: Bool = true
    ) -> User {
        let user = User(context: context)
        user.id = UUID()
        user.name = name
        user.userType = userType
        user.email = email
        user.hasDevice = hasDevice
        user.isMinor = isMinor
        user.parentId = parentId
        user.currentGoalStreak = 0
        user.longestGoalStreak = 0
        
        // Set parent consent date if minor
        if isMinor {
            user.parentConsentDate = Date()
        }
        
        return user
    }
    
    // MARK: - Computed Properties
    
    var isSupervised: Bool {
        return userType == "supervised"
    }
    
    var isParent: Bool {
        return userType == "parent"
    }
    
    var isGuardian: Bool {
        return userType == "guardian"
    }
}


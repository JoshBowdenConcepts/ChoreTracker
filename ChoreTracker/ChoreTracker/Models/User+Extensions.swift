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
    public static func create(context: NSManagedObjectContext, name: String, userType: String = "parent", email: String? = nil) -> User {
        let user = User(context: context)
        user.id = UUID()
        user.name = name
        user.userType = userType
        user.email = email
        user.hasDevice = true
        user.isMinor = false
        user.currentGoalStreak = 0
        user.longestGoalStreak = 0
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


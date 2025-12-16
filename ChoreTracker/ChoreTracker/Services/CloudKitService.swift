//
//  CloudKitService.swift
//  ChoreTracker
//
//  Created on 2025-12-16.
//

import Foundation
import CloudKit
import CoreData

/// Service for managing CloudKit operations
/// Note: With NSPersistentCloudKitContainer, most sync happens automatically.
/// This service provides additional CloudKit operations and validation.
class CloudKitService {
    static let shared = CloudKitService()
    
    private let container: CKContainer
    private let privateDatabase: CKDatabase
    
    private init() {
        // Use default container (matches bundle identifier)
        container = CKContainer.default()
        privateDatabase = container.privateCloudDatabase
    }
    
    // MARK: - Account Status
    
    /// Checks iCloud account status
    func checkAccountStatus() async throws -> CKAccountStatus {
        return try await container.accountStatus()
    }
    
    // MARK: - ChoreTemplate Operations
    
    /// Creates a chore template (via Core Data, which syncs to CloudKit automatically)
    func createChoreTemplate(
        name: String,
        description: String?,
        category: String,
        createdBy: User,
        context: NSManagedObjectContext
    ) throws -> ChoreTemplate {
        let template = ChoreTemplate.create(
            context: context,
            name: name,
            description: description,
            category: category,
            createdBy: createdBy
        )
        
        try context.save()
        return template
    }
    
    /// Fetches chore templates (via Core Data fetch)
    func fetchChoreTemplates(context: NSManagedObjectContext) throws -> [ChoreTemplate] {
        let request: NSFetchRequest<ChoreTemplate> = ChoreTemplate.fetchRequest()
        request.predicate = NSPredicate(format: "isActive == YES")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \ChoreTemplate.createdAt, ascending: false)]
        return try context.fetch(request)
    }
    
    /// Updates a chore template
    func updateChoreTemplate(_ template: ChoreTemplate, context: NSManagedObjectContext) throws {
        try context.save()
    }
    
    /// Deletes a chore template
    func deleteChoreTemplate(_ template: ChoreTemplate, context: NSManagedObjectContext) throws {
        context.delete(template)
        try context.save()
    }
    
    // MARK: - ChoreInstance Operations
    
    /// Creates a chore instance
    func createChoreInstance(
        template: ChoreTemplate,
        dueDate: Date,
        context: NSManagedObjectContext
    ) throws -> ChoreInstance {
        let instance = ChoreInstance.create(
            context: context,
            template: template,
            dueDate: dueDate
        )
        
        try context.save()
        return instance
    }
    
    /// Fetches chore instances
    func fetchChoreInstances(
        context: NSManagedObjectContext,
        status: String? = nil,
        assignedTo: User? = nil
    ) throws -> [ChoreInstance] {
        let request: NSFetchRequest<ChoreInstance> = ChoreInstance.fetchRequest()
        
        var predicates: [NSPredicate] = []
        
        if let status = status {
            predicates.append(NSPredicate(format: "status == %@", status))
        }
        
        if let user = assignedTo {
            predicates.append(NSPredicate(format: "template.assignedTo == %@", user))
        }
        
        if !predicates.isEmpty {
            request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        }
        
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \ChoreInstance.dueDate, ascending: true)
        ]
        
        return try context.fetch(request)
    }
    
    /// Updates a chore instance (e.g., mark complete)
    func updateChoreInstance(_ instance: ChoreInstance, context: NSManagedObjectContext) throws {
        try context.save()
    }
    
    /// Deletes a chore instance
    func deleteChoreInstance(_ instance: ChoreInstance, context: NSManagedObjectContext) throws {
        context.delete(instance)
        try context.save()
    }
    
    // MARK: - User Operations
    
    /// Fetches or creates the current user
    func fetchOrCreateCurrentUser(context: NSManagedObjectContext) async throws -> User {
        // First, try to fetch existing user
        let request: NSFetchRequest<User> = User.fetchRequest()
        // In a real app, you'd match against iCloud user ID
        // For now, we'll create a default user if none exists
        let users = try context.fetch(request)
        
        if let user = users.first {
            return user
        }
        
        // Create default user
        // In production, you'd get the actual iCloud user info
        let user = User.create(context: context, name: "Current User", userType: "parent")
        try context.save()
        return user
    }
    
    // MARK: - Error Handling
    
    /// Handles CloudKit errors and provides user-friendly messages
    func handleCloudKitError(_ error: Error) -> String {
        if let ckError = error as? CKError {
            return ckError.userFriendlyMessage
        } else if let nsError = error as NSError?,
                  nsError.isCloudKitError,
                  let ckError = nsError.asCloudKitError {
            return ckError.userFriendlyMessage
        }
        
        // For Core Data errors, return generic message
        // Never log user data per security requirements
        return "An error occurred. Please try again."
    }
}


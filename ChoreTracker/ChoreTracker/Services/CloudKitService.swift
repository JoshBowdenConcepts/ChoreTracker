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
        
        // Save to Core Data (which will sync to CloudKit automatically)
        // CRITICAL: Save on the view context to ensure CloudKit sync
        try context.save()
        
        // Process pending changes to trigger CloudKit export
        context.processPendingChanges()
        
        // Log for debugging
        let templateID = template.id?.uuidString ?? "no ID"
        let templateName = template.name ?? "unnamed"
        print("💾 ChoreTemplate saved: '\(templateName)' (ID: \(templateID))")
        print("   - Context has changes: \(context.hasChanges)")
        print("   - Object is inserted: \(template.isInserted)")
        print("   - Object is updated: \(template.isUpdated)")
        
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
    
    // MARK: - CloudKit Sharing
    
    /// Fetches all users in the household (from Core Data)
    func fetchHouseholdUsers(context: NSManagedObjectContext) throws -> [User] {
        let request: NSFetchRequest<User> = User.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \User.name, ascending: true)]
        return try context.fetch(request)
    }
    
    /// Creates a CloudKit share for sharing chore data with another user
    /// Note: With NSPersistentCloudKitContainer, use container.share(_:to:) method
    /// This is a placeholder for future CloudKit sharing implementation
    func createShare(for template: ChoreTemplate, container: NSPersistentCloudKitContainer) async throws -> CKShare {
        // CloudKit sharing with Core Data requires using the container's share method
        // This will be implemented when we add full CloudKit sharing support
        throw NSError(domain: "CloudKitService", code: -1, userInfo: [NSLocalizedDescriptionKey: "CloudKit sharing not yet implemented"])
    }
    
    /// Accepts a CloudKit share invitation
    /// Note: Share acceptance is typically handled by the system via UICloudSharingController
    func acceptShare(metadata: CKShare.Metadata) async throws {
        let acceptOperation = CKAcceptSharesOperation(shareMetadatas: [metadata])
        
        return try await withCheckedThrowingContinuation { continuation in
            acceptOperation.acceptSharesResultBlock = { result in
                switch result {
                case .success:
                    continuation.resume()
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
            
            container.add(acceptOperation)
        }
    }
    
    // MARK: - Diagnostic Methods
    
    /// Queries CloudKit directly to check if records exist
    /// This helps diagnose sync issues by checking what's actually in CloudKit
    func queryCloudKitRecords(recordType: String) async throws -> [CKRecord] {
        let query = CKQuery(recordType: recordType, predicate: NSPredicate(value: true))
        query.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        
        var allRecords: [CKRecord] = []
        var cursor: CKQueryOperation.Cursor?
        
        repeat {
            let operation: CKQueryOperation
            if let existingCursor = cursor {
                operation = CKQueryOperation(cursor: existingCursor)
            } else {
                operation = CKQueryOperation(query: query)
            }
            
            let (matchResults, queryCursor) = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<([CKRecord.ID: Result<CKRecord, Error>], CKQueryOperation.Cursor?), Error>) in
                var records: [CKRecord.ID: Result<CKRecord, Error>] = [:]
                
                operation.recordMatchedBlock = { (recordID, result) in
                    records[recordID] = result
                }
                
                operation.queryResultBlock = { result in
                    switch result {
                    case .success(let cursor):
                        continuation.resume(returning: (records, cursor))
                    case .failure(let error):
                        continuation.resume(throwing: error)
                    }
                }
                
                privateDatabase.add(operation)
            }
            
            cursor = queryCursor
            
            for (_, result) in matchResults {
                switch result {
                case .success(let record):
                    allRecords.append(record)
                case .failure(let error):
                    print("⚠️ Failed to fetch record: \(error.localizedDescription)")
                }
            }
        } while cursor != nil
        
        return allRecords
    }
    
    /// Gets a summary of all CloudKit record types and counts
    func getCloudKitDataSummary() async -> [String: Int] {
        var summary: [String: Int] = [:]
        
        let recordTypes = ["ChoreTemplate", "ChoreInstance", "User", "DailyGoalCompletion"]
        
        for recordType in recordTypes {
            do {
                let records = try await queryCloudKitRecords(recordType: recordType)
                summary[recordType] = records.count
                print("📊 CloudKit \(recordType): \(records.count) records")
            } catch {
                print("❌ Error querying \(recordType): \(error.localizedDescription)")
                if let ckError = error as? CKError {
                    print("   - CloudKit error code: \(ckError.code.rawValue)")
                    print("   - CloudKit error: \(ckError.userFriendlyMessage)")
                }
                summary[recordType] = -1 // -1 indicates error
            }
        }
        
        return summary
    }
    
    /// Verifies the CloudKit container identifier matches what's expected
    func verifyContainerIdentifier() -> String {
        let containerID = container.containerIdentifier
        let expectedID = "iCloud.\(Bundle.main.bundleIdentifier ?? "unknown")"
        print("🔍 Container Verification:")
        print("   - Actual: \(containerID ?? "nil")")
        print("   - Expected: \(expectedID)")
        return containerID ?? "unknown"
    }
    
    /// Checks if CloudKit account is available and container is accessible
    func verifyCloudKitAccess() async -> (isAvailable: Bool, error: String?) {
        do {
            let status = try await checkAccountStatus()
            if status != .available {
                return (false, "iCloud account status: \(status)")
            }
            
            // Try a simple query to verify database access
            // Using a predicate that matches nothing is safe and tests access
            let query = CKQuery(recordType: "ChoreTemplate", predicate: NSPredicate(value: false))
            let operation = CKQueryOperation(query: query)
            operation.resultsLimit = 1
            
            return try await withCheckedThrowingContinuation { continuation in
                operation.queryResultBlock = { result in
                    switch result {
                    case .success:
                        // Query succeeded, database is accessible
                        continuation.resume(returning: (true, nil))
                    case .failure(let error):
                        if let ckError = error as? CKError {
                            // Check for critical errors that indicate access problems
                            switch ckError.code {
                            case .notAuthenticated, .permissionFailure, .serviceUnavailable:
                                continuation.resume(returning: (false, "CloudKit error: \(ckError.userFriendlyMessage)"))
                            default:
                                // Other errors might be okay (like network issues)
                                continuation.resume(returning: (true, nil))
                            }
                        } else {
                            continuation.resume(returning: (false, "Error: \(error.localizedDescription)"))
                        }
                    }
                }
                
                privateDatabase.add(operation)
            }
        } catch {
            return (false, "Error: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Error Handling
    
    /// Handles CloudKit errors and provides user-friendly messages
    func handleCloudKitError(_ error: Error) -> String {
        return ErrorHandler.userFriendlyMessage(for: error)
    }
}


//
//  ReviewService.swift
//  ChoreTracker
//
//  Created on 2025-12-16.
//

import Foundation
import CoreData

/// Service for managing parent review workflow for supervised account completions
class ReviewService {
    static let shared = ReviewService()
    
    private init() {}
    
    // MARK: - Review Operations
    
    /// Approves a chore completion
    func approveCompletion(
        _ instance: ChoreInstance,
        reviewedBy: User,
        context: NSManagedObjectContext
    ) throws {
        instance.status = "completed"
        instance.requiresReview = false
        instance.reviewedAt = Date()
        instance.reviewStatus = "approved"
        instance.completedBy = reviewedBy
        
        try context.save()
    }
    
    /// Rejects a chore completion
    func rejectCompletion(
        _ instance: ChoreInstance,
        reviewedBy: User,
        reason: String?,
        context: NSManagedObjectContext
    ) throws {
        instance.status = "pending"
        instance.requiresReview = false
        instance.reviewedAt = Date()
        instance.reviewStatus = "rejected"
        instance.rejectionReason = reason
        instance.completedAt = nil
        instance.completedBy = nil
        
        try context.save()
    }
    
    /// Fetches all instances pending review
    func fetchPendingReviews(
        context: NSManagedObjectContext,
        supervisedUser: User? = nil
    ) throws -> [ChoreInstance] {
        let request: NSFetchRequest<ChoreInstance> = ChoreInstance.fetchRequest()
        
        var predicates: [NSPredicate] = [
            NSPredicate(format: "status == %@", "pending_review"),
            NSPredicate(format: "requiresReview == YES")
        ]
        
        if let supervisedUser = supervisedUser {
            predicates.append(NSPredicate(format: "template.assignedTo == %@", supervisedUser))
        }
        
        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \ChoreInstance.completedAt, ascending: false)
        ]
        
        return try context.fetch(request)
    }
    
    /// Checks if a user is supervised (has a parent)
    func isSupervisedUser(_ user: User) -> Bool {
        return user.parentId != nil || user.userType == "supervised"
    }
    
    /// Gets all supervised users for a parent
    func getSupervisedUsers(for parent: User, context: NSManagedObjectContext) throws -> [User] {
        guard let parentId = parent.id else { return [] }
        
        let request: NSFetchRequest<User> = User.fetchRequest()
        request.predicate = NSPredicate(format: "parentId == %@", parentId as NSUUID)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \User.name, ascending: true)]
        return try context.fetch(request)
    }
    
    /// Gets all guardians for a supervised user
    func getGuardians(for supervisedUser: User, context: NSManagedObjectContext) throws -> [User] {
        guard let parentId = supervisedUser.parentId else { return [] }
        
        let request: NSFetchRequest<User> = User.fetchRequest()
        let parentPredicate = NSPredicate(format: "id == %@", parentId as NSUUID)
        let guardianPredicate = NSPredicate(format: "userType == %@", "guardian")
        request.predicate = NSCompoundPredicate(orPredicateWithSubpredicates: [parentPredicate, guardianPredicate])
        request.sortDescriptors = [NSSortDescriptor(keyPath: \User.name, ascending: true)]
        return try context.fetch(request)
    }
}


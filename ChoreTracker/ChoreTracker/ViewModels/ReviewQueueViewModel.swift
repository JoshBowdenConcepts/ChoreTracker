//
//  ReviewQueueViewModel.swift
//  ChoreTracker
//
//  Created on 2025-12-16.
//

import Foundation
import SwiftUI
import CoreData
import Combine

@MainActor
class ReviewQueueViewModel: ObservableObject {
    @Published var pendingReviews: [ChoreInstance] = []
    @Published var supervisedUsers: [User] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var selectedSupervisedUser: User? = nil
    
    private let reviewService = ReviewService.shared
    private let cloudKitService = CloudKitService.shared
    private var cancellables = Set<AnyCancellable>()
    private let context: NSManagedObjectContext
    
    init(context: NSManagedObjectContext? = nil) {
        if let context = context {
            self.context = context
        } else {
            self.context = PersistenceController.shared.container.viewContext
        }
        setupObservers()
        Task {
            await loadInitialData()
        }
    }
    
    // MARK: - Setup
    
    private func setupObservers() {
        NotificationCenter.default.publisher(
            for: .NSManagedObjectContextDidSave,
            object: context
        )
        .sink { [weak self] _ in
            Task { @MainActor in
                await self?.loadPendingReviews()
            }
        }
        .store(in: &cancellables)
    }
    
    // MARK: - Data Loading
    
    func loadInitialData() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Get current user
            let currentUser = try await cloudKitService.fetchOrCreateCurrentUser(context: context)
            
            // Load supervised users (only if current user is a parent)
            if currentUser.isParent || currentUser.isGuardian {
                supervisedUsers = try reviewService.getSupervisedUsers(for: currentUser, context: context)
            } else {
                // If not a parent, try to get all supervised users in household
                let allUsers = try cloudKitService.fetchHouseholdUsers(context: context)
                supervisedUsers = allUsers.filter { $0.userType == "supervised" || $0.parentId != nil }
            }
            
            // Load pending reviews
            await loadPendingReviews()
        } catch {
            errorMessage = cloudKitService.handleCloudKitError(error)
        }
    }
    
    func loadPendingReviews() async {
        do {
            pendingReviews = try reviewService.fetchPendingReviews(
                context: context,
                supervisedUser: selectedSupervisedUser
            )
            errorMessage = nil
        } catch {
            errorMessage = cloudKitService.handleCloudKitError(error)
        }
    }
    
    // MARK: - Review Actions
    
    func approveReview(_ instance: ChoreInstance) async {
        guard let currentUser = try? await cloudKitService.fetchOrCreateCurrentUser(context: context) else {
            errorMessage = "User not available"
            return
        }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            try reviewService.approveCompletion(
                instance,
                reviewedBy: currentUser,
                context: context
            )
            await loadPendingReviews()
        } catch {
            errorMessage = cloudKitService.handleCloudKitError(error)
        }
    }
    
    func rejectReview(_ instance: ChoreInstance, reason: String? = nil) async {
        guard let currentUser = try? await cloudKitService.fetchOrCreateCurrentUser(context: context) else {
            errorMessage = "User not available"
            return
        }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            try reviewService.rejectCompletion(
                instance,
                reviewedBy: currentUser,
                reason: reason,
                context: context
            )
            await loadPendingReviews()
        } catch {
            errorMessage = cloudKitService.handleCloudKitError(error)
        }
    }
    
    // MARK: - Filtering
    
    var filteredReviews: [ChoreInstance] {
        if let selectedUser = selectedSupervisedUser {
            return pendingReviews.filter { instance in
                instance.template?.assignedTo?.id == selectedUser.id
            }
        }
        return pendingReviews
    }
}


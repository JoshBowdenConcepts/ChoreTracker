//
//  ChoreListViewModel.swift
//  ChoreTracker
//
//  Created on 2025-12-16.
//

import Foundation
import SwiftUI
import CoreData
import Combine

@MainActor
class ChoreListViewModel: ObservableObject {
    @Published var choreTemplates: [ChoreTemplate] = []
    @Published var choreInstances: [ChoreInstance] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var currentUser: User?
    @Published var householdUsers: [User] = []
    
    private let cloudKitService = CloudKitService.shared
    private var cancellables = Set<AnyCancellable>()
    private let context: NSManagedObjectContext
    
    init(context: NSManagedObjectContext? = nil) {
        // Access PersistenceController inside init body (MainActor context) to avoid isolation issues
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
        // Observe Core Data changes
        NotificationCenter.default.publisher(
            for: .NSManagedObjectContextDidSave,
            object: context
        )
        .sink { [weak self] _ in
            Task { @MainActor in
                await self?.loadChores()
            }
        }
        .store(in: &cancellables)
    }
    
    // MARK: - Data Loading
    
    func loadInitialData() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Fetch or create current user
            currentUser = try await cloudKitService.fetchOrCreateCurrentUser(context: context)
            
            // Load household users
            householdUsers = try cloudKitService.fetchHouseholdUsers(context: context)
            
            // Load chores
            await loadChores()
        } catch {
            errorMessage = cloudKitService.handleCloudKitError(error)
        }
    }
    
    func loadChores() async {
        // Only show loading indicator for initial load, not for refreshes
        let shouldShowLoading = choreTemplates.isEmpty && choreInstances.isEmpty
        if shouldShowLoading {
            isLoading = true
        }
        defer { isLoading = false }
        
        do {
            choreTemplates = try cloudKitService.fetchChoreTemplates(context: context)
            choreInstances = try cloudKitService.fetchChoreInstances(context: context)
            
            // Refresh household users
            householdUsers = try cloudKitService.fetchHouseholdUsers(context: context)
            
            // Generate instances for templates that need them (batch operation)
            var templatesNeedingGeneration: [ChoreTemplate] = []
            for template in choreTemplates {
                if InstanceGenerator.needsInstanceGeneration(for: template) {
                    templatesNeedingGeneration.append(template)
                }
            }
            
            // Generate instances in batch to improve performance
            for template in templatesNeedingGeneration {
                do {
                    _ = try InstanceGenerator.generateInstances(
                        for: template,
                        context: context
                    )
                } catch {
                    // Log error but don't fail the entire load
                    print("Failed to generate instances for template: \(error.localizedDescription)")
                }
            }
            
            // Reload instances after generation
            if !templatesNeedingGeneration.isEmpty {
                choreInstances = try cloudKitService.fetchChoreInstances(context: context)
            }
            
            errorMessage = nil
        } catch {
            errorMessage = cloudKitService.handleCloudKitError(error)
        }
    }
    
    // MARK: - Chore Template Operations
    
    func createChoreTemplate(
        name: String,
        description: String?,
        category: String,
        recurrenceRule: RecurrenceRule? = nil,
        assignedTo: User? = nil
    ) async {
        guard let user = currentUser else {
            errorMessage = "User not available"
            return
        }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            let template = try cloudKitService.createChoreTemplate(
                name: name,
                description: description,
                category: category,
                createdBy: user,
                context: context
            )
            
            // Set assignment if provided
            if let assignedTo = assignedTo {
                template.assignedTo = assignedTo
            }
            
            // Set recurrence rule if provided
            if let recurrenceRule = recurrenceRule {
                template.recurrenceRule = recurrenceRule
            }
            
            try context.save()
            
            // Generate initial instances for recurring chores
            if template.recurrenceRule != nil {
                _ = try InstanceGenerator.generateInstances(
                    for: template,
                    context: context
                )
            }
            
            await loadChores()
        } catch {
            errorMessage = cloudKitService.handleCloudKitError(error)
        }
    }
    
    func deleteChoreTemplate(_ template: ChoreTemplate) async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            try cloudKitService.deleteChoreTemplate(template, context: context)
            await loadChores()
        } catch {
            errorMessage = cloudKitService.handleCloudKitError(error)
        }
    }
    
    // MARK: - Chore Instance Operations
    
    func markInstanceComplete(_ instance: ChoreInstance, duration: TimeInterval? = nil) async {
        guard let user = currentUser else {
            errorMessage = "User not available"
            return
        }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            instance.markComplete(by: user, duration: duration)
            try cloudKitService.updateChoreInstance(instance, context: context)
            
            // Update daily goal and statistics if completed (not pending review)
            if instance.status == "completed" {
                let statisticsService = StatisticsService.shared
                let completionDate = instance.completedAt ?? Date()
                try statisticsService.checkAndUpdateDailyGoal(
                    for: user,
                    date: completionDate,
                    context: context
                )
            }
            
            // Schedule/cancel notifications
            let notificationService = NotificationService.shared
            if instance.status == "completed" || instance.status == "skipped" {
                notificationService.cancelNotification(for: instance)
            }
            
            await loadChores()
        } catch {
            errorMessage = cloudKitService.handleCloudKitError(error)
        }
    }
    
    func markInstanceSkipped(_ instance: ChoreInstance) async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            instance.markSkipped()
            try cloudKitService.updateChoreInstance(instance, context: context)
            await loadChores()
        } catch {
            errorMessage = cloudKitService.handleCloudKitError(error)
        }
    }
    
    // MARK: - Filtering
    
    var pendingInstances: [ChoreInstance] {
        choreInstances.filter { $0.status == "pending" }
    }
    
    var completedInstances: [ChoreInstance] {
        choreInstances.filter { $0.status == "completed" }
    }
    
    var overdueInstances: [ChoreInstance] {
        choreInstances.filter { $0.isOverdue }
    }
}


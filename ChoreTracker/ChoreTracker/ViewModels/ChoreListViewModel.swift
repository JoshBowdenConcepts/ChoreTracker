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
            
            // Load chores
            await loadChores()
        } catch {
            errorMessage = cloudKitService.handleCloudKitError(error)
        }
    }
    
    func loadChores() async {
        do {
            choreTemplates = try cloudKitService.fetchChoreTemplates(context: context)
            choreInstances = try cloudKitService.fetchChoreInstances(context: context)
            
            // Generate instances for templates that need them
            for template in choreTemplates {
                if InstanceGenerator.needsInstanceGeneration(for: template) {
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
            }
            
            // Reload instances after generation
            choreInstances = try cloudKitService.fetchChoreInstances(context: context)
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
        recurrenceRule: RecurrenceRule? = nil
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
            
            // Set recurrence rule if provided
            if let recurrenceRule = recurrenceRule {
                template.recurrenceRule = recurrenceRule
                try context.save()
                
                // Generate initial instances for recurring chores
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
    
    func markInstanceComplete(_ instance: ChoreInstance) async {
        guard let user = currentUser else {
            errorMessage = "User not available"
            return
        }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            instance.markComplete(by: user)
            try cloudKitService.updateChoreInstance(instance, context: context)
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


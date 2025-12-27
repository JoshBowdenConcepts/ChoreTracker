//
//  StatisticsViewModel.swift
//  ChoreTracker
//
//  Created on 2025-12-16.
//

import Foundation
import SwiftUI
import CoreData
import Combine

@MainActor
class StatisticsViewModel: ObservableObject {
    @Published var totalChoresCompleted: Int = 0
    @Published var totalTimeSpent: TimeInterval = 0
    @Published var currentStreak: Int = 0
    @Published var longestStreak: Int = 0
    @Published var completionRate: Double = 0.0
    @Published var averageCompletionTime: TimeInterval = 0
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var goalCompletions: [DailyGoalCompletion] = []
    
    private let statisticsService = StatisticsService.shared
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
            await loadStatistics()
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
                await self?.loadStatistics()
            }
        }
        .store(in: &cancellables)
    }
    
    // MARK: - Data Loading
    
    func loadStatistics(for user: User? = nil) async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let targetUser: User
            if let user = user {
                targetUser = user
            } else {
                targetUser = try await cloudKitService.fetchOrCreateCurrentUser(context: context)
            }
            
            totalChoresCompleted = try statisticsService.totalChoresCompleted(for: targetUser, context: context)
            totalTimeSpent = try statisticsService.totalTimeSpent(for: targetUser, context: context)
            currentStreak = statisticsService.currentGoalStreak(for: targetUser)
            longestStreak = statisticsService.longestGoalStreak(for: targetUser)
            completionRate = try statisticsService.completionRate(for: targetUser, context: context)
            averageCompletionTime = try statisticsService.averageCompletionTime(for: targetUser, context: context)
            
            // Load last 30 days of goal completions
            let endDate = Date()
            let startDate = Calendar.current.date(byAdding: .day, value: -30, to: endDate) ?? endDate
            goalCompletions = try statisticsService.fetchGoalCompletions(
                for: targetUser,
                from: startDate,
                to: endDate,
                context: context
            )
            
            errorMessage = nil
        } catch {
            errorMessage = cloudKitService.handleCloudKitError(error)
        }
    }
}






//
//  ChoreTrackerApp.swift
//  ChoreTracker
//
//  Created on 2025-12-16.
//

import SwiftUI
import CoreData

@main
struct ChoreTrackerApp: App {
    // Persistent container for Core Data with CloudKit integration
    let persistenceController = PersistenceController.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .task {
                    // Request notification permission on app launch
                    _ = await NotificationService.shared.requestPermission()
                }
        }
    }
}

// MARK: - PersistenceController
/// Manages the Core Data stack with CloudKit integration
class PersistenceController {
    static let shared = PersistenceController()
    
    let container: NSPersistentCloudKitContainer
    
    init(inMemory: Bool = false) {
        // Temporarily commented out until Core Data model is recreated
        // container = NSPersistentCloudKitContainer(name: "ChoreTracker")
        
        // Create a basic container for now
        container = NSPersistentCloudKitContainer(name: "ChoreTracker")
        
        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }
        
        // Configure CloudKit
        let description = container.persistentStoreDescriptions.first
        description?.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        description?.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
        
        // Enable CloudKit sync
        container.loadPersistentStores { description, error in
            if let error = error {
                // In production, use proper error handling
                // For now, we'll log a technical error (not user data)
                fatalError("Core Data store failed to load: \(error.localizedDescription)")
            }
        }
        
        // Automatically merge changes from CloudKit
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }
    
    // Preview instance for SwiftUI previews
    @MainActor
    static var preview: PersistenceController = {
        let controller = PersistenceController(inMemory: true)
        let context = controller.container.viewContext
        
        // Create sample data for previews
        let user = User.create(context: context, name: "Preview User")
        let template = ChoreTemplate.create(context: context, name: "Sample Chore", category: "General", createdBy: user)
        
        do {
            try context.save()
        } catch {
            let nsError = error as NSError
            fatalError("Preview data creation failed: \(nsError), \(nsError.userInfo)")
        }
        
        return controller
    }()
}


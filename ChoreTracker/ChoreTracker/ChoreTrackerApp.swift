//
//  ChoreTrackerApp.swift
//  ChoreTracker
//
//  Created on 2025-12-16.
//

import SwiftUI
import CoreData
import CloudKit

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
                    
                    // Check iCloud status and ensure sync is working
                    await checkAndEnsureCloudKitSync()
                }
        }
    }
    
    private func checkAndEnsureCloudKitSync() async {
        do {
            let status = try await CloudKitService.shared.checkAccountStatus()
            print("iCloud account status: \(status.rawValue)")
            
            if status == .available {
                // Force CloudKit to sync by accessing the container
                // This triggers the initial download from iCloud
                let context = persistenceController.container.viewContext
                
                // Wait a moment for CloudKit to initialize
                try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
                
                // Perform fetches to trigger CloudKit sync
                // These will download data from iCloud if it exists
                let templates = try? context.fetch(ChoreTemplate.fetchRequest())
                let instances = try? context.fetch(ChoreInstance.fetchRequest())
                let users = try? context.fetch(User.fetchRequest())
                
                print("CloudKit sync check - Templates: \(templates?.count ?? 0), Instances: \(instances?.count ?? 0), Users: \(users?.count ?? 0)")
                
                // Process any pending changes from CloudKit
                context.processPendingChanges()
                
                // Refresh all objects to ensure we have the latest from CloudKit
                context.refreshAllObjects()
            } else {
                print("⚠️ iCloud not available - status: \(status.rawValue)")
                print("⚠️ Data will NOT sync to iCloud. Please sign in to iCloud in Settings.")
            }
        } catch {
            print("❌ CloudKit status check failed: \(error.localizedDescription)")
        }
    }
}

// MARK: - PersistenceController
/// Manages the Core Data stack with CloudKit integration
class PersistenceController {
    static let shared = PersistenceController()
    
    let container: NSPersistentCloudKitContainer
    
    init(inMemory: Bool = false) {
        // Create NSPersistentCloudKitContainer
        container = NSPersistentCloudKitContainer(name: "ChoreTracker")
        
        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
            // For in-memory stores, CloudKit is disabled
        } else {
            // Configure CloudKit for persistent storage
            guard let description = container.persistentStoreDescriptions.first else {
                fatalError("No persistent store description found")
            }
            
            // CRITICAL: Enable CloudKit sync options
            description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
            description.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
            
            // CRITICAL: Explicitly set CloudKit container options
            // NSPersistentCloudKitContainer should do this automatically, but we'll be explicit
            if description.cloudKitContainerOptions == nil {
                let bundleID = Bundle.main.bundleIdentifier ?? "com.choretracker.ChoreTracker"
                let containerIdentifier = "iCloud.\(bundleID)"
                description.cloudKitContainerOptions = NSPersistentCloudKitContainerOptions(containerIdentifier: containerIdentifier)
                print("✅ Explicitly set CloudKit container: \(containerIdentifier)")
            } else {
                let containerID = description.cloudKitContainerOptions?.containerIdentifier ?? "unknown"
                print("✅ CloudKit container already configured: \(containerID)")
            }
            
            // Log configuration for debugging
            print("📦 Store Configuration:")
            print("   - URL: \(description.url?.lastPathComponent ?? "nil")")
            print("   - Type: \(description.type)")
            print("   - CloudKit enabled: \(description.cloudKitContainerOptions != nil)")
        }
        
        // Load persistent stores
        container.loadPersistentStores { [weak self] storeDescription, error in
            if let error = error {
                // Log detailed error information
                let nsError = error as NSError
                print("❌ Core Data store failed to load:")
                print("   - Error: \(nsError.localizedDescription)")
                print("   - Domain: \(nsError.domain)")
                print("   - Code: \(nsError.code)")
                print("   - UserInfo: \(nsError.userInfo)")
                
                // Check if it's a CloudKit error
                if let cloudKitError = nsError.asCloudKitError {
                    print("   - CloudKit error: \(cloudKitError.userFriendlyMessage)")
                    print("   - CloudKit error code: \(cloudKitError.code.rawValue)")
                    print("   - CloudKit error userInfo: \(cloudKitError.userInfo)")
                }
                
                fatalError("Core Data store failed to load: \(error.localizedDescription)")
            }
            
            // After store loads, verify CloudKit is active
            print("✅ Store loaded successfully:")
            print("   - Path: \(storeDescription.url?.lastPathComponent ?? "unknown")")
            print("   - CloudKit enabled: \(storeDescription.cloudKitContainerOptions != nil)")
            if let containerID = storeDescription.cloudKitContainerOptions?.containerIdentifier {
                print("   - Container ID: \(containerID)")
            }
            print("   - Store type: \(storeDescription.type)")
            
            // Verify CloudKit configuration
            if let self = self {
                let isConfigured = CloudKitSyncHelper.verifyCloudKitConfiguration(container: self.container)
                if !isConfigured {
                    print("⚠️ WARNING: CloudKit may not be properly configured!")
                }
                
                // Set up error observer for CloudKit sync errors
                self.setupCloudKitErrorObserver()
            }
        }
        
        // Automatically merge changes from CloudKit
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        
        // Set up CloudKit sync notifications
        NotificationCenter.default.addObserver(
            forName: .NSPersistentStoreRemoteChange,
            object: container.persistentStoreCoordinator,
            queue: .main
        ) { [weak self] notification in
            guard let self = self else { return }
            // CloudKit sync occurred - data was synced from iCloud
            print("🔄 CloudKit sync notification received")
            print("   - Data may have been synced from iCloud")
            
            // Refresh the view context to pull in changes
            // This will update sync status indicators in the UI
            self.container.viewContext.refreshAllObjects()
            print("   - View context refreshed - sync status indicators updated")
        }
        
        // Also listen for Core Data save notifications to track when we save
        NotificationCenter.default.addObserver(
            forName: .NSManagedObjectContextDidSave,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let self = self else { return }
            if let context = notification.object as? NSManagedObjectContext,
               context == self.container.viewContext {
                let inserted = notification.userInfo?[NSInsertedObjectsKey] as? Set<NSManagedObject> ?? []
                let updated = notification.userInfo?[NSUpdatedObjectsKey] as? Set<NSManagedObject> ?? []
                print("💾 Core Data save completed:")
                print("   - Inserted: \(inserted.count) objects")
                print("   - Updated: \(updated.count) objects")
                print("   - These will sync to CloudKit automatically")
            }
        }
    }
    
    /// Sets up observers for CloudKit sync errors
    private func setupCloudKitErrorObserver() {
        // Listen for NSPersistentStoreRemoteChange notifications which include CloudKit errors
        NotificationCenter.default.addObserver(
            forName: .NSPersistentStoreRemoteChange,
            object: container.persistentStoreCoordinator,
            queue: .main
        ) { notification in
            if let userInfo = notification.userInfo {
                print("🔄 CloudKit Remote Change Notification:")
                print("   - UserInfo: \(userInfo)")
                
                // Check for errors in the notification
                // Note: NSPersistentStoreRemoteChange doesn't include errors directly
                // Errors would be logged separately during save operations
            }
        }
        
        // Also listen for Core Data save notifications to track sync
        NotificationCenter.default.addObserver(
            forName: .NSManagedObjectContextDidSave,
            object: nil,
            queue: .main
        ) { notification in
            // This notification fires on successful saves
            // CloudKit errors would appear in the save operation itself
            if let inserted = notification.userInfo?[NSInsertedObjectsKey] as? Set<NSManagedObject>,
               !inserted.isEmpty {
                print("💾 Saved \(inserted.count) objects - will sync to CloudKit")
            }
        }
    }
    
    /// Forces CloudKit to initialize schema and sync
    func forceCloudKitSync() async {
        print("🔄 Forcing CloudKit sync...")
        let context = container.viewContext
        
        // Save any pending changes
        if context.hasChanges {
            do {
                try context.save()
                print("✅ Saved pending changes")
            } catch {
                print("❌ Error saving context: \(error.localizedDescription)")
                let nsError = error as NSError
                if let cloudKitError = nsError.asCloudKitError {
                    print("   - CloudKit error: \(cloudKitError.userFriendlyMessage)")
                }
            }
        }
        
        // Process pending changes to trigger CloudKit export
        context.processPendingChanges()
        
        // Wait a moment for CloudKit to process
        try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
        
        // Try to fetch to trigger CloudKit import
        do {
            _ = try context.fetch(ChoreTemplate.fetchRequest())
            print("✅ Triggered CloudKit fetch")
        } catch {
            print("❌ Error fetching: \(error.localizedDescription)")
        }
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


//
//  CloudKitDiagnosticsView.swift
//  ChoreTracker
//
//  Created on 2025-12-16.
//

import SwiftUI
import CoreData
import CloudKit

struct CloudKitDiagnosticsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var cloudKitSummary: [String: Int] = [:]
    @State private var coreDataSummary: [String: Int] = [:]
    @State private var isChecking = false
    @State private var errorMessage: String?
    @State private var containerID: String = "Unknown"
    @State private var cloudKitAccessStatus: String = "Not checked"
    @State private var accountStatus: String = "Not checked"
    
    var body: some View {
        NavigationView {
            List {
                Section("Container Information") {
                    HStack {
                        Text("Container ID:")
                        Spacer()
                        Text(containerID)
                            .font(.system(.body, design: .monospaced))
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Account Status:")
                        Spacer()
                        Text(accountStatus)
                            .foregroundColor(accountStatus.contains("available") ? .green : .orange)
                    }
                    
                    HStack {
                        Text("CloudKit Access:")
                        Spacer()
                        Text(cloudKitAccessStatus)
                            .foregroundColor(cloudKitAccessStatus.contains("OK") ? .green : .red)
                    }
                }
                
                Section("Core Data (Local)") {
                    ForEach(["ChoreTemplate", "ChoreInstance", "User", "DailyGoalCompletion"], id: \.self) { type in
                        HStack {
                            Text(type)
                            Spacer()
                            Text("\(coreDataSummary[type] ?? 0)")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Section("CloudKit (iCloud)") {
                    ForEach(["ChoreTemplate", "ChoreInstance", "User", "DailyGoalCompletion"], id: \.self) { type in
                        HStack {
                            Text(type)
                            Spacer()
                            if let count = cloudKitSummary[type] {
                                if count == -1 {
                                    Text("Error")
                                        .foregroundColor(.red)
                                } else {
                                    Text("\(count)")
                                        .foregroundColor(count > 0 ? .green : .secondary)
                                }
                            } else {
                                Text("—")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                
                if let error = errorMessage {
                    Section("Error") {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
                
                Section {
                    Button(action: {
                        Task {
                            await checkSyncStatus()
                        }
                    }) {
                        HStack {
                            if isChecking {
                                ProgressView()
                                    .scaleEffect(0.8)
                            }
                            Text(isChecking ? "Checking..." : "Refresh CloudKit Status")
                        }
                    }
                    .disabled(isChecking)
                    
                    Button(action: {
                        Task {
                            await forceCloudKitSync()
                        }
                    }) {
                        HStack {
                            Image(systemName: "arrow.clockwise")
                            Text("Force CloudKit Sync")
                        }
                    }
                    .disabled(isChecking)
                }
                
                Section("Troubleshooting") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("If you don't see data in CloudKit:")
                            .font(.headline)
                        Text("1. Make sure you're signed in to iCloud")
                        Text("2. Check you're looking at the Development environment")
                        Text("3. Check you're looking at Private Database (not Public)")
                        Text("4. Wait 1-2 minutes after creating data")
                        Text("5. Check Xcode console for CloudKit errors")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
            }
            .navigationTitle("CloudKit Diagnostics")
            .task {
                await checkSyncStatus()
            }
        }
    }
    
    private func forceCloudKitSync() async {
        isChecking = true
        errorMessage = nil
        defer { isChecking = false }
        
        await PersistenceController.shared.forceCloudKitSync()
        
        // Wait a moment then refresh
        try? await Task.sleep(nanoseconds: 2_000_000_000)
        await checkSyncStatus()
    }
    
    private func checkSyncStatus() async {
        isChecking = true
        errorMessage = nil
        defer { isChecking = false }
        
        // Get Core Data counts
        await MainActor.run {
            do {
                let templates = try viewContext.fetch(ChoreTemplate.fetchRequest())
                let instances = try viewContext.fetch(ChoreInstance.fetchRequest())
                let users = try viewContext.fetch(User.fetchRequest())
                let completions = try viewContext.fetch(DailyGoalCompletion.fetchRequest())
                
                coreDataSummary = [
                    "ChoreTemplate": templates.count,
                    "ChoreInstance": instances.count,
                    "User": users.count,
                    "DailyGoalCompletion": completions.count
                ]
            } catch {
                errorMessage = "Error fetching Core Data: \(error.localizedDescription)"
            }
        }
        
        // Get CloudKit container ID
        if let container = PersistenceController.shared.container.persistentStoreDescriptions.first?.cloudKitContainerOptions?.containerIdentifier {
            await MainActor.run {
                containerID = container
            }
        } else {
            // Fallback: get from CloudKitService
            let actualID = CloudKitService.shared.verifyContainerIdentifier()
            await MainActor.run {
                containerID = actualID
            }
        }
        
        // Check account status
        do {
            let status = try await CloudKitService.shared.checkAccountStatus()
            await MainActor.run {
                switch status {
                case .available:
                    accountStatus = "Available ✅"
                case .noAccount:
                    accountStatus = "No Account ⚠️"
                case .restricted:
                    accountStatus = "Restricted ⚠️"
                case .couldNotDetermine:
                    accountStatus = "Unknown ⚠️"
                case .temporarilyUnavailable:
                    accountStatus = "Temporarily Unavailable ⚠️"
                @unknown default:
                    accountStatus = "Unknown"
                }
            }
        } catch {
            await MainActor.run {
                accountStatus = "Error: \(error.localizedDescription)"
            }
        }
        
        // Check CloudKit access
        let (isAvailable, accessError) = await CloudKitService.shared.verifyCloudKitAccess()
        await MainActor.run {
            if isAvailable {
                cloudKitAccessStatus = "OK ✅"
            } else {
                cloudKitAccessStatus = accessError ?? "Unknown error"
            }
        }
        
        // Get CloudKit counts
        let summary = await CloudKitService.shared.getCloudKitDataSummary()
        await MainActor.run {
            cloudKitSummary = summary
            // Check if any record types had errors (indicated by -1)
            let hasErrors = summary.values.contains(-1)
            if hasErrors {
                errorMessage = "Some CloudKit queries failed. Check console for details."
            }
        }
    }
}




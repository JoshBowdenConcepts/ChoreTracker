//
//  SettingsView.swift
//  ChoreTracker
//
//  Created on 2025-12-16.
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var notificationReminderMinutes = 60
    @State private var lookAheadDays = 90
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Notifications") {
                    Picker("Reminder Time", selection: $notificationReminderMinutes) {
                        Text("15 minutes before").tag(15)
                        Text("30 minutes before").tag(30)
                        Text("1 hour before").tag(60)
                        Text("2 hours before").tag(120)
                        Text("1 day before").tag(1440)
                    }
                    
                    Text("You'll receive a notification this long before each chore is due")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Section("Instance Generation") {
                    Picker("Look Ahead Days", selection: $lookAheadDays) {
                        Text("30 days").tag(30)
                        Text("60 days").tag(60)
                        Text("90 days").tag(90)
                        Text("180 days").tag(180)
                    }
                    
                    Text("How far in advance to generate chore instances")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Section("iCloud Sync") {
                    NavigationLink(destination: iCloudStatusView()) {
                        HStack {
                            Image(systemName: "icloud.fill")
                            Text("iCloud Status")
                        }
                    }
                    
                    NavigationLink(destination: CloudKitDiagnosticsView()) {
                        HStack {
                            Image(systemName: "stethoscope")
                            Text("CloudKit Diagnostics")
                        }
                    }
                    
                    Text("Your data is stored in iCloud and will sync across all your devices. Make sure you're signed in to iCloud in Settings.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    Link("Privacy Policy", destination: URL(string: "https://example.com/privacy")!)
                    Link("Terms of Service", destination: URL(string: "https://example.com/terms")!)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}


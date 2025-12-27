//
//  iCloudStatusView.swift
//  ChoreTracker
//
//  Created on 2025-12-16.
//

import SwiftUI
import CloudKit

struct iCloudStatusView: View {
    @State private var accountStatus: CKAccountStatus?
    @State private var isChecking = true
    @State private var errorMessage: String?
    
    var body: some View {
        VStack(spacing: 20) {
            if isChecking {
                ProgressView()
                Text("Checking iCloud status...")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else if let status = accountStatus {
                switch status {
                case .available:
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("iCloud is available")
                            .font(.headline)
                    }
                    Text("Your data will sync across all your devices")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                case .noAccount:
                    VStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                            .font(.largeTitle)
                        Text("iCloud Not Signed In")
                            .font(.headline)
                        Text("Sign in to iCloud in Settings to sync your data across devices")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    Button("Open Settings") {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    
                    Text("After signing in, restart the app to sync your data")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top, 8)
                    }
                    
                case .restricted:
                    VStack(spacing: 12) {
                        Image(systemName: "lock.fill")
                            .foregroundColor(.orange)
                            .font(.largeTitle)
                        Text("iCloud Restricted")
                            .font(.headline)
                        Text("iCloud is restricted on this device. Check Screen Time settings.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    
                case .couldNotDetermine:
                    VStack(spacing: 12) {
                        Image(systemName: "questionmark.circle.fill")
                            .foregroundColor(.orange)
                            .font(.largeTitle)
                        Text("iCloud Status Unknown")
                            .font(.headline)
                        Text("Unable to determine iCloud status. Please check your network connection.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    
                case .temporarilyUnavailable:
                    VStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                            .font(.largeTitle)
                        Text("iCloud Temporarily Unavailable")
                            .font(.headline)
                        Text("iCloud is temporarily unavailable. Please try again later.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    
                @unknown default:
                    Text("Unknown iCloud status")
                }
            }
            
            if let error = errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
        .padding()
        .task {
            await checkiCloudStatus()
        }
    }
    
    private func checkiCloudStatus() async {
        isChecking = true
        defer { isChecking = false }
        
        do {
            let status = try await CloudKitService.shared.checkAccountStatus()
            await MainActor.run {
                self.accountStatus = status
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to check iCloud status: \(error.localizedDescription)"
            }
        }
    }
}


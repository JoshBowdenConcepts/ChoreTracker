//
//  ReviewQueueView.swift
//  ChoreTracker
//
//  Created on 2025-12-16.
//

import SwiftUI
import CoreData

struct ReviewQueueView: View {
    @StateObject private var viewModel: ReviewQueueViewModel
    @Environment(\.dismiss) private var dismiss
    
    init(context: NSManagedObjectContext? = nil) {
        _viewModel = StateObject(wrappedValue: ReviewQueueViewModel(context: context))
    }
    
    var body: some View {
        NavigationStack {
            List {
                if !viewModel.supervisedUsers.isEmpty {
                    Section("Filter by User") {
                        Picker("Supervised User", selection: $viewModel.selectedSupervisedUser) {
                            Text("All Users").tag(nil as User?)
                            ForEach(viewModel.supervisedUsers, id: \.id) { user in
                                Text(user.name ?? "Unknown").tag(user as User?)
                            }
                        }
                    }
                }
                
                Section {
                    if viewModel.filteredReviews.isEmpty {
                        ContentUnavailableView(
                            "No Reviews Pending",
                            systemImage: "checkmark.circle",
                            description: Text("All supervised account completions have been reviewed")
                        )
                    } else {
                        ForEach(viewModel.filteredReviews, id: \.id) { instance in
                            NavigationLink(destination: ReviewDetailView(instance: instance, viewModel: viewModel)) {
                                ReviewQueueRow(instance: instance)
                            }
                        }
                    }
                } header: {
                    Text("Pending Reviews (\(viewModel.filteredReviews.count))")
                }
            }
            .navigationTitle("Review Queue")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .refreshable {
                await viewModel.loadPendingReviews()
            }
            .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") {
                    viewModel.errorMessage = nil
                }
            } message: {
                if let error = viewModel.errorMessage {
                    Text(error)
                }
            }
        }
    }
}

struct ReviewQueueRow: View {
    let instance: ChoreInstance
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(instance.template?.name ?? "Unknown Chore")
                    .font(.headline)
                
                if let assignedTo = instance.template?.assignedTo {
                    Text("Assigned to: \(assignedTo.name ?? "Unknown")")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if let completedAt = instance.completedAt {
                    Text("Completed: \(completedAt, style: .relative)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            Spacer()
            
            Image(systemName: "exclamationmark.circle.fill")
                .foregroundColor(.orange)
        }
    }
}

struct ReviewDetailView: View {
    let instance: ChoreInstance
    @ObservedObject var viewModel: ReviewQueueViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var rejectionReason: String = ""
    @State private var showingRejectDialog = false
    
    var body: some View {
        Form {
            Section("Chore Details") {
                HStack {
                    Text("Chore")
                    Spacer()
                    Text(instance.template?.name ?? "Unknown")
                        .foregroundColor(.secondary)
                }
                
                if let description = instance.template?.choreDescription {
                    HStack {
                        Text("Description")
                        Spacer()
                        Text(description)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.trailing)
                    }
                }
                
                if let assignedTo = instance.template?.assignedTo {
                    HStack {
                        Text("Assigned To")
                        Spacer()
                    Text(assignedTo.name ?? "Unknown")
                            .foregroundColor(.secondary)
                    }
                }
                
                if let dueDate = instance.dueDate {
                    HStack {
                        Text("Due Date")
                        Spacer()
                        Text(dueDate, style: .date)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Section("Completion Details") {
                if let completedAt = instance.completedAt {
                    HStack {
                        Text("Completed At")
                        Spacer()
                        Text(completedAt, style: .date)
                            .foregroundColor(.secondary)
                    }
                }
                
                if let completedBy = instance.completedBy {
                    HStack {
                        Text("Completed By")
                        Spacer()
                        Text(completedBy.name ?? "Unknown")
                            .foregroundColor(.secondary)
                    }
                }
                
                if instance.actualDuration > 0 {
                    HStack {
                        Text("Duration")
                        Spacer()
                        Text(instance.actualDuration.formattedDuration())
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Section {
                Button(role: .destructive, action: {
                    showingRejectDialog = true
                }) {
                    HStack {
                        Spacer()
                        Text("Reject")
                            .fontWeight(.semibold)
                        Spacer()
                    }
                }
                
                Button(action: {
                    Task {
                        await viewModel.approveReview(instance)
                        dismiss()
                    }
                }) {
                    HStack {
                        Spacer()
                        Text("Approve")
                            .fontWeight(.semibold)
                        Spacer()
                    }
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .navigationTitle("Review Chore")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Reject Completion", isPresented: $showingRejectDialog) {
            TextField("Reason (optional)", text: $rejectionReason)
            Button("Cancel", role: .cancel) {
                rejectionReason = ""
            }
            Button("Reject", role: .destructive) {
                Task {
                    await viewModel.rejectReview(instance, reason: rejectionReason.isEmpty ? nil : rejectionReason)
                    rejectionReason = ""
                    dismiss()
                }
            }
        } message: {
            Text("Provide an optional reason for rejecting this completion.")
        }
    }
}


//
//  ChoreDetailView.swift
//  ChoreTracker
//
//  Created on 2025-12-16.
//

import SwiftUI

struct ChoreDetailView: View {
    let template: ChoreTemplate
    @ObservedObject var viewModel: ChoreListViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showingEditView = false
    
    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text(template.name ?? "Unnamed Chore")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    if let description = template.choreDescription, !description.isEmpty {
                        Text(description)
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.vertical, 4)
            }
            
            Section("Details") {
                HStack {
                    Text("Category")
                    Spacer()
                    Text(template.category ?? "General")
                        .foregroundColor(.secondary)
                }
                
                if template.estimatedDuration > 0 {
                    HStack {
                        Text("Estimated Duration")
                        Spacer()
                        Text(template.estimatedDuration.formattedDuration())
                            .foregroundColor(.secondary)
                    }
                }
                
                if let recurrenceRule = template.recurrenceRule {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Recurrence")
                            .font(.headline)
                        Text(RecurrenceEngine.description(for: recurrenceRule))
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }
                
                if let createdAt = template.createdAt {
                    HStack {
                        Text("Created")
                        Spacer()
                        Text(createdAt.formattedDateOnly())
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Section("Instances") {
                let instances = template.instances?.allObjects as? [ChoreInstance] ?? []
                if instances.isEmpty {
                    Text("No instances yet")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(instances.sorted(by: { 
                        let date0 = $0.dueDate ?? Date.distantPast
                        let date1 = $1.dueDate ?? Date.distantPast
                        return date0 < date1
                    }), id: \.id) { instance in
                        NavigationLink(value: instance) {
                            ChoreInstanceRow(instance: instance)
                        }
                    }
                }
            }
        }
        .navigationTitle("Chore Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Edit") {
                    showingEditView = true
                }
            }
        }
        .sheet(isPresented: $showingEditView) {
            // Edit view would go here in a future update
            Text("Edit functionality coming soon")
        }
    }
}

struct ChoreInstanceDetailView: View {
    let instance: ChoreInstance
    @ObservedObject var viewModel: ChoreListViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showingCompletionView = false
    
    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    if let template = instance.template {
                        Text(template.name ?? "Unnamed Chore")
                            .font(.title2)
                            .fontWeight(.bold)
                    } else {
                        Text("Unknown Chore")
                            .font(.title2)
                            .fontWeight(.bold)
                    }
                    
                    if let dueDate = instance.dueDate {
                        Text(dueDate.formattedForChoreList())
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.vertical, 4)
            }
            
            Section("Status") {
                HStack {
                    Text("Status")
                    Spacer()
                    Text((instance.status ?? "unknown").capitalized)
                        .foregroundColor(statusColor)
                }
                
                if instance.status == "completed", let completedAt = instance.completedAt {
                    HStack {
                        Text("Completed")
                        Spacer()
                        Text(completedAt.formattedForChoreList())
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            if instance.status == "pending" {
                Section {
                    Button(action: {
                        showingCompletionView = true
                    }) {
                        HStack {
                            Spacer()
                            Text("Mark Complete")
                                .fontWeight(.semibold)
                            Spacer()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .accessibilityLabel("Mark chore as complete")
                    .accessibilityHint("Opens completion screen where you can record time spent")
                    
                    Button(action: {
                        Task {
                            await viewModel.markInstanceSkipped(instance)
                            dismiss()
                        }
                    }) {
                        HStack {
                            Spacer()
                            Text("Skip")
                            Spacer()
                        }
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
        .sheet(isPresented: $showingCompletionView) {
            ChoreCompletionView(instance: instance, viewModel: viewModel)
        }
        .navigationTitle("Chore Instance")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private var statusColor: Color {
        switch instance.status ?? "unknown" {
        case "completed":
            return .green
        case "pending_review":
            return .orange
        case "skipped":
            return .gray
        default:
            return .blue
        }
    }
}


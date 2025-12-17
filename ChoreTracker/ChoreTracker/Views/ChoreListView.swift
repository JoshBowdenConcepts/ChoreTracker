//
//  ChoreListView.swift
//  ChoreTracker
//
//  Created on 2025-12-16.
//

import SwiftUI

struct ChoreListView: View {
    @ObservedObject var viewModel: ChoreListViewModel
    @State private var showingCreateView = false
    @State private var showingUserManagement = false
    @State private var showingSupervisedAccounts = false
    @State private var showingReviewQueue = false
    @State private var showingStatistics = false
    @State private var selectedFilter: FilterOption = .all
    
    enum FilterOption: String, CaseIterable {
        case all = "All"
        case pending = "Pending"
        case completed = "Completed"
        case overdue = "Overdue"
        case pendingReview = "Pending Review"
    }
    
    var body: some View {
        List {
            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, alignment: .center)
            } else {
                // Templates Section
                if !viewModel.choreTemplates.isEmpty {
                    Section("Chore Templates") {
                        ForEach(viewModel.choreTemplates, id: \.id) { template in
                            NavigationLink(value: template) {
                                ChoreTemplateRow(template: template)
                            }
                        }
                    }
                }
                
                // Instances Section
                let filteredInstances = filteredInstances
                if !filteredInstances.isEmpty {
                    Section("Chores") {
                        ForEach(filteredInstances, id: \.id) { instance in
                            NavigationLink(value: instance) {
                                ChoreInstanceRow(instance: instance)
                            }
                        }
                    }
                } else if !viewModel.isLoading {
                    ContentUnavailableView(
                        "No chores",
                        systemImage: "checklist",
                        description: Text("Create a chore template to get started")
                    )
                }
            }
        }
        .navigationTitle("Chore Progress")
        .navigationDestination(for: ChoreTemplate.self) { template in
            ChoreDetailView(template: template, viewModel: viewModel)
        }
        .navigationDestination(for: ChoreInstance.self) { instance in
            ChoreInstanceDetailView(instance: instance, viewModel: viewModel)
        }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Menu {
                    Button(action: {
                        showingUserManagement = true
                    }) {
                        Label("Household Members", systemImage: "person.2")
                    }
                    
                    Button(action: {
                        showingSupervisedAccounts = true
                    }) {
                        Label("Supervised Accounts", systemImage: "person.fill.checkmark")
                    }
                    
                    Button(action: {
                        showingReviewQueue = true
                    }) {
                        Label("Review Queue", systemImage: "checkmark.circle.badge.questionmark")
                    }
                    
                    Divider()
                    
                    Button(action: {
                        showingStatistics = true
                    }) {
                        Label("Statistics", systemImage: "chart.bar.fill")
                    }
                } label: {
                    Image(systemName: "person.2")
                }
            }
            
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    ForEach(FilterOption.allCases, id: \.self) { option in
                        Button(action: {
                            selectedFilter = option
                        }) {
                            HStack {
                                Text(option.rawValue)
                                if selectedFilter == option {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                }
            }
            
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: {
                    showingCreateView = true
                }) {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingUserManagement) {
            UserManagementView(viewModel: viewModel)
        }
        .sheet(isPresented: $showingSupervisedAccounts) {
            SupervisedAccountManagementView(viewModel: viewModel)
        }
        .sheet(isPresented: $showingReviewQueue) {
            ReviewQueueView()
        }
        .sheet(isPresented: $showingStatistics) {
            StatisticsView()
        }
        .sheet(isPresented: $showingCreateView) {
            ChoreCreationView(viewModel: viewModel)
        }
        .refreshable {
            await viewModel.loadChores()
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
    
    private var filteredInstances: [ChoreInstance] {
        switch selectedFilter {
        case .all:
            return viewModel.choreInstances
        case .pending:
            return viewModel.pendingInstances
        case .completed:
            return viewModel.completedInstances
        case .overdue:
            return viewModel.overdueInstances
        case .pendingReview:
            return viewModel.choreInstances.filter { $0.status == "pending_review" }
        }
    }
}

// MARK: - Row Views

struct ChoreTemplateRow: View {
    let template: ChoreTemplate
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(template.name ?? "Unnamed Chore")
                .font(.headline)
            if let description = template.choreDescription, !description.isEmpty {
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            HStack {
                Text(template.category ?? "General")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(4)
                
                if let assignedTo = template.assignedTo {
                    Text(assignedTo.name ?? "Assigned")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(4)
                }
                
                Spacer()
                if template.estimatedDuration > 0 {
                    Text(template.estimatedDuration.formattedDuration())
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

struct ChoreInstanceRow: View {
    let instance: ChoreInstance
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                if let template = instance.template {
                    Text(template.name ?? "Unnamed Chore")
                        .font(.headline)
                } else {
                    Text("Unknown Chore")
                        .font(.headline)
                }
                if let dueDate = instance.dueDate {
                    Text(dueDate.formattedDateOnly())
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            if instance.isOverdue {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.red)
            }
            
            if instance.status == "completed" {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            } else if instance.status == "pending_review" {
                Image(systemName: "clock.fill")
                    .foregroundColor(.orange)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Navigation Support
// Note: ChoreTemplate and ChoreInstance already conform to Hashable through NSManagedObject
// No need to add explicit conformance


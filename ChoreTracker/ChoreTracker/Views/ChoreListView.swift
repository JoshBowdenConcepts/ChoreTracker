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
    @State private var showingSettings = false
    @State private var selectedFilter: FilterOption = .all
    @State private var searchText = ""
    
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
                loadingSection
            } else {
                templatesSection
                instancesSection
            }
        }
        .searchable(text: $searchText, prompt: "Search chores...")
        .navigationTitle("Chore Progress")
        .accessibilityLabel("Chore Progress List")
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
                    
                    Divider()
                    
                    Button(action: {
                        showingSettings = true
                    }) {
                        Label("Settings", systemImage: "gearshape.fill")
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
        .sheet(isPresented: $showingSettings) {
            SettingsView()
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
    
    // MARK: - View Components
    
    private var loadingSection: some View {
        Section {
            HStack {
                Spacer()
                ProgressView()
                    .padding()
                Spacer()
            }
        }
    }
    
    @ViewBuilder
    private var templatesSection: some View {
        let filteredTemplates = filteredTemplates
        if !filteredTemplates.isEmpty {
            Section("Chore Templates") {
                ForEach(filteredTemplates, id: \.id) { template in
                    NavigationLink(value: template) {
                        ChoreTemplateRow(template: template)
                    }
                }
            }
        }
    }
    
    private var filteredTemplates: [ChoreTemplate] {
        if searchText.isEmpty {
            return viewModel.choreTemplates
        }
        return viewModel.choreTemplates.filter { template in
            let name = template.name?.lowercased() ?? ""
            let description = template.choreDescription?.lowercased() ?? ""
            let category = template.category?.lowercased() ?? ""
            let search = searchText.lowercased()
            return name.contains(search) || description.contains(search) || category.contains(search)
        }
    }
    
    @ViewBuilder
    private var instancesSection: some View {
        if !filteredInstances.isEmpty {
            Section("Chores") {
                ForEach(filteredInstances, id: \.id) { instance in
                    NavigationLink(value: instance) {
                        ChoreInstanceRow(instance: instance)
                    }
                }
            }
        } else {
            Section {
                VStack(spacing: 16) {
                    Image(systemName: "checklist")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    Text("No Chores Yet")
                        .font(.headline)
                    Text("Create your first chore template to get started with tracking your progress")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    Button("Create Chore") {
                        showingCreateView = true
                    }
                    .buttonStyle(.borderedProminent)
                }
                .frame(maxWidth: .infinity)
                .padding()
            }
        }
    }
    
    private var filteredInstances: [ChoreInstance] {
        let baseInstances: [ChoreInstance]
        switch selectedFilter {
        case .all:
            baseInstances = viewModel.choreInstances
        case .pending:
            baseInstances = viewModel.pendingInstances
        case .completed:
            baseInstances = viewModel.completedInstances
        case .overdue:
            baseInstances = viewModel.overdueInstances
        case .pendingReview:
            baseInstances = viewModel.choreInstances.filter { $0.status == "pending_review" }
        }
        
        // Apply search filter if active
        if searchText.isEmpty {
            return baseInstances
        }
        
        let search = searchText.lowercased()
        return baseInstances.filter { instance in
            let templateName = instance.template?.name?.lowercased() ?? ""
            let templateDescription = instance.template?.choreDescription?.lowercased() ?? ""
            let templateCategory = instance.template?.category?.lowercased() ?? ""
            return templateName.contains(search) || templateDescription.contains(search) || templateCategory.contains(search)
        }
    }
}

// MARK: - Row Views

struct ChoreTemplateRow: View {
    let template: ChoreTemplate
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(template.name ?? "Unnamed Chore")
                    .font(.headline)
                
                Spacer()
                
                // Sync status indicator
                let syncStatus = SyncStatusHelper.syncStatusIcon(for: template)
                Image(systemName: syncStatus.icon)
                    .font(.caption)
                    .foregroundColor(syncStatus.color)
                    .accessibilityLabel(SyncStatusHelper.isSynced(template) ? "Synced to iCloud" : "Syncing to iCloud")
            }
            
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
                HStack {
                    if let template = instance.template {
                        Text(template.name ?? "Unnamed Chore")
                            .font(.headline)
                    } else {
                        Text("Unknown Chore")
                            .font(.headline)
                    }
                    
                    // Sync status indicator
                    let syncStatus = SyncStatusHelper.syncStatusIcon(for: instance)
                    Image(systemName: syncStatus.icon)
                        .font(.caption2)
                        .foregroundColor(syncStatus.color)
                        .accessibilityLabel(SyncStatusHelper.isSynced(instance) ? "Synced to iCloud" : "Syncing to iCloud")
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




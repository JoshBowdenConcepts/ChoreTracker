//
//  ChoreEditView.swift
//  ChoreTracker
//
//  Created on 2025-12-16.
//

import SwiftUI

struct ChoreEditView: View {
    let template: ChoreTemplate
    @ObservedObject var viewModel: ChoreListViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var name: String
    @State private var description: String
    @State private var category: String
    @State private var estimatedHours: Int
    @State private var estimatedMinutes: Int
    @State private var recurrenceRule: RecurrenceRule?
    @State private var showingRecurrenceBuilder = false
    @State private var selectedUser: User?
    
    private let categories = ["General", "Indoor", "Outdoor", "Kitchen", "Bathroom", "Bedroom", "Weekly", "Monthly"]
    
    init(template: ChoreTemplate, viewModel: ChoreListViewModel) {
        self.template = template
        self.viewModel = viewModel
        
        _name = State(initialValue: template.name ?? "")
        _description = State(initialValue: template.choreDescription ?? "")
        _category = State(initialValue: template.category ?? "General")
        
        let totalMinutes = Int((template.estimatedDuration / 60).rounded())
        _estimatedHours = State(initialValue: totalMinutes / 60)
        _estimatedMinutes = State(initialValue: totalMinutes % 60)
        
        _recurrenceRule = State(initialValue: template.recurrenceRule)
        _selectedUser = State(initialValue: template.assignedTo)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Chore Information") {
                    TextField("Chore Name", text: $name)
                        .textInputAutocapitalization(.words)
                    
                    TextField("Description (optional)", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                        .textInputAutocapitalization(.sentences)
                    
                    Picker("Category", selection: $category) {
                        ForEach(categories, id: \.self) { category in
                            Text(category).tag(category)
                        }
                    }
                }
                
                Section("Estimated Duration") {
                    HStack {
                        Picker("Hours", selection: $estimatedHours) {
                            ForEach(0..<24) { hour in
                                Text("\(hour)").tag(hour)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(width: 80)
                        
                        Text("hours")
                            .foregroundColor(.secondary)
                        
                        Picker("Minutes", selection: $estimatedMinutes) {
                            ForEach([0, 5, 10, 15, 30, 45], id: \.self) { minute in
                                Text("\(minute)").tag(minute)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(width: 80)
                        
                        Text("minutes")
                            .foregroundColor(.secondary)
                    }
                }
                
                Section("Assignment") {
                    Picker("Assign To", selection: $selectedUser) {
                        Text("Unassigned").tag(nil as User?)
                        ForEach(viewModel.householdUsers, id: \.id) { user in
                            Text(user.name ?? "Unknown").tag(user as User?)
                        }
                    }
                }
                
                Section("Recurrence") {
                    Button(action: {
                        showingRecurrenceBuilder = true
                    }) {
                        HStack {
                            Text("Repeat Pattern")
                            Spacer()
                            if let rule = recurrenceRule {
                                Text(RecurrenceEngine.description(for: rule))
                                    .foregroundColor(.secondary)
                                    .font(.caption)
                            } else {
                                Text("None")
                                    .foregroundColor(.secondary)
                            }
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                    }
                    
                    if recurrenceRule != nil {
                        Button(role: .destructive, action: {
                            recurrenceRule = nil
                        }) {
                            Text("Remove Recurrence")
                        }
                    }
                }
                
                Section {
                    Button(action: {
                        Task {
                            await saveChanges()
                        }
                    }) {
                        HStack {
                            Spacer()
                            Text("Save Changes")
                                .fontWeight(.semibold)
                            Spacer()
                        }
                    }
                    .disabled(name.isEmpty || viewModel.isLoading)
                    .overlay {
                        if viewModel.isLoading {
                            ProgressView()
                        }
                    }
                }
            }
            .navigationTitle("Edit Chore")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingRecurrenceBuilder) {
                RecurrenceBuilderView(recurrenceRule: $recurrenceRule)
            }
        }
    }
    
    private func saveChanges() async {
        template.name = name
        template.choreDescription = description.isEmpty ? nil : description
        template.category = category
        template.estimatedDuration = Double(estimatedHours * 3600 + estimatedMinutes * 60)
        template.assignedTo = selectedUser
        template.recurrenceRule = recurrenceRule
        
        do {
            try await viewModel.updateChoreTemplate(template)
            dismiss()
        } catch {
            // Error is handled by viewModel
        }
    }
}






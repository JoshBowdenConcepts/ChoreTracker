//
//  ChoreCreationView.swift
//  ChoreTracker
//
//  Created on 2025-12-16.
//

import SwiftUI

struct ChoreCreationView: View {
    @ObservedObject var viewModel: ChoreListViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var name = ""
    @State private var description = ""
    @State private var category = "General"
    @State private var estimatedHours = 0
    @State private var estimatedMinutes = 15
    @State private var recurrenceRule: RecurrenceRule? = nil
    @State private var showingRecurrenceBuilder = false
    
    private let categories = ["General", "Indoor", "Outdoor", "Kitchen", "Bathroom", "Bedroom", "Weekly", "Monthly"]
    
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
                            await viewModel.createChoreTemplate(
                                name: name,
                                description: description.isEmpty ? nil : description,
                                category: category,
                                recurrenceRule: recurrenceRule
                            )
                            dismiss()
                        }
                    }) {
                        HStack {
                            Spacer()
                            Text("Create Chore")
                                .fontWeight(.semibold)
                            Spacer()
                        }
                    }
                    .disabled(name.isEmpty || viewModel.isLoading)
                }
            }
            .navigationTitle("New Chore")
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
}


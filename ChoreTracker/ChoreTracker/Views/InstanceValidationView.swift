//
//  InstanceValidationView.swift
//  ChoreTracker
//
//  Created on 2025-12-16.
//

import SwiftUI
import CoreData

struct InstanceValidationView: View {
    let template: ChoreTemplate
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var validationResult: InstanceValidator.ValidationResult?
    @State private var isFixing = false
    @State private var showFixConfirmation = false
    
    var body: some View {
        NavigationStack {
            List {
                if let result = validationResult {
                    if result.isValid {
                        Section {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text("All instances are valid")
                                    .font(.headline)
                            }
                            .padding(.vertical, 8)
                        }
                    } else {
                        // Missing instances
                        if !result.missingDates.isEmpty {
                            Section {
                                HStack {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundColor(.orange)
                                    Text("Missing Instances")
                                        .font(.headline)
                                }
                                
                                ForEach(result.missingDates, id: \.self) { date in
                                    HStack {
                                        Text(date, style: .date)
                                            .foregroundColor(.secondary)
                                        Spacer()
                                        Text("Should exist")
                                            .font(.caption)
                                            .foregroundColor(.orange)
                                    }
                                }
                            } header: {
                                Text("\(result.missingDates.count) Missing")
                            }
                        }
                        
                        // Duplicate instances
                        if !result.duplicateDates.isEmpty {
                            Section {
                                HStack {
                                    Image(systemName: "exclamationmark.circle.fill")
                                        .foregroundColor(.red)
                                    Text("Duplicate Instances")
                                        .font(.headline)
                                }
                                
                                ForEach(result.duplicateDates, id: \.self) { date in
                                    HStack {
                                        Text(date, style: .date)
                                            .foregroundColor(.secondary)
                                        Spacer()
                                        Text("Multiple instances")
                                            .font(.caption)
                                            .foregroundColor(.red)
                                    }
                                }
                            } header: {
                                Text("\(result.duplicateDates.count) Duplicates")
                            }
                        }
                        
                        // Extra instances
                        if !result.extraInstances.isEmpty {
                            Section {
                                HStack {
                                    Image(systemName: "minus.circle.fill")
                                        .foregroundColor(.blue)
                                    Text("Extra Instances")
                                        .font(.headline)
                                }
                                
                                ForEach(result.extraInstances, id: \.id) { instance in
                                    HStack {
                                        if let dueDate = instance.dueDate {
                                            Text(dueDate, style: .date)
                                                .foregroundColor(.secondary)
                                        }
                                        Spacer()
                                        Text("Not in schedule")
                                            .font(.caption)
                                            .foregroundColor(.blue)
                                    }
                                }
                            } header: {
                                Text("\(result.extraInstances.count) Extra")
                            }
                        }
                        
                        // Fix button
                        Section {
                            Button(action: {
                                showFixConfirmation = true
                            }) {
                                HStack {
                                    Spacer()
                                    if isFixing {
                                        ProgressView()
                                            .padding(.trailing, 8)
                                    }
                                    Text("Fix All Issues")
                                        .fontWeight(.semibold)
                                    Spacer()
                                }
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(isFixing)
                        }
                    }
                    
                    // Summary
                    Section("Summary") {
                        HStack {
                            Text("Expected Instances")
                            Spacer()
                            Text("\(result.expectedInstances.count)")
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Text("Actual Instances")
                            Spacer()
                            Text("\(result.actualInstances.count)")
                                .foregroundColor(.secondary)
                        }
                    }
                } else {
                    Section {
                        ProgressView()
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding()
                    }
                }
            }
            .navigationTitle("Validate Schedule")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .task {
                await validate()
            }
            .alert("Fix Issues", isPresented: $showFixConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Fix") {
                    Task {
                        await fixIssues()
                    }
                }
            } message: {
                Group {
                    if let result = validationResult {
                        let message = buildFixMessage(for: result)
                        Text(message)
                    } else {
                        Text("Fix validation issues?")
                    }
                }
            }
        }
    }
    
    private func validate() async {
        validationResult = InstanceValidator.validateInstances(
            for: template,
            context: viewContext
        )
    }
    
    private func buildFixMessage(for result: InstanceValidator.ValidationResult) -> String {
        var message = "This will:\n"
        if !result.missingDates.isEmpty {
            message += "• Add \(result.missingDates.count) missing instance(s)\n"
        }
        if !result.duplicateDates.isEmpty {
            message += "• Remove duplicate instance(s) for \(result.duplicateDates.count) date(s)\n"
        }
        if !result.extraInstances.isEmpty {
            message += "• Remove \(result.extraInstances.count) extra instance(s)\n"
        }
        message += "\nContinue?"
        return message
    }
    
    private func fixIssues() async {
        isFixing = true
        defer { isFixing = false }
        
        do {
            try InstanceValidator.fixValidationIssues(
                for: template,
                context: viewContext
            )
            // Re-validate after fixing
            await validate()
        } catch {
            print("Failed to fix validation issues: \(error.localizedDescription)")
        }
    }
}


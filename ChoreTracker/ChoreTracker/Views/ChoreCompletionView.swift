//
//  ChoreCompletionView.swift
//  ChoreTracker
//
//  Created on 2025-12-16.
//

import SwiftUI

struct ChoreCompletionView: View {
    let instance: ChoreInstance
    @ObservedObject var viewModel: ChoreListViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var hours = 0
    @State private var minutes = 0
    @State private var trackingTime = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Chore") {
                    Text(instance.template?.name ?? "Unknown Chore")
                        .font(.headline)
                    
                    if let description = instance.template?.choreDescription, !description.isEmpty {
                        Text(description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Section("Time Tracking") {
                    Toggle("Track Time", isOn: $trackingTime)
                    
                    if trackingTime {
                        HStack {
                            Picker("Hours", selection: $hours) {
                                ForEach(0..<24) { hour in
                                    Text("\(hour)").tag(hour)
                                }
                            }
                            .pickerStyle(.wheel)
                            .frame(width: 80)
                            
                            Text("hours")
                                .foregroundColor(.secondary)
                            
                            Picker("Minutes", selection: $minutes) {
                                ForEach(Array(stride(from: 0, to: 60, by: 5)), id: \.self) { minute in
                                    Text("\(minute)").tag(minute)
                                }
                            }
                            .pickerStyle(.wheel)
                            .frame(width: 80)
                            
                            Text("minutes")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Section {
                    Button(action: {
                        let duration: TimeInterval? = trackingTime ? TimeInterval(hours * 3600 + minutes * 60) : nil
                        Task {
                            await viewModel.markInstanceComplete(instance, duration: duration)
                            dismiss()
                        }
                    }) {
                        HStack {
                            Spacer()
                            Text("Mark Complete")
                                .fontWeight(.semibold)
                            Spacer()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .navigationTitle("Complete Chore")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}


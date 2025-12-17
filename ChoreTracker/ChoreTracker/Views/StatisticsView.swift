//
//  StatisticsView.swift
//  ChoreTracker
//
//  Created on 2025-12-16.
//

import SwiftUI
import Charts
import CoreData

struct StatisticsView: View {
    @StateObject private var viewModel: StatisticsViewModel
    @Environment(\.dismiss) private var dismiss
    
    init(context: NSManagedObjectContext? = nil) {
        _viewModel = StateObject(wrappedValue: StatisticsViewModel(context: context))
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Big Number Metrics
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        BigNumberCard(
                            title: "Completed",
                            value: "\(viewModel.totalChoresCompleted)",
                            icon: "checkmark.circle.fill",
                            color: .green
                        )
                        
                        BigNumberCard(
                            title: "Time Spent",
                            value: viewModel.totalTimeSpent.formattedDuration(),
                            icon: "clock.fill",
                            color: .blue
                        )
                        
                        BigNumberCard(
                            title: "Current Streak",
                            value: "\(viewModel.currentStreak) days",
                            icon: "flame.fill",
                            color: .orange
                        )
                        
                        BigNumberCard(
                            title: "Longest Streak",
                            value: "\(viewModel.longestStreak) days",
                            icon: "star.fill",
                            color: .purple
                        )
                    }
                    .padding(.horizontal)
                    
                    // Completion Rate
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Completion Rate")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        ProgressView(value: viewModel.completionRate / 100.0) {
                            HStack {
                                Text("\(Int(viewModel.completionRate))%")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Spacer()
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // Average Time
                    if viewModel.averageCompletionTime > 0 {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Average Time per Chore")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            Text(viewModel.averageCompletionTime.formattedDuration())
                                .font(.title2)
                                .fontWeight(.semibold)
                                .padding(.horizontal)
                        }
                    }
                    
                    // Streak Chart (if we have data)
                    if !viewModel.goalCompletions.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Goal Completion (Last 30 Days)")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            Chart {
                                ForEach(viewModel.goalCompletions, id: \.id) { goal in
                                    if let date = goal.date {
                                        BarMark(
                                            x: .value("Date", date, unit: .day),
                                            y: .value("Completed", goal.allChoresCompleted ? 1 : 0)
                                        )
                                        .foregroundStyle(goal.allChoresCompleted ? .green : .red)
                                    }
                                }
                            }
                            .frame(height: 200)
                            .padding()
                        }
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Statistics")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .refreshable {
                await viewModel.loadStatistics()
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

struct BigNumberCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title)
                .foregroundColor(color)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}


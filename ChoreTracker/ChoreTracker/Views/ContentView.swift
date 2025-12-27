//
//  ContentView.swift
//  ChoreTracker
//
//  Created on 2025-12-16.
//

import SwiftUI
import CoreData

struct ContentView: View {
    @StateObject private var viewModel = ChoreListViewModel()
    @State private var showSplash = true
    
    var body: some View {
        Group {
            if showSplash {
                SplashView()
                    .transition(.opacity)
            } else {
                NavigationStack {
                    ChoreListView(viewModel: viewModel)
                }
                .transition(.opacity)
            }
        }
        .task {
            // Wait for initial data to load
            await viewModel.loadInitialData()
            
            // Hide splash screen with animation
            withAnimation(.easeOut(duration: 0.3)) {
                showSplash = false
            }
        }
    }
}

#Preview {
    ContentView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}


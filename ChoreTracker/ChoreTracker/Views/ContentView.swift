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
    
    var body: some View {
        NavigationStack {
            ChoreListView(viewModel: viewModel)
        }
    }
}

#Preview {
    ContentView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}


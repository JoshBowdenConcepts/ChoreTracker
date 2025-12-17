//
//  UserManagementView.swift
//  ChoreTracker
//
//  Created on 2025-12-16.
//

import SwiftUI
import CoreData

struct UserManagementView: View {
    @ObservedObject var viewModel: ChoreListViewModel
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var showingAddUser = false
    @State private var newUserName = ""
    @State private var newUserType = "parent"
    @State private var newUserEmail: String? = nil
    
    var body: some View {
        NavigationStack {
            List {
                Section("Household Members") {
                    ForEach(viewModel.householdUsers, id: \.id) { user in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(user.name ?? "Unknown")
                                    .font(.headline)
                                Text(user.userType ?? "parent")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                if let email = user.email {
                                    Text(email)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            Spacer()
                            if user.isMinor {
                                Text("Minor")
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.orange.opacity(0.2))
                                    .cornerRadius(4)
                            }
                        }
                    }
                }
                
                Section {
                    Button(action: {
                        showingAddUser = true
                    }) {
                        HStack {
                            Image(systemName: "person.badge.plus")
                            Text("Add Household Member")
                        }
                    }
                }
            }
            .navigationTitle("Household")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingAddUser) {
                AddUserView(
                    userName: $newUserName,
                    userType: $newUserType,
                    userEmail: Binding(
                        get: { newUserEmail ?? "" },
                        set: { newUserEmail = $0.isEmpty ? nil : $0 }
                    ),
                    onSave: {
                        Task {
                            await addUser()
                        }
                    }
                )
            }
        }
    }
    
    private func addUser() async {
        guard !newUserName.isEmpty else { return }
        
        _ = User.create(
            context: viewContext,
            name: newUserName,
            userType: newUserType,
            email: newUserEmail
        )
        
        do {
            try viewContext.save()
            await viewModel.loadChores()
            newUserName = ""
            newUserType = "parent"
            newUserEmail = nil
            showingAddUser = false
        } catch {
            viewModel.errorMessage = "Failed to add user: \(error.localizedDescription)"
        }
    }
}

struct AddUserView: View {
    @Binding var userName: String
    @Binding var userType: String
    @Binding var userEmail: String
    let onSave: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    private let userTypes = ["parent", "supervised", "guardian"]
    
    var body: some View {
        NavigationStack {
            Form {
                Section("User Information") {
                    TextField("Name", text: $userName)
                        .textInputAutocapitalization(.words)
                    
                    Picker("Type", selection: $userType) {
                        ForEach(userTypes, id: \.self) { type in
                            Text(type.capitalized).tag(type)
                        }
                    }
                    
                    TextField("Email (optional)", text: $userEmail)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .keyboardType(.emailAddress)
                }
            }
            .navigationTitle("Add User")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        onSave()
                        dismiss()
                    }
                    .disabled(userName.isEmpty)
                }
            }
        }
    }
}


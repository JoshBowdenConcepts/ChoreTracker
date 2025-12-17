//
//  SupervisedAccountManagementView.swift
//  ChoreTracker
//
//  Created on 2025-12-16.
//

import SwiftUI
import CoreData

struct SupervisedAccountManagementView: View {
    @ObservedObject var viewModel: ChoreListViewModel
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var showingAddSupervised = false
    @State private var newUserName = ""
    @State private var newUserEmail: String? = nil
    @State private var isMinor = true
    @State private var hasDevice = false
    @State private var showingConsent = false
    
    var supervisedUsers: [User] {
        viewModel.householdUsers.filter { $0.userType == "supervised" || $0.parentId != nil }
    }
    
    var body: some View {
        NavigationStack {
            List {
                Section("Supervised Accounts") {
                    if supervisedUsers.isEmpty {
                        Text("No supervised accounts yet")
                            .foregroundColor(.secondary)
                            .italic()
                    } else {
                        ForEach(supervisedUsers, id: \.id) { user in
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(user.name ?? "Unknown")
                                        .font(.headline)
                                    
                                    HStack(spacing: 12) {
                                        if user.isMinor {
                                            Label("Minor", systemImage: "person.fill.checkmark")
                                                .font(.caption)
                                                .foregroundColor(.orange)
                                        }
                                        
                                        if user.hasDevice {
                                            Label("Has Device", systemImage: "iphone")
                                                .font(.caption)
                                                .foregroundColor(.blue)
                                        } else {
                                            Label("No Device", systemImage: "iphone.slash")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    
                                    if let email = user.email {
                                        Text(email)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                Spacer()
                            }
                        }
                    }
                }
                
                Section {
                    Button(action: {
                        showingAddSupervised = true
                    }) {
                        HStack {
                            Image(systemName: "person.badge.plus")
                            Text("Add Supervised Account")
                        }
                    }
                }
            }
            .navigationTitle("Supervised Accounts")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingAddSupervised) {
                AddSupervisedAccountView(
                    userName: $newUserName,
                    userEmail: Binding(
                        get: { newUserEmail ?? "" },
                        set: { newUserEmail = $0.isEmpty ? nil : $0 }
                    ),
                    isMinor: $isMinor,
                    hasDevice: $hasDevice,
                    showingConsent: $showingConsent,
                    onSave: {
                        Task {
                            await addSupervisedAccount()
                        }
                    }
                )
            }
            .sheet(isPresented: $showingConsent) {
                ParentalConsentView(isPresented: $showingConsent)
            }
        }
    }
    
    private func addSupervisedAccount() async {
        guard !newUserName.isEmpty,
              let currentUser = viewModel.currentUser,
              let parentId = currentUser.id else {
            return
        }
        
        _ = User.create(
            context: viewContext,
            name: newUserName,
            userType: "supervised",
            email: newUserEmail,
            parentId: parentId,
            isMinor: isMinor,
            hasDevice: hasDevice
        )
        
        do {
            try viewContext.save()
            await viewModel.loadChores()
            newUserName = ""
            newUserEmail = nil
            isMinor = true
            hasDevice = false
            showingAddSupervised = false
        } catch {
            viewModel.errorMessage = "Failed to add supervised account: \(error.localizedDescription)"
        }
    }
}

struct AddSupervisedAccountView: View {
    @Binding var userName: String
    @Binding var userEmail: String
    @Binding var isMinor: Bool
    @Binding var hasDevice: Bool
    @Binding var showingConsent: Bool
    let onSave: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Account Information") {
                    TextField("Name", text: $userName)
                        .textInputAutocapitalization(.words)
                    
                    TextField("Email (optional)", text: $userEmail)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .keyboardType(.emailAddress)
                }
                
                Section("Account Settings") {
                    Toggle("Is Minor", isOn: $isMinor)
                    
                    Toggle("Has Own Device", isOn: $hasDevice)
                    
                    if !hasDevice {
                        Text("If the supervised user doesn't have a device, you'll manage all their chores on their behalf.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                if isMinor {
                    Section {
                        Button(action: {
                            showingConsent = true
                        }) {
                            HStack {
                                Image(systemName: "doc.text")
                                Text("View Parental Consent Information")
                            }
                        }
                    }
                }
            }
            .navigationTitle("Add Supervised Account")
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

struct ParentalConsentView: View {
    @Binding var isPresented: Bool
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Parental Consent & Privacy")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("By creating a supervised account, you acknowledge:")
                        .font(.headline)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        ConsentBullet(text: "You are the parent or legal guardian of this account")
                        ConsentBullet(text: "All data is stored in your iCloud account")
                        ConsentBullet(text: "No data is shared with third parties")
                        ConsentBullet(text: "You can delete all data at any time")
                        ConsentBullet(text: "Completions require your review and approval")
                        ConsentBullet(text: "You maintain full control over the account")
                    }
                    
                    Text("This app complies with COPPA (Children's Online Privacy Protection Act) requirements.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top)
                }
                .padding()
            }
            .navigationTitle("Consent Information")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        isPresented = false
                    }
                }
            }
        }
    }
}

struct ConsentBullet: View {
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
                .font(.caption)
            Text(text)
                .font(.body)
            Spacer()
        }
    }
}


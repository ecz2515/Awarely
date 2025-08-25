//
//  ContentView.swift
//  Awarely
//
//  Created by Evan Chen on 8/23/25.
//

import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0
    @State private var entries: [LogEntry] = []
    @State private var newEntry: String = ""
    @State private var selectedTags: Set<String> = []
    @State private var customTags: [String] = ["Read a book", "Practice violin", "Work on startup", "Journal", "Practice German", "Exercise", "Practice conducting", "Take multivitamins", "Meditate", "Work", "Work meetings"]
    @FocusState private var isFieldFocused: Bool
    @State private var notificationEnabled = true
    @State private var reminderInterval: TimeInterval = 30 * 60 // 30 minutes
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView(entries: $entries)
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Home")
                }
                .tag(0)
            
            LogView(
                entries: $entries,
                newEntry: $newEntry,
                selectedTags: $selectedTags,
                customTags: $customTags,
                isFieldFocused: _isFieldFocused
            )
            .tabItem {
                Image(systemName: "plus.circle.fill")
                Text("Log")
            }
            .tag(1)
            
            ProfileView(
                notificationEnabled: $notificationEnabled,
                reminderInterval: $reminderInterval,
                entries: $entries
            )
            .tabItem {
                Image(systemName: "person.circle.fill")
                Text("Profile")
            }
            .tag(2)
        }
        .accentColor(.blue)
        .onAppear {
            loadSampleData()
        }
    }
    
    private func loadSampleData() {
        // Add some sample entries for demonstration
        if entries.isEmpty {
            entries = [
            ]
        }
    }
}

#Preview {
    ContentView()
}

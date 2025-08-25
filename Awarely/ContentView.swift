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
    @FocusState private var isFieldFocused: Bool
    @State private var notificationEnabled = true
    @State private var reminderInterval: TimeInterval = 30 * 60 // 30 minutes
    
    // Common tags for quick selection
    let commonTags = [
        "Work", "Study", "Exercise", "Social", "Chores", 
        "Entertainment", "Reading", "Cooking", "Travel", "Rest"
    ]
    
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
                isFieldFocused: _isFieldFocused,
                commonTags: commonTags
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
                LogEntry(text: "Had morning coffee and checked emails", tags: ["Work"], timestamp: Date().addingTimeInterval(-3600)),
                LogEntry(text: "Went for a 30-minute walk", tags: ["Exercise"], timestamp: Date().addingTimeInterval(-1800)),
                LogEntry(text: "Read a chapter of my book", tags: ["Reading"], timestamp: Date().addingTimeInterval(-900))
            ]
        }
    }
}

#Preview {
    ContentView()
}

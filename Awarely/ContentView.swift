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
    @StateObject private var intervalTimer = IntervalTimer()
    @State private var shouldNavigateToHome = false
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView(entries: $entries, intervalTimer: intervalTimer)
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
                isFieldFocused: _isFieldFocused,
                intervalTimer: intervalTimer,
                shouldNavigateToHome: $shouldNavigateToHome
            )
            .tabItem {
                Image(systemName: "plus.circle.fill")
                Text("Log")
            }
            .tag(1)
            
            ProfileView(
                notificationEnabled: $notificationEnabled,
                reminderInterval: $reminderInterval,
                entries: $entries,
                intervalTimer: intervalTimer
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
            NotificationManager.shared.requestPermission()
        }
        .onChange(of: shouldNavigateToHome) { _, newValue in
            if newValue {
                selectedTab = 0
                shouldNavigateToHome = false
            }
        }
    }
    
    private func loadSampleData() {
        // Add some sample entries for demonstration
        if entries.isEmpty {
            _ = Calendar.current
            _ = Date()
            
            // Get the previous intervals using the interval timer logic
            let currentIntervalStart = getCurrentIntervalStart()
            let previousIntervalStart = currentIntervalStart.addingTimeInterval(-30 * 60) // 30 minutes back
            let previousIntervalEnd = currentIntervalStart
            
            let twoIntervalsAgoStart = previousIntervalStart.addingTimeInterval(-30 * 60)
            let twoIntervalsAgoEnd = previousIntervalStart
            
            let threeIntervalsAgoStart = twoIntervalsAgoStart.addingTimeInterval(-30 * 60)
            let threeIntervalsAgoEnd = twoIntervalsAgoStart
            
            // Create sample entries for the last few intervals
            let sampleEntries = [
                LogEntry(
                    text: "Worked on project documentation and reviewed code",
                    tags: ["Work", "Documentation"],
                    timestamp: previousIntervalStart.addingTimeInterval(15 * 60), // 15 minutes into the interval
                    timePeriodStart: previousIntervalStart,
                    timePeriodEnd: previousIntervalEnd
                ),
                LogEntry(
                    text: "Practiced violin for 25 minutes, focused on scales and etudes",
                    tags: ["Music", "Practice"],
                    timestamp: twoIntervalsAgoStart.addingTimeInterval(10 * 60), // 10 minutes into the interval
                    timePeriodStart: twoIntervalsAgoStart,
                    timePeriodEnd: twoIntervalsAgoEnd
                ),
                LogEntry(
                    text: "Read chapter 3 of 'Atomic Habits' and took notes",
                    tags: ["Reading", "Learning"],
                    timestamp: threeIntervalsAgoStart.addingTimeInterval(20 * 60), // 20 minutes into the interval
                    timePeriodStart: threeIntervalsAgoStart,
                    timePeriodEnd: threeIntervalsAgoEnd
                )
            ]
            
            entries = sampleEntries
        }
    }
    
    // Helper function to get current interval start (copied from IntervalTimer logic)
    private func getCurrentIntervalStart() -> Date {
        let calendar = Calendar.current
        let now = Date()
        
        // Get the current minute
        let currentMinute = calendar.component(.minute, from: now)
        
        // Calculate the start of the current interval
        let intervalStartMinute: Int
        if currentMinute < 30 {
            intervalStartMinute = 0
        } else {
            intervalStartMinute = 30
        }
        
        // Create the interval start date
        var components = calendar.dateComponents([.year, .month, .day, .hour], from: now)
        components.minute = intervalStartMinute
        components.second = 0
        
        return calendar.date(from: components) ?? now
    }
}

#Preview {
    ContentView()
}

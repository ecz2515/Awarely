//
//  ContentView.swift
//  Awarely
//
//  Created by Evan Chen on 8/23/25.
//

import SwiftUI

// MARK: - Keyboard Dismissal Modifier
struct KeyboardDismissalModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture {
                        hideKeyboard()
                    }
            )
    }
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

extension View {
    func dismissKeyboardOnTap() -> some View {
        self.modifier(KeyboardDismissalModifier())
    }
}

struct ContentView: View {
    @State private var selectedTab = 0
    @State private var entries: [LogEntry] = []
    @State private var newEntry: String = ""
    @State private var selectedTags: Set<String> = []
    @State private var customTags: [String] = ["Read", "Practice", "Work", "Journal", "Exercise", "Meditate", "Meetings"]
    @FocusState private var isFieldFocused: Bool
    @State private var notificationEnabled = true
    @State private var reminderInterval: TimeInterval = 30 * 60 // Default to 30 minutes
    @StateObject private var intervalTimer = IntervalTimer()
    @State private var shouldNavigateToHome = false
    @State private var showOnboarding = false
    
    // Set this to true to force onboarding, false to use normal logic
    private let forceOnboardingFlag = false
    
    @EnvironmentObject var coreDataManager: CoreDataManager
    
    var body: some View {
        Group {
            if showOnboarding {
                OnboardingView()
                    .onReceive(NotificationCenter.default.publisher(for: .profileCreated)) { _ in
                        showOnboarding = false
                        loadDataFromCoreData()
                        // Request notification permission after onboarding is complete
                        NotificationManager.shared.requestPermission()
                    }
            } else {
                mainAppView
            }
        }
        .onAppear {
            checkFirstLaunch()
        }
    }
    
    private var mainAppView: some View {
        TabView(selection: $selectedTab) {
            HomeView(entries: $entries, customTags: $customTags, intervalTimer: intervalTimer)
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
            loadDataFromCoreData()
            intervalTimer.setEntries(entries)
            // Dismiss all delivered notifications when app appears
            NotificationManager.shared.dismissAllDeliveredNotifications()
            // Schedule notifications for today when app becomes active
            NotificationManager.shared.scheduleNotificationsForToday()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            // Dismiss all delivered notifications when app becomes active
            NotificationManager.shared.dismissAllDeliveredNotifications()
            // Reschedule notifications when app becomes active (after being backgrounded)
            NotificationManager.shared.scheduleNotificationsForToday()
        }
        .onReceive(NotificationCenter.default.publisher(for: .navigateToLogView)) { _ in
            // Navigate to LogView when notification is tapped
            print("🔄 Received navigateToLogView notification, switching to tab 1")
            selectedTab = 1
        }
        .onChange(of: shouldNavigateToHome) { _, newValue in
            if newValue {
                selectedTab = 0
                shouldNavigateToHome = false
            }
        }
        .onChange(of: notificationEnabled) { _, newValue in
            saveSettingsToCoreData()
            handleNotificationToggleChange(newValue)
        }
        .onChange(of: reminderInterval) { 
            saveSettingsToCoreData()
        }
        .onChange(of: entries) { _, _ in
            intervalTimer.setEntries(entries)
            saveEntriesToCoreData()
        }
        .onChange(of: customTags) { _, _ in
            saveCustomTagsToCoreData()
        }
        .dismissKeyboardOnTap()
    }
    
    // MARK: - First Launch Check
    
    private func checkFirstLaunch() {
        // Check force flag first
        if forceOnboardingFlag {
            showOnboarding = true
            return
        }
        
        if let userProfile = coreDataManager.getUserProfile() {
            // User profile exists, load data
            showOnboarding = false
            loadDataFromCoreData()
        } else {
            // First launch, show onboarding
            showOnboarding = true
        }
    }
    
    // MARK: - Core Data Operations
    
    private func loadDataFromCoreData() {
        // Load entries from Core Data
        let loadedEntries = coreDataManager.fetchAllLogEntries()
        entries = loadedEntries
        
        // Load user profile settings
        if let userProfile = coreDataManager.getUserProfile() {
            notificationEnabled = userProfile.notificationEnabled
            reminderInterval = userProfile.reminderInterval
            customTags = (userProfile.customTags as? [String]) ?? ["Read a book", "Practice violin", "Work on startup", "Journal", "Practice German", "Exercise", "Practice conducting", "Take multivitamins", "Meditate", "Work", "Work meetings"]
        }
        
        // Only load sample data if this is the first launch (no user profile exists)
        if entries.isEmpty && coreDataManager.getUserProfile() == nil {
            loadSampleData()
        }
    }
    
    private func saveEntriesToCoreData() {
        // This method is called when entries change
        // We don't need to save all entries here since individual entries are saved when created/updated
        // This is just a placeholder for future functionality if needed
    }
    
    private func saveSettingsToCoreData() {
        let userProfile = coreDataManager.fetchOrCreateUserProfile()
        userProfile.notificationEnabled = notificationEnabled
        userProfile.reminderInterval = reminderInterval
        coreDataManager.saveUserProfile()
    }
    
    private func saveCustomTagsToCoreData() {
        coreDataManager.updateCustomTags(customTags)
    }
    
    private func handleNotificationToggleChange(_ enabled: Bool) {
        if enabled {
            // Request notification permission when toggle is turned ON
            NotificationManager.shared.requestPermission()
            // Schedule notifications for today
            NotificationManager.shared.scheduleNotificationsForToday()
        } else {
            // Cancel all notifications when toggle is turned OFF
            NotificationManager.shared.cancelAllNotifications()
        }
    }
    
    // MARK: - Sample Data (for backward compatibility)
    
    private func loadSampleData() {
        // Add some sample entries for demonstration
        if entries.isEmpty {
            let calendar = Calendar.current
            let date = Date()
            
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
            
            // Don't save sample entries to Core Data during initial load
            // This prevents automatic profile creation and allows onboarding to show
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

// MARK: - Notification Extension

extension Notification.Name {
    static let profileCreated = Notification.Name("profileCreated")
    static let navigateToLogView = Notification.Name("navigateToLogView")
}

#Preview {
    ContentView()
        .environmentObject(CoreDataManager.shared)
}

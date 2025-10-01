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
    @State private var customTags: [String] = CoreDataManager.defaultTags
    @FocusState private var isFieldFocused: Bool
    @State private var notificationEnabled = true
    @State private var reminderInterval: TimeInterval = 30 * 60 // Default to 30 minutes
    @StateObject private var intervalTimer = IntervalTimer()
    @State private var shouldNavigateToHome = false
    
    @EnvironmentObject var coreDataManager: CoreDataManager
    
    var body: some View {
        mainAppView
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
            print("📱 ContentView onAppear - app launched")
            // Ensure a user profile exists for first-run scenarios
            _ = coreDataManager.fetchOrCreateUserProfile()
            loadDataFromCoreData()
            intervalTimer.setEntries(entries)
            // Dismiss all delivered notifications when app appears
            NotificationManager.shared.dismissAllDeliveredNotifications()
            // Schedule initial notifications if they're enabled
            if notificationEnabled {
                print("📱 Notifications enabled - scheduling initial notifications")
                NotificationManager.shared.scheduleNotificationsForToday()
            } else {
                print("📱 Notifications disabled - skipping initial scheduling")
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            print("📱 App became active - dismissing delivered notifications only")
            // Dismiss all delivered notifications when app becomes active
            NotificationManager.shared.dismissAllDeliveredNotifications()
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
    
    // MARK: - Core Data Operations
    
    private func loadDataFromCoreData() {
        // Load entries from Core Data
        let loadedEntries = coreDataManager.fetchAllLogEntries()
        entries = loadedEntries
        
        // Load user profile settings
        if let userProfile = coreDataManager.getUserProfile() {
            notificationEnabled = userProfile.notificationEnabled
            reminderInterval = userProfile.reminderInterval
            customTags = (userProfile.customTags as? [String]) ?? CoreDataManager.defaultTags
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
        print("⚙️ Notification toggle changed to: \(enabled)")
        if enabled {
            // Request notification permission when toggle is turned ON
            print("⚙️ Requesting notification permission")
            NotificationManager.shared.requestPermission()
            // Schedule notifications for today
            print("⚙️ Scheduling notifications after enabling")
            NotificationManager.shared.scheduleNotificationsForToday()
        } else {
            // Cancel all notifications when toggle is turned OFF
            print("⚙️ Cancelling all notifications after disabling")
            NotificationManager.shared.cancelAllNotifications()
        }
    }
    
    
}

// MARK: - Notification Extension

extension Notification.Name {
    static let navigateToLogView = Notification.Name("navigateToLogView")
}

#Preview {
    ContentView()
        .environmentObject(CoreDataManager.shared)
}

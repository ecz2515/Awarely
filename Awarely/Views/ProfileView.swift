//
//  ProfileView.swift
//  Awarely
//
//  Created by Evan Chen on 8/23/25.
//

import SwiftUI

enum NotificationSchedule: String, CaseIterable {
    case daily = "Daily"
    case weekdays = "Weekdays"
    case custom = "Custom"
    
    var description: String {
        switch self {
        case .daily:
            return "Every day"
        case .weekdays:
            return "Monday to Friday"
        case .custom:
            return "Custom schedule"
        }
    }
}

struct ProfileView: View {
    @Binding var notificationEnabled: Bool
    @Binding var reminderInterval: TimeInterval
    @Binding var entries: [LogEntry]
    @ObservedObject var intervalTimer: IntervalTimer
    
    // Premium feature state
    @State private var isPremiumUser = false
    @State private var gracePeriod: Int = 5
    @State private var notificationSchedule: NotificationSchedule = .daily
    @State private var vacationModeEnabled = false
    @EnvironmentObject var coreDataManager: CoreDataManager
    
    // Time picker states
    @State private var showingStartTimePicker = false
    @State private var showingEndTimePicker = false
    @State private var tempStartTime = Date()
    @State private var tempEndTime = Date()
    
    // Notification permission states
    @State private var showingPermissionAlert = false
    @State private var notificationPermissionStatus: UNAuthorizationStatus = .notDetermined
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                LinearGradient(
                    colors: [
                        Color(.systemBackground),
                        Color(.systemBackground).opacity(0.95),
                        Color(.secondarySystemBackground).opacity(0.3)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 32) {
                        // Profile Header Section
                        profileHeaderSection
                        
                        // Notifications Section
                        notificationsSection
                        
                        // Logging Settings Section
                        loggingSettingsSection
                        
                        // Export & Sharing Section
                        exportSharingSection
                        
                        // Personalization Section
                        personalizationSection
                        
                        // Smart Features Section
                        smartFeaturesSection
                        
                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 40)
                    .padding(.bottom, 100)
                }
            }
        }
        .onAppear {
            loadSettingsFromCoreData()
            checkNotificationPermissionStatus()
        }
        .onChange(of: reminderInterval) { 
            // Ensure grace period doesn't exceed reminder interval
            let maxGracePeriod = Int(reminderInterval / 60)
            if gracePeriod > maxGracePeriod {
                gracePeriod = maxGracePeriod
            }
            saveSettingsToCoreData()
        }
        .sheet(isPresented: $showingStartTimePicker) {
            TimePickerSheet(
                title: "Start Time",
                selectedTime: $tempStartTime,
                onSave: {
                    let userProfile = coreDataManager.fetchOrCreateUserProfile()
                    userProfile.notificationStartTime = tempStartTime
                    coreDataManager.saveUserProfile()
                }
            )
        }
        .sheet(isPresented: $showingEndTimePicker) {
            TimePickerSheet(
                title: "End Time",
                selectedTime: $tempEndTime,
                onSave: {
                    let userProfile = coreDataManager.fetchOrCreateUserProfile()
                    userProfile.notificationEndTime = tempEndTime
                    coreDataManager.saveUserProfile()
                }
            )
        }
        .alert("Notification Permission", isPresented: $showingPermissionAlert) {
            Button("Settings") {
                if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsUrl)
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Please enable notifications in Settings to receive mindful reminders.")
        }
    }
    
    private var profileHeaderSection: some View {
        VStack(spacing: 24) {
            // User Avatar and Name
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.blue.opacity(0.2), .purple.opacity(0.2)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 100, height: 100)
                    
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 50, weight: .medium))
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                
                VStack(spacing: 6) {
                    Text(userName)
                        .font(.title.weight(.bold))
                        .foregroundStyle(.primary)
                    
                    Text("Building awareness of your time")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            
            // Statistics Cards
            HStack(spacing: 12) {
                StatCard(
                    title: "Total Entries",
                    value: "\(entries.count)",
                    icon: "list.bullet",
                    color: .blue
                )
                
                StatCard(
                    title: "Day Streak",
                    value: "\(currentStreak)",
                    icon: "flame.fill",
                    color: .orange
                )
            }
        }
        .padding(.vertical, 20)
    }
    
    private var notificationsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Notifications")
                .font(.headline.weight(.semibold))
                .foregroundStyle(.primary)
            
            VStack(spacing: 16) {
                // Push Notifications Toggle
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Push notifications")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.primary)
                        
                        Text(notificationStatusText)
                            .font(.caption)
                            .foregroundStyle(notificationStatusColor)
                    }
                    
                    Spacer()
                    
                    Toggle("", isOn: $notificationEnabled)
                        .tint(.blue)
                        .onChange(of: notificationEnabled) { _, newValue in
                            if newValue {
                                handleNotificationToggleOn()
                            } else {
                                handleNotificationToggleOff()
                            }
                        }
                }
                
                // Reminder Interval
                if notificationEnabled {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 6) {
                                Text("Reminder interval")
                                    .font(.subheadline.weight(.medium))
                                    .foregroundStyle(.primary)
                                
                                if !isPremiumUser {
                                    Image(systemName: "crown.fill")
                                        .font(.caption2)
                                        .foregroundStyle(.orange)
                                }
                            }
                            Text("How often to send reminders")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                        
                        HStack(spacing: 8) {
                            VStack(alignment: .trailing, spacing: 4) {
                                Text(formatInterval(reminderInterval))
                                    .font(.subheadline.weight(.medium))
                                    .foregroundStyle(.primary)
                                
                                if reminderInterval != 30 * 60 && !isPremiumUser {
                                    Text("Premium")
                                        .font(.caption2)
                                        .foregroundStyle(.orange)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(
                                            RoundedRectangle(cornerRadius: 4)
                                                .fill(.orange.opacity(0.2))
                                        )
                                }
                            }
                            
                            // Chevron indicator to show it's tappable
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .opacity(0.7)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if isPremiumUser {
                            showIntervalPicker()
                        } else {
                            // Show premium upgrade prompt for non-30-minute intervals
                            showPremiumUpgrade()
                        }
                    }
                    
                    // Notification Start Time
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Start time")
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(.primary)
                            Text("When to start sending reminders")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                        
                        HStack(spacing: 8) {
                            Text(formatNotificationTime(getNotificationStartTime()))
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(.primary)
                            
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .opacity(0.7)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        tempStartTime = getNotificationStartTime()
                        showingStartTimePicker = true
                    }
                    
                    // Notification End Time
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("End time")
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(.primary)
                            Text("When to stop sending reminders")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                        
                        HStack(spacing: 8) {
                            Text(formatNotificationTime(getNotificationEndTime()))
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(.primary)
                            
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .opacity(0.7)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        tempEndTime = getNotificationEndTime()
                        showingEndTimePicker = true
                    }
                    
                    // Notification Schedule
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 6) {
                                Text("Schedule")
                                    .font(.subheadline.weight(.medium))
                                    .foregroundStyle(.primary)
                                
                                Image(systemName: "crown.fill")
                                    .font(.caption2)
                                    .foregroundStyle(.orange)
                            }
                            Text("When to send notifications")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                        
                        HStack(spacing: 8) {
                            Text(notificationSchedule.rawValue)
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(.primary)
                            
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .opacity(0.7)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        showPremiumScheduleAlert(notificationSchedule)
                    }
                    
                    // Vacation Mode
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 6) {
                                Text("Vacation Mode")
                                    .font(.subheadline.weight(.medium))
                                    .foregroundStyle(.primary)
                                
                                Image(systemName: "crown.fill")
                                    .font(.caption2)
                                    .foregroundStyle(.orange)
                            }
                            Text("Pause all reminders")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                        
                        Toggle("", isOn: $vacationModeEnabled)
                            .tint(.blue)
                            .disabled(true) // Prevent toggle from moving
                            .onTapGesture {
                                // Show premium prompt when trying to turn on
                                showPremiumScheduleAlert(.custom)
                            }
                    }
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .strokeBorder(.quaternary, lineWidth: 0.5)
                    )
            )
        }
    }
    
    private var loggingSettingsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Logging Settings")
                .font(.headline.weight(.semibold))
                .foregroundStyle(.primary)
            
            VStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 16) {
                    // Early Grace Period
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Early Grace Period")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.primary)
                        Text("How many minutes beforehand you can log")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        let maxGracePeriod = Int(reminderInterval / 60)
                        
                        VStack(spacing: 12) {
                            HStack {
                                Text("\(gracePeriod) minutes")
                                    .font(.subheadline.weight(.medium))
                                    .foregroundStyle(.primary)
                                Spacer()
                            }
                            
                            Slider(
                                value: Binding(
                                    get: { Double(gracePeriod) },
                                    set: { 
                                        gracePeriod = Int($0)
                                        saveSettingsToCoreData()
                                    }
                                ),
                                in: 1...Double(maxGracePeriod),
                                step: 1
                            )
                            .accentColor(.blue)
                            
                            HStack {
                                Text("1 min")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Text("\(maxGracePeriod) min")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .strokeBorder(.quaternary, lineWidth: 0.5)
                    )
            )
        }
    }
    
    private var exportSharingSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Export & Sharing")
                .font(.headline.weight(.semibold))
                .foregroundStyle(.primary)
            
            VStack(spacing: 16) {
                // Export to Calendar
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                            Text("Export to Calendar")
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(.primary)
                            
                            Image(systemName: "crown.fill")
                                .font(.caption2)
                                .foregroundStyle(.orange)
                        }
                        Text("Automatically add logs to calendar")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .opacity(0.7)
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    showComingSoonAlert("Export to Calendar")
                }
                
                // Share Report
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                            Text("Share Report")
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(.primary)
                            
                            Image(systemName: "crown.fill")
                                .font(.caption2)
                                .foregroundStyle(.orange)
                        }
                        Text("Generate and share detailed time tracking reports")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .opacity(0.7)
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    showComingSoonAlert("Share Report")
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .strokeBorder(.quaternary, lineWidth: 0.5)
                    )
            )
        }
    }
    
    private var personalizationSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Personalization")
                .font(.headline.weight(.semibold))
                .foregroundStyle(.primary)
            
            VStack(spacing: 16) {
                // Customize Theme
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                            Text("Customize Theme")
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(.primary)
                            
                            Image(systemName: "crown.fill")
                                .font(.caption2)
                                .foregroundStyle(.orange)
                        }
                        Text("Personalize the app with custom colors and themes")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .opacity(0.7)
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    showComingSoonAlert("Customize Theme")
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .strokeBorder(.quaternary, lineWidth: 0.5)
                    )
            )
        }
    }
    
    private var smartFeaturesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Smart Features")
                .font(.headline.weight(.semibold))
                .foregroundStyle(.primary)
            
            VStack(spacing: 16) {
                // AI Summaries
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                            Text("AI Summaries")
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(.primary)
                            
                            Image(systemName: "crown.fill")
                                .font(.caption2)
                                .foregroundStyle(.orange)
                        }
                        Text("Get intelligent summaries of your daily activities")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .opacity(0.7)
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    showComingSoonAlert("AI Summaries")
                }
                
                // Smart Notifications
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                            Text("Smart Notifications")
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(.primary)
                            
                            Image(systemName: "crown.fill")
                                .font(.caption2)
                                .foregroundStyle(.orange)
                        }
                        Text("Automatically pause reminders during calendar events")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .opacity(0.7)
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    showComingSoonAlert("Smart Notifications")
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .strokeBorder(.quaternary, lineWidth: 0.5)
                    )
            )
        }
    }
    
    // MARK: - Computed Properties
    
    private var notificationStatusText: String {
        if !notificationEnabled {
            return "Notifications disabled"
        }
        
        switch notificationPermissionStatus {
        case .authorized:
            return "Notifications enabled"
        case .denied:
            return "Permission denied - check Settings"
        case .notDetermined:
            return "Permission not requested"
        case .provisional:
            return "Provisional notifications enabled"
        case .ephemeral:
            return "Ephemeral notifications enabled"
        @unknown default:
            return "Unknown status"
        }
    }
    
    private var notificationStatusColor: Color {
        if !notificationEnabled {
            return .secondary
        }
        
        switch notificationPermissionStatus {
        case .authorized:
            return .green
        case .denied:
            return .red
        case .notDetermined:
            return .orange
        case .provisional, .ephemeral:
            return .blue
        @unknown default:
            return .secondary
        }
    }
    
    private var userName: String {
        if let userProfile = coreDataManager.getUserProfile(),
           let name = userProfile.name, !name.isEmpty {
            return name
        }
        return "User"
    }
    
    private var currentStreak: Int {
        let calendar = Calendar.current
        var streak = 0
        let currentDate = Date()
        
        // Check if today has entries
        let todayEntries = entries.filter { entry in
            calendar.isDate(entry.timestamp, inSameDayAs: currentDate)
        }
        
        if !todayEntries.isEmpty {
            streak = 1
        }
        
        // Check previous days
        for dayOffset in 1...365 { // Check up to a year back
            let previousDate = calendar.date(byAdding: .day, value: -dayOffset, to: Date()) ?? Date()
            let dayEntries = entries.filter { entry in
                calendar.isDate(entry.timestamp, inSameDayAs: previousDate)
            }
            
            if !dayEntries.isEmpty {
                streak += 1
            } else {
                break // Streak broken
            }
        }
        
        return streak
    }
    
    // MARK: - Helper Functions
    
    private func formatInterval(_ interval: TimeInterval) -> String {
        let minutes = Int(interval / 60)
        if minutes == 30 {
            return "30 min"
        } else if minutes == 60 {
            return "1 hour"
        } else {
            return "\(minutes) min"
        }
    }
    
    private func formatNotificationTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func getNotificationStartTime() -> Date {
        if let userProfile = coreDataManager.getUserProfile(),
           let savedTime = userProfile.notificationStartTime {
            return savedTime
        } else {
            // Default to 9 AM
            let calendar = Calendar.current
            let today = calendar.startOfDay(for: Date())
            let defaultTime = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: today) ?? Date()
            let userProfile = coreDataManager.fetchOrCreateUserProfile()
            userProfile.notificationStartTime = defaultTime
            coreDataManager.saveUserProfile()
            return defaultTime
        }
    }
    
    private func getNotificationEndTime() -> Date {
        if let userProfile = coreDataManager.getUserProfile(),
           let savedTime = userProfile.notificationEndTime {
            return savedTime
        } else {
            // Default to 6 PM
            let calendar = Calendar.current
            let today = calendar.startOfDay(for: Date())
            let defaultTime = calendar.date(bySettingHour: 18, minute: 0, second: 0, of: today) ?? Date()
            let userProfile = coreDataManager.fetchOrCreateUserProfile()
            userProfile.notificationEndTime = defaultTime
            coreDataManager.saveUserProfile()
            return defaultTime
        }
    }
    
    private func showIntervalPicker() {
        // For now, just show an alert with options
        // In a real app, you'd show a proper picker sheet
        let alert = UIAlertController(title: "Reminder Interval", message: "Choose how often to send reminders", preferredStyle: .actionSheet)
        
        let intervals = [
            (15 * 60, "15 min"),
            (30 * 60, "30 min"),
            (45 * 60, "45 min"),
            (60 * 60, "1 hour")
        ]
        
        for (interval, label) in intervals {
            alert.addAction(UIAlertAction(title: label, style: .default) { _ in
                reminderInterval = TimeInterval(interval)
            })
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController?.present(alert, animated: true)
        }
    }
    
    private func showPremiumUpgrade() {
        let alert = UIAlertController(
            title: "Premium Feature",
            message: "Custom reminder intervals will be available in the premium version. Coming soon!",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController?.present(alert, animated: true)
        }
    }
    

    
    
    private func showPremiumScheduleAlert(_ schedule: NotificationSchedule) {
        let featureName = schedule == .custom ? "Vacation Mode" : "\(schedule.rawValue) notification schedule"
        let alert = UIAlertController(
            title: "Premium Feature",
            message: "\(featureName) will be available in the premium version. Coming soon!",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController?.present(alert, animated: true)
        }
    }
    
    private func showComingSoonAlert(_ featureName: String) {
        let alert = UIAlertController(
            title: "Coming Soon",
            message: "\(featureName) will be available in the premium version!",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController?.present(alert, animated: true)
        }
    }
    
    // MARK: - Settings Persistence
    
    private func loadSettingsFromCoreData() {
        if let userProfile = coreDataManager.getUserProfile() {
            gracePeriod = Int(userProfile.loggingGracePeriod)
            isPremiumUser = userProfile.isPremiumUser
        } else {
            gracePeriod = 5 // Default to 5 minutes
        }
        
        // Note: reminderInterval is managed by ContentView and passed as a binding
        // We don't modify it here, just use it for calculations
    }
    
    private func saveSettingsToCoreData() {
        let userProfile = coreDataManager.fetchOrCreateUserProfile()
        userProfile.loggingGracePeriod = Int32(gracePeriod)
        coreDataManager.saveUserProfile()
    }
    
    private func checkNotificationPermissionStatus() {
        NotificationManager.shared.getNotificationAuthorizationStatus { status in
            notificationPermissionStatus = status
        }
    }
    
    private func handleNotificationToggleOn() {
        NotificationManager.shared.requestPermission()
        // Check status after a brief delay to allow permission dialog to complete
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            checkNotificationPermissionStatus()
        }
    }
    
    private func handleNotificationToggleOff() {
        NotificationManager.shared.cancelAllNotifications()
        checkNotificationPermissionStatus()
    }
}

// MARK: - TimePickerSheet

struct TimePickerSheet: View {
    let title: String
    @Binding var selectedTime: Date
    let onSave: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                DatePicker(
                    "Time",
                    selection: $selectedTime,
                    displayedComponents: .hourAndMinute
                )
                .datePickerStyle(.wheel)
                .labelsHidden()
                
                Spacer()
            }
            .padding()
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        onSave()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.medium])
        .onAppear {
            UIDatePicker.appearance().minuteInterval = 30
        }
        .onDisappear {
            UIDatePicker.appearance().minuteInterval = 1
        }
    }
}

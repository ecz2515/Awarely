//
//  ProfileView.swift
//  Awarely
//
//  Created by Evan Chen on 8/23/25.
//

import SwiftUI
import UserNotifications

struct ScheduledNotification: Identifiable {
    let id: String
    let title: String
    let body: String
    let scheduledDate: Date
    let type: NotificationType
    
    enum NotificationType {
        case dayStarted
        case loggingReminder
    }
}

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
    @State private var showingNameEditor = false
    @State private var tempName: String = ""
    
    // Notification permission states
    @State private var showingPermissionAlert = false
    @State private var notificationPermissionStatus: UNAuthorizationStatus = .notDetermined
    
    // Notification log states
    @State private var scheduledNotifications: [ScheduledNotification] = []
    @State private var showingNotificationLog = false
    
    
    var body: some View {
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
                    // Profile Header Section with Edit Button
                    profileHeaderSection
                    
                    // Notifications Section
                    notificationsSection
                    
                    // Premium Features Section
                    premiumFeaturesSection
                    
                    // Notification Log Section
                    // notificationLogSection
                    
                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 20)
                .padding(.top, 40)
                .padding(.bottom, 100)
            }
            
            // Floating Edit Button
            VStack {
                HStack {
                    Spacer()
                    Button(action: {
                        tempName = userName
                        showingNameEditor = true
                    }) {
                        Image(systemName: "pencil.circle.fill")
                            .font(.system(size: 24, weight: .medium))
                            .foregroundStyle(.blue)
                    }
                    .accessibilityLabel("Edit name")
                    .padding(.trailing, 20)
                    .padding(.top, 10)
                }
                Spacer()
            }
        }
        .onAppear {
            loadSettingsFromCoreData()
            checkNotificationPermissionStatus()
            // loadScheduledNotifications()
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
                    print("⚙️ ===== START TIME CHANGE =====")
                    print("⚙️ New start time selected: \(tempStartTime)")
                    
                    // Get current settings for comparison
                    let userProfile = coreDataManager.fetchOrCreateUserProfile()
                    if let oldStartTime = userProfile.notificationStartTime {
                        print("⚙️ Previous start time: \(oldStartTime)")
                    } else {
                        print("⚙️ No previous start time set")
                    }
                    
                    userProfile.notificationStartTime = tempStartTime
                    coreDataManager.saveUserProfile()
                    print("⚙️ Start time saved to CoreData: \(tempStartTime)")
                    
                    // Reschedule notifications with new time
                    if notificationEnabled {
                        print("⚙️ Notifications enabled - rescheduling...")
                        NotificationManager.shared.rescheduleNotificationsForSettingsChange()
                    } else {
                        print("⚙️ Notifications disabled - skipping reschedule")
                    }
                    print("⚙️ ===== START TIME CHANGE COMPLETE =====")
                }
            )
        }
        .sheet(isPresented: $showingEndTimePicker) {
            TimePickerSheet(
                title: "End Time",
                selectedTime: $tempEndTime,
                onSave: {
                    print("⚙️ ===== END TIME CHANGE =====")
                    print("⚙️ New end time selected: \(tempEndTime)")
                    
                    // Get current settings for comparison
                    let userProfile = coreDataManager.fetchOrCreateUserProfile()
                    if let oldEndTime = userProfile.notificationEndTime {
                        print("⚙️ Previous end time: \(oldEndTime)")
                    } else {
                        print("⚙️ No previous end time set")
                    }
                    
                    userProfile.notificationEndTime = tempEndTime
                    coreDataManager.saveUserProfile()
                    print("⚙️ End time saved to CoreData: \(tempEndTime)")
                    
                    // Reschedule notifications with new time
                    if notificationEnabled {
                        print("⚙️ Notifications enabled - rescheduling...")
                        NotificationManager.shared.rescheduleNotificationsForSettingsChange()
                    } else {
                        print("⚙️ Notifications disabled - skipping reschedule")
                    }
                    print("⚙️ ===== END TIME CHANGE COMPLETE =====")
                }
            )
        }
        .alert("Edit Name", isPresented: $showingNameEditor) {
            TextField("Your name", text: $tempName)
            Button("Save") {
                let trimmed = tempName.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmed.isEmpty {
                    coreDataManager.updateUserName(trimmed)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Update the name shown on your profile")
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
                    
                    Text(personalMantra)
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
                
                if notificationEnabled {
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
    
    private var premiumFeaturesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Premium Features")
                .font(.headline.weight(.semibold))
                .foregroundStyle(.primary)
            
            VStack(spacing: 16) {
                // Reminder Interval
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                            Text("Reminder interval")
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(.primary)
                            
                            Image(systemName: "crown.fill")
                                .font(.caption2)
                                .foregroundStyle(.orange)
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
                        Text("Generate/share detailed time tracking reports")
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
                        Text("Custom colors and themes")
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
                        Text("Intelligent summaries of your daily activities")
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
                
                // Early Grace Period
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                            Text("Early Grace Period")
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(.primary)
                            
                            Image(systemName: "crown.fill")
                                .font(.caption2)
                                .foregroundStyle(.orange)
                        }
                        Text("How many mins beforehand you can log")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 8) {
                        Text("\(gracePeriod) min")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.primary)
                        
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
                        showGracePeriodPicker()
                    } else {
                        showPremiumUpgrade()
                    }
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
                        Text("Pause during calendar events")
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
    
    /*
    private var notificationLogSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Notification Log")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.primary)
                
                Spacer()
                
                HStack(spacing: 12) {
                    Button("Debug") {
                        NotificationManager.shared.debugNotificationScheduling()
                        loadScheduledNotifications()
                    }
                    .font(.caption)
                    .foregroundStyle(.orange)
                    
                    Button("Refresh") {
                        loadScheduledNotifications()
                    }
                    .font(.caption)
                    .foregroundStyle(.blue)
                }
            }
            
            VStack(spacing: 12) {
                if scheduledNotifications.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "bell.slash")
                            .font(.title2)
                            .foregroundStyle(.secondary)
                        
                        Text("No scheduled notifications")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        
                        Text("Notifications will appear here when scheduled")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.vertical, 20)
                } else {
                    ForEach(scheduledNotifications.prefix(10)) { notification in
                        NotificationLogRow(notification: notification)
                    }
                    
                    if scheduledNotifications.count > 10 {
                        Text("... and \(scheduledNotifications.count - 10) more")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.top, 8)
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
    */
    
    // MARK: - Computed Properties
    
    private var notificationStatusText: String {
        if !notificationEnabled {
            return "Notifications disabled"
        }
        
        switch notificationPermissionStatus {
        case .authorized:
            return "Enabled"
        case .denied:
            return "Denied (check Settings)"
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
    
    private var personalMantra: String {
        return "Building awareness of your time"
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
            // No saved time - return a reasonable default for display only
            let calendar = Calendar.current
            let today = calendar.startOfDay(for: Date())
            return calendar.date(bySettingHour: 9, minute: 0, second: 0, of: today) ?? Date()
        }
    }
    
    private func getNotificationEndTime() -> Date {
        if let userProfile = coreDataManager.getUserProfile(),
           let savedTime = userProfile.notificationEndTime {
            return savedTime
        } else {
            // No saved time - return a reasonable default for display only
            let calendar = Calendar.current
            let today = calendar.startOfDay(for: Date())
            return calendar.date(bySettingHour: 21, minute: 0, second: 0, of: today) ?? Date()
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
    
    private func showGracePeriodPicker() {
        let alert = UIAlertController(title: "Early Grace Period", message: "Choose how many minutes beforehand you can log", preferredStyle: .actionSheet)
        
        let maxGracePeriod = Int(reminderInterval / 60)
        let gracePeriods = Array(1...maxGracePeriod)
        
        for period in gracePeriods {
            alert.addAction(UIAlertAction(title: "\(period) min", style: .default) { _ in
                gracePeriod = period
                saveSettingsToCoreData()
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
            
            // Load notification times into temp variables
            if let savedStartTime = userProfile.notificationStartTime {
                tempStartTime = savedStartTime
            } else {
                tempStartTime = getNotificationStartTime()
            }
            
            if let savedEndTime = userProfile.notificationEndTime {
                tempEndTime = savedEndTime
            } else {
                tempEndTime = getNotificationEndTime()
            }
        } else {
            gracePeriod = 5 // Default to 5 minutes
            // Set default notification times
            tempStartTime = getNotificationStartTime()
            tempEndTime = getNotificationEndTime()
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
    
    private func loadScheduledNotifications() {
        print("📋 ===== LOADING SCHEDULED NOTIFICATIONS =====")
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            DispatchQueue.main.async {
                print("📋 Found \(requests.count) pending notification requests")
                var notifications: [ScheduledNotification] = []
                
                for (index, request) in requests.enumerated() {
                    if let trigger = request.trigger as? UNCalendarNotificationTrigger,
                       let nextTriggerDate = trigger.nextTriggerDate() {
                        
                        let type: ScheduledNotification.NotificationType
                        if request.identifier.hasPrefix("day-started") {
                            type = .dayStarted
                        } else {
                            type = .loggingReminder
                        }
                        
                        let notification = ScheduledNotification(
                            id: request.identifier,
                            title: request.content.title,
                            body: request.content.body,
                            scheduledDate: nextTriggerDate,
                            type: type
                        )
                        
                        notifications.append(notification)
                        print("📋 \(index + 1). \(type == .dayStarted ? "🌅 Day Start" : "🔔 Logging") - \(nextTriggerDate)")
                    } else {
                        print("📋 \(index + 1). ❌ Invalid trigger or date for request: \(request.identifier)")
                    }
                }
                
                // Sort by scheduled date
                notifications.sort { $0.scheduledDate < $1.scheduledDate }
                self.scheduledNotifications = notifications
                
                print("📋 Loaded \(notifications.count) valid scheduled notifications")
                if let firstNotification = notifications.first {
                    print("📋 Next notification: \(firstNotification.scheduledDate) (\(firstNotification.type == .dayStarted ? "Day Start" : "Logging"))")
                }
                print("📋 ===== LOADING COMPLETE =====")
            }
        }
    }
}

// MARK: - NotificationLogRow

struct NotificationLogRow: View {
    let notification: ScheduledNotification
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon based on notification type
            Image(systemName: notification.type == .dayStarted ? "sunrise.fill" : "bell.fill")
                .font(.caption)
                .foregroundStyle(notification.type == .dayStarted ? .orange : .blue)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(notification.title)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                
                Text(notification.body)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text(formatNotificationTime(notification.scheduledDate))
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.primary)
                
                Text(formatNotificationDate(notification.scheduledDate))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
    
    private func formatNotificationTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func formatNotificationDate(_ date: Date) -> String {
        let calendar = Calendar.current
        let now = Date()
        
        if calendar.isDate(date, inSameDayAs: now) {
            return "Today"
        } else if calendar.isDate(date, inSameDayAs: calendar.date(byAdding: .day, value: 1, to: now) ?? now) {
            return "Tomorrow"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d"
            return formatter.string(from: date)
        }
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


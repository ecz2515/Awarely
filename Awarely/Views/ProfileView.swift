//
//  ProfileView.swift
//  Awarely
//
//  Created by Evan Chen on 8/23/25.
//

import SwiftUI

struct ProfileView: View {
    @Binding var notificationEnabled: Bool
    @Binding var reminderInterval: TimeInterval
    @Binding var entries: [LogEntry]
    @ObservedObject var intervalTimer: IntervalTimer
    
    // Premium feature state
    @State private var isPremiumUser = false
    @State private var gracePeriod: Int = 5
    @EnvironmentObject var coreDataManager: CoreDataManager
    
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
                        // App Info Section
                        appInfoSection
                        
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
        }
        .onChange(of: reminderInterval) { 
            // Ensure grace period doesn't exceed reminder interval
            let maxGracePeriod = Int(reminderInterval / 60)
            if gracePeriod > maxGracePeriod {
                gracePeriod = maxGracePeriod
            }
            saveSettingsToCoreData()
        }
    }
    
    private var appInfoSection: some View {
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
                
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 40, weight: .medium))
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
                Text("Awarely")
                    .font(.title.weight(.bold))
                    .foregroundStyle(.primary)
                
                Text("Building awareness of your time")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
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
                        Text("Reminders to log your activities")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    Toggle("", isOn: $notificationEnabled)
                        .tint(.blue)
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
                        showStartTimePicker()
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
                        showEndTimePicker()
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
                        Text("How many minutes beforehand you can log the current time interval")
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
                        Text("Automatically add your logged activities to your calendar")
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
    
    private func showStartTimePicker() {
        let alert = UIAlertController(title: "Start Time", message: "Choose when to start sending reminders", preferredStyle: .actionSheet)
        
        let times = [
            (6, "6:00 AM"),
            (7, "7:00 AM"),
            (8, "8:00 AM"),
            (9, "9:00 AM"),
            (10, "10:00 AM"),
            (11, "11:00 AM"),
            (12, "12:00 PM")
        ]
        
        for (hour, label) in times {
            alert.addAction(UIAlertAction(title: label, style: .default) { _ in
                let calendar = Calendar.current
                let today = calendar.startOfDay(for: Date())
                let newTime = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: today) ?? Date()
                let userProfile = self.coreDataManager.fetchOrCreateUserProfile()
                userProfile.notificationStartTime = newTime
                self.coreDataManager.saveUserProfile()
            })
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController?.present(alert, animated: true)
        }
    }
    
    private func showEndTimePicker() {
        let alert = UIAlertController(title: "End Time", message: "Choose when to stop sending reminders", preferredStyle: .actionSheet)
        
        let times = [
            (17, "5:00 PM"),
            (18, "6:00 PM"),
            (19, "7:00 PM"),
            (20, "8:00 PM"),
            (21, "9:00 PM"),
            (22, "10:00 PM"),
            (23, "11:00 PM")
        ]
        
        for (hour, label) in times {
            alert.addAction(UIAlertAction(title: label, style: .default) { _ in
                let calendar = Calendar.current
                let today = calendar.startOfDay(for: Date())
                let newTime = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: today) ?? Date()
                let userProfile = self.coreDataManager.fetchOrCreateUserProfile()
                userProfile.notificationEndTime = newTime
                self.coreDataManager.saveUserProfile()
            })
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
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
        
        // Ensure reminder interval defaults to 30 minutes if not set
        if reminderInterval == 0 {
            reminderInterval = 30 * 60
        }
    }
    
    private func saveSettingsToCoreData() {
        let userProfile = coreDataManager.fetchOrCreateUserProfile()
        userProfile.loggingGracePeriod = Int32(gracePeriod)
        coreDataManager.saveUserProfile()
    }
}

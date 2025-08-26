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
    
    // New notification timing settings
    @State private var notificationStartTime = Calendar.current.date(from: DateComponents(hour: 9, minute: 0)) ?? Date()
    @State private var notificationEndTime = Calendar.current.date(from: DateComponents(hour: 18, minute: 0)) ?? Date()
    @State private var loggingGracePeriod: Int = 5 // minutes
    
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
                        
                        // Notification Timing Section
                        if notificationEnabled {
                            notificationTimingSection
                        }
                        
                        // Logging Settings Section
                        loggingSettingsSection
                        
                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 40)
                    .padding(.bottom, 100)
                }
            }
        }
        .onAppear {
            loadSettings()
        }
        .onChange(of: notificationStartTime) { saveSettings() }
        .onChange(of: notificationEndTime) { saveSettings() }
        .onChange(of: loggingGracePeriod) { saveSettings() }
        .onChange(of: reminderInterval) { 
            // Ensure grace period doesn't exceed reminder interval
            let maxGracePeriod = Int(reminderInterval / 60)
            if loggingGracePeriod > maxGracePeriod {
                loggingGracePeriod = maxGracePeriod
            }
            saveSettings()
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
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Reminder Notifications")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.primary)
                        Text("Get reminded to log your activities")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    Toggle("", isOn: $notificationEnabled)
                        .tint(.blue)
                }
                
                if notificationEnabled {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Reminder Interval")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.primary)
                        
                        Picker("Interval", selection: $reminderInterval) {
                            Text("15 min").tag(TimeInterval(15 * 60))
                            Text("30 min").tag(TimeInterval(30 * 60))
                            Text("45 min").tag(TimeInterval(45 * 60))
                            Text("1 hour").tag(TimeInterval(60 * 60))
                        }
                        .pickerStyle(.segmented)
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
    
    private var notificationTimingSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Notification Timing")
                .font(.headline.weight(.semibold))
                .foregroundStyle(.primary)
            
            Text("Set when you want to receive logging reminders")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            VStack(spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Start Time")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.primary)
                        Text("When to start sending notifications")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    DatePicker("Start Time", selection: $notificationStartTime, displayedComponents: .hourAndMinute)
                        .labelsHidden()
                }
                
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("End Time")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.primary)
                        Text("When to stop sending notifications")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    DatePicker("End Time", selection: $notificationEndTime, displayedComponents: .hourAndMinute)
                        .labelsHidden()
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
                        
                        VStack(spacing: 12) {
                            HStack {
                                Text("\(loggingGracePeriod) minutes")
                                    .font(.subheadline.weight(.medium))
                                    .foregroundStyle(.primary)
                                Spacer()
                            }
                            
                            Slider(
                                value: Binding(
                                    get: { Double(loggingGracePeriod) },
                                    set: { loggingGracePeriod = Int($0) }
                                ),
                                in: 1...Double(reminderInterval / 60),
                                step: 1
                            )
                            .accentColor(.blue)
                            
                            HStack {
                                Text("1 min")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Text("\(Int(reminderInterval / 60)) min")
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
    
    // MARK: - Settings Persistence
    
    private func loadSettings() {
        let defaults = UserDefaults.standard
        
        if let startTime = defaults.object(forKey: "notificationStartTime") as? Date {
            notificationStartTime = startTime
        }
        
        if let endTime = defaults.object(forKey: "notificationEndTime") as? Date {
            notificationEndTime = endTime
        }
        
        loggingGracePeriod = defaults.integer(forKey: "loggingGracePeriod")
        if loggingGracePeriod == 0 {
            loggingGracePeriod = 5 // Default to 5 minutes
        }
    }
    
    private func saveSettings() {
        let defaults = UserDefaults.standard
        defaults.set(notificationStartTime, forKey: "notificationStartTime")
        defaults.set(notificationEndTime, forKey: "notificationEndTime")
        defaults.set(loggingGracePeriod, forKey: "loggingGracePeriod")
    }
}

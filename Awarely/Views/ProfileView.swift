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
                        
                        // Statistics Section
                        statisticsSection
                        
                        // Notifications Section
                        notificationsSection
                        
                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 40)
                    .padding(.bottom, 100)
                }
            }
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
    
    private var statisticsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Your Progress")
                .font(.headline.weight(.semibold))
                .foregroundStyle(.primary)
            
            HStack(spacing: 12) {
                StatCard(
                    title: "Total Entries",
                    value: "\(entries.count)",
                    icon: "list.bullet",
                    color: .blue
                )
                
                StatCard(
                    title: "This Week",
                    value: "\(weeklyEntries)",
                    icon: "calendar",
                    color: .green
                )
            }
            
            HStack(spacing: 12) {
                StatCard(
                    title: "This Month",
                    value: "\(monthlyEntries)",
                    icon: "chart.line.uptrend.xyaxis",
                    color: .orange
                )
                
                StatCard(
                    title: "Streak",
                    value: "\(currentStreak)",
                    icon: "flame",
                    color: .red
                )
            }
        }
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
    
    // MARK: - Computed Properties
    
    private var weeklyEntries: Int {
        let calendar = Calendar.current
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return entries.filter { entry in
            entry.timestamp >= weekAgo
        }.count
    }
    
    private var monthlyEntries: Int {
        let calendar = Calendar.current
        let monthAgo = calendar.date(byAdding: .month, value: -1, to: Date()) ?? Date()
        return entries.filter { entry in
            entry.timestamp >= monthAgo
        }.count
    }
    
    private var currentStreak: Int {
        let calendar = Calendar.current
        var streak = 0
        var currentDate = Date()
        
        while true {
            let dayEntries = entries.filter { entry in
                calendar.isDate(entry.timestamp, inSameDayAs: currentDate)
            }
            
            if dayEntries.isEmpty {
                break
            }
            
            streak += 1
            currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate) ?? currentDate
        }
        
        return streak
    }
}

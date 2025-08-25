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
                    VStack(spacing: 24) {
                        // App Info Section
                        appInfoSection
                        
                        // Notifications Section
                        notificationsSection
                        
                        // Actions Section
                        actionsSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 100)
                }
            }
        }
    }
    
    private var appInfoSection: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 80, height: 80)
                
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 32, weight: .medium))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(.blue)
            }
            
            VStack(spacing: 4) {
                Text("Awarely")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.primary)
                
                Text("Building awareness of your time")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 20)
    }
    
    private var notificationsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Notifications")
                .font(.headline.weight(.semibold))
            
            VStack(spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Reminder Notifications")
                            .font(.subheadline.weight(.medium))
                        Text("Get reminded to log your activities")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    Toggle("", isOn: $notificationEnabled)
                        .tint(.blue)
                }
                
                if notificationEnabled {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Reminder Interval")
                            .font(.subheadline.weight(.medium))
                        
                        Picker("Interval", selection: $reminderInterval) {
                            Text("15 minutes").tag(TimeInterval(15 * 60))
                            Text("30 minutes").tag(TimeInterval(30 * 60))
                            Text("45 minutes").tag(TimeInterval(45 * 60))
                            Text("1 hour").tag(TimeInterval(60 * 60))
                        }
                        .pickerStyle(.segmented)
                    }
                }
            }
            .padding(16)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
    }
    
    private var actionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Actions")
                .font(.headline.weight(.semibold))
            
            VStack(spacing: 8) {
                ActionButton(
                    title: "Export Data",
                    icon: "square.and.arrow.up",
                    color: .blue
                ) {
                    // Export functionality
                }
                
                ActionButton(
                    title: "Clear All Data",
                    icon: "trash",
                    color: .red
                ) {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                        entries.removeAll()
                    }
                }
            }
        }
    }
}

//
//  HomeView.swift
//  Awarely
//
//  Created by Evan Chen on 8/23/25.
//

import SwiftUI

struct HomeView: View {
    @Binding var entries: [LogEntry]
    @State private var showingEntriesList = false
    @ObservedObject var intervalTimer: IntervalTimer
    
    var todayEntries: [LogEntry] {
        let calendar = Calendar.current
        return entries.filter { entry in
            calendar.isDate(entry.timestamp, inSameDayAs: Date())
        }.sorted { $0.timePeriodStart > $1.timePeriodStart } // Sort by when activity occurred, newest first
    }
    
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
                        // "Your Entries" Title
                        titleSection
                        
                        // Timer Status Section
                        timerStatusSection
                        
                        // Statistics Section
                        statisticsSection
                        
                        // View All Entries Button
                        viewAllEntriesButton
                        
                        // Date Section
                        dateSection
                        
                        // Today's Entries
                        entriesSection
                        
                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 40)
                    .padding(.bottom, 20)
                }
            }
        }
        .sheet(isPresented: $showingEntriesList) {
            EntriesListView(entries: $entries)
        }

    }
    
    private var titleSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Your Entries")
                .font(.largeTitle.weight(.bold))
                .foregroundStyle(.primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var timerStatusSection: some View {
        HStack {
            HStack {
                Image(systemName: intervalTimer.isLateGracePeriod ? "exclamationmark.triangle.fill" : (intervalTimer.isLoggingWindow ? "checkmark.circle.fill" : "timer"))
                    .foregroundStyle(intervalTimer.isLateGracePeriod ? .red : (intervalTimer.isLoggingWindow ? .green : .orange))
                
                Text(intervalTimer.isLateGracePeriod ? "Log your previous activity now" : (intervalTimer.isLoggingWindow ? "Ready to log your activity" : "\(intervalTimer.formatTimeRemaining()) until next check-in"))
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.primary)
            }
            
            Spacer()
            
            if !intervalTimer.isLoggingWindow {
                Text(intervalTimer.nextIntervalDate.formatted(date: .omitted, time: .shortened))
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.orange)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(intervalTimer.isLateGracePeriod ? Color.red.opacity(0.1) : (intervalTimer.isLoggingWindow ? Color.green.opacity(0.1) : Color.orange.opacity(0.1)))
        )
    }
    
    private var statisticsSection: some View {
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
    }
    
    private var dateSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(Date().formatted(date: .complete, time: .omitted))
                .font(.title2.weight(.semibold))
                .foregroundStyle(.primary)
                .tracking(0.5)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    

    
    private var entriesSection: some View {
        VStack(spacing: 0) {
            if todayEntries.isEmpty {
                emptyState
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(todayEntries) { entry in
                        EnhancedEntryRow(entry: entry) { updated in
                            if let idx = entries.firstIndex(where: { $0.id == updated.id }) {
                                entries[idx] = updated
                            }
                        }
                        .transition(.asymmetric(
                            insertion: .scale.combined(with: .opacity),
                            removal: .scale.combined(with: .opacity)
                        ))
                    }
                }
            }
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "sparkles")
                .font(.system(size: 48, weight: .light))
                .foregroundStyle(.secondary)
            
            Text("No entries yet today")
                .font(.title3.weight(.medium))
                .foregroundStyle(.primary)
            
            Text("Start logging your activities to see them here")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(40)
    }
    
    private var viewAllEntriesButton: some View {
        Button(action: {
            showingEntriesList = true
        }) {
            HStack {
                Image(systemName: "calendar")
                    .font(.subheadline)
                    .foregroundStyle(.blue)
                
                Text("View All Entries")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.blue)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.blue)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                Color.blue.opacity(0.1),
                in: RoundedRectangle(cornerRadius: 12, style: .continuous)
            )
        }
    }
    
    private var weeklyEntries: Int {
        let calendar = Calendar.current
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return entries.filter { entry in
            entry.timestamp >= weekAgo
        }.count
    }
}

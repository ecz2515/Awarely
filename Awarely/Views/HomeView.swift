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
    
    var todayEntries: [LogEntry] {
        let calendar = Calendar.current
        return entries.filter { entry in
            calendar.isDate(entry.timestamp, inSameDayAs: Date())
        }.sorted { $0.timestamp > $1.timestamp } // Newest first
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

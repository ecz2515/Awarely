//
//  HomeView.swift
//  Awarely
//
//  Created by Evan Chen on 8/23/25.
//

import SwiftUI

struct HomeView: View {
    @Binding var entries: [LogEntry]
    @State private var showingAllEntries = false
    
    var todayEntries: [LogEntry] {
        let calendar = Calendar.current
        return entries.filter { entry in
            calendar.isDate(entry.timestamp, inSameDayAs: Date())
        }.sorted { $0.timestamp > $1.timestamp } // Newest first
    }
    
    var displayedEntries: [LogEntry] {
        if showingAllEntries {
            return todayEntries
        } else {
            return Array(todayEntries.prefix(3))
        }
    }
    
    var shouldShowSeeMore: Bool {
        todayEntries.count > 4
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
                
                VStack(spacing: 0) {
                    // Header
                    header
                    
                    // Entries Section
                    entriesSection
                    
                    Spacer(minLength: 0)
                    
                    // Statistics Section (sticky bottom)
                    statisticsSection
                }
            }
        }
    }
    
    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Your Day So Far")
                .font(.largeTitle.weight(.bold))
                .foregroundStyle(.primary)
            
            Text(Date().formatted(date: .complete, time: .omitted))
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .tracking(0.5)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 16)
    }
    
    private var entriesSection: some View {
        VStack(spacing: 0) {
            if todayEntries.isEmpty {
                emptyState
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(displayedEntries) { entry in
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
                .padding(.horizontal, 20)
                
                // See More Button (only if needed)
                if shouldShowSeeMore {
                    Button(action: {
                        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                            showingAllEntries.toggle()
                        }
                    }) {
                        HStack {
                            Text(showingAllEntries ? "Show Less" : "See More Entries")
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(.blue)
                            
                            Image(systemName: showingAllEntries ? "chevron.up" : "chevron.down")
                                .font(.caption)
                                .foregroundStyle(.blue)
                        }
                        .padding(.vertical, 12)
                        .padding(.horizontal, 16)
                        .background(.blue.opacity(0.1), in: Capsule())
                    }
                    .padding(.top, 16)
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
    
    private var statisticsSection: some View {
        VStack(spacing: 16) {
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
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
        .background(
            LinearGradient(
                colors: [
                    Color(.systemBackground).opacity(0.8),
                    Color(.systemBackground)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
    
    private var weeklyEntries: Int {
        let calendar = Calendar.current
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return entries.filter { entry in
            entry.timestamp >= weekAgo
        }.count
    }
}

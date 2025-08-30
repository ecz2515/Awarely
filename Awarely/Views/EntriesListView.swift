//
//  EntriesListView.swift
//  Awarely
//
//  Created by Evan Chen on 8/23/25.
//

import SwiftUI

struct EntriesListView: View {
    @Binding var entries: [LogEntry]
    @Binding var customTags: [String]
    @Environment(\.dismiss) private var dismiss
    @State private var selectedDate = Date()
    @State private var currentWeekOffset = 0
    @EnvironmentObject var coreDataManager: CoreDataManager
    
    var selectedDateEntries: [LogEntry] {
        let calendar = Calendar.current
        return entries.filter { entry in
            calendar.isDate(entry.timestamp, inSameDayAs: selectedDate)
        }.sorted { $0.timePeriodStart > $1.timePeriodStart } // Sort by when activity occurred, newest first
    }
    
    var weekDates: [Date] {
        let calendar = Calendar.current
        let today = Date()
        let weekStart = calendar.dateInterval(of: .weekOfYear, for: today)?.start ?? today
        let adjustedWeekStart = calendar.date(byAdding: .weekOfYear, value: currentWeekOffset, to: weekStart) ?? weekStart
        
        return (0..<7).compactMap { dayOffset in
            calendar.date(byAdding: .day, value: dayOffset, to: adjustedWeekStart)
        }
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
                    // Fixed Weekly Calendar at Top
                    weeklyCalendar
                    
                    // Scrollable Entries List
                    ScrollView {
                        VStack(spacing: 0) {
                            if selectedDateEntries.isEmpty {
                                emptyState
                            } else {
                                LazyVStack(spacing: 12) {
                                    ForEach(selectedDateEntries) { entry in
                                        EnhancedEntryRow(
                                            entry: entry, 
                                            customTags: customTags,
                                            onEdit: { updated in
                                                if let idx = entries.firstIndex(where: { $0.id == updated.id }) {
                                                    entries[idx] = updated
                                                    // Save updated entry to Core Data
                                                    coreDataManager.updateLogEntry(updated)
                                                }
                                            },
                                            onDelete: { entryId in
                                                // Remove from local array
                                                entries.removeAll { $0.id == entryId }
                                                // Delete from Core Data
                                                coreDataManager.deleteLogEntry(withId: entryId)
                                            }
                                        )
                                        .transition(.asymmetric(
                                            insertion: .scale.combined(with: .opacity),
                                            removal: .scale.combined(with: .opacity)
                                        ))
                                    }
                                }
                                .padding(.horizontal, 20)
                                .padding(.bottom, 20)
                            }
                        }
                    }
                }
            }
            .navigationTitle("All Entries")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(.headline.weight(.medium))
                }
            }
            .gesture(
                DragGesture()
                    .onEnded { value in
                        let threshold: CGFloat = 50
                        if value.translation.width > threshold {
                            // Swipe right - go to previous week
                            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                                currentWeekOffset -= 1
                                // Keep selected date in sync with current week
                                if !weekDates.contains(selectedDate) {
                                    selectedDate = weekDates[3] // Middle of the week
                                }
                            }
                        } else if value.translation.width < -threshold {
                            // Swipe left - go to next week
                            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                                currentWeekOffset += 1
                                // Keep selected date in sync with current week
                                if !weekDates.contains(selectedDate) {
                                    selectedDate = weekDates[3] // Middle of the week
                                }
                            }
                        }
                    }
            )
        }
    }
    
    private var weeklyCalendar: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Select Date")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.primary)
                Spacer()
                
                // Today button
                Button(action: {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                        currentWeekOffset = 0
                        selectedDate = Date()
                    }
                }) {
                    Text("Today")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.blue)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.blue.opacity(0.1), in: Capsule())
                }
                
                // Week navigation buttons
                HStack(spacing: 12) {
                    Button(action: {
                        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                            currentWeekOffset -= 1
                            if !weekDates.contains(selectedDate) {
                                selectedDate = weekDates[3]
                            }
                        }
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.blue)
                            .frame(width: 32, height: 32)
                            .background(Color.blue.opacity(0.1), in: Circle())
                    }
                    
                    Button(action: {
                        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                            currentWeekOffset += 1
                            if !weekDates.contains(selectedDate) {
                                selectedDate = weekDates[3]
                            }
                        }
                    }) {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.blue)
                            .frame(width: 32, height: 32)
                            .background(Color.blue.opacity(0.1), in: Circle())
                    }
                }
            }
            
            HStack(spacing: 6) {
                ForEach(weekDates, id: \.self) { date in
                    DayButton(
                        date: date,
                        isSelected: Calendar.current.isDate(date, inSameDayAs: selectedDate),
                        entryCount: entriesForDate(date).count
                    ) {
                        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                            selectedDate = date
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 24)
        .background(Color(.systemBackground))
    }
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 48, weight: .light))
                .foregroundStyle(.secondary)
            
            Text("No entries for \(selectedDate.formatted(date: .abbreviated, time: .omitted))")
                .font(.title3.weight(.medium))
                .foregroundStyle(.primary)
            
            Text("Select a different date or add new entries")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, minHeight: 300)
        .padding(40)
    }
    
    private func entriesForDate(_ date: Date) -> [LogEntry] {
        let calendar = Calendar.current
        return entries.filter { entry in
            calendar.isDate(entry.timestamp, inSameDayAs: date)
        }
    }
}

struct DayButton: View {
    let date: Date
    let isSelected: Bool
    let entryCount: Int
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Text(date.formatted(.dateTime.weekday(.abbreviated)))
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(isSelected ? .white : .secondary)
                
                Text(date.formatted(.dateTime.day()))
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(isSelected ? .white : .primary)
            }
            .frame(width: 44, height: 60)
            .background(
                isSelected ? Color.blue : Color(.systemGray6),
                in: RoundedRectangle(cornerRadius: 12, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(isSelected ? .clear : Color(.systemGray4), lineWidth: 0.5)
            )
        }
    }
}

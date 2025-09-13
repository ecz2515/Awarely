//
//  CatchUpView.swift
//  Awarely
//
//  Created by Evan Chen on 8/23/25.
//

import SwiftUI

struct CatchUpView: View {
    @Binding var entries: [LogEntry]
    @Binding var customTags: [String]
    let missedIntervals: [(start: Date, end: Date)]
    @Environment(\.dismiss) private var dismiss
    @State private var selectedIntervals: Set<Int> = []
    @State private var bulkText = ""
    @State private var showingCompletion = false
    @State private var completionScale: CGFloat = 0.8
    @State private var completionOpacity: Double = 0
    @FocusState private var isTextFieldFocused: Bool
    @ObservedObject var intervalTimer: IntervalTimer
    @EnvironmentObject var coreDataManager: CoreDataManager
    
    // Order missed intervals latest first - use current missed intervals
    private var orderedMissedIntervals: [(start: Date, end: Date)] {
        return intervalTimer.getMissedIntervals(for: entries).reversed()
    }
    
    // Track which intervals have been completed by their time period
    // Note: This could be simplified further by just using the entries array
    @State private var completedIntervals: Set<String> = []
    
    // Helper function to generate a unique key for an interval
    private func intervalKey(for interval: (start: Date, end: Date)) -> String {
        return "\(interval.start.timeIntervalSince1970)-\(interval.end.timeIntervalSince1970)"
    }
    
    // MARK: - Computed Views
    
    private var mainContent: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: 0) {
                    headerSection
                    intervalsListSection
                    
                    if !selectedIntervals.isEmpty {
                        bulkActionSection
                            .id("textFieldSection")
                    }
                }
            }
            .onChange(of: isTextFieldFocused) { _, isFocused in
                if isFocused {
                    // Scroll to text field when it becomes focused
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        withAnimation(.easeInOut(duration: 0.5)) {
                            proxy.scrollTo("textFieldSection", anchor: .bottom)
                        }
                    }
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Cancel") {
                    dismiss()
                }
            }
            
            ToolbarItem(placement: .topBarTrailing) {
                Button("Done") {
                    dismiss()
                }
                .fontWeight(.semibold)
            }
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            Text("Catch Up on Missed Intervals")
                .font(.title2.weight(.bold))
                .foregroundStyle(.primary)
            
            Text("Select intervals to log your activities")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 24)
    }
    
    private var intervalsListSection: some View {
        LazyVStack(spacing: 0) {
            ForEach(Array(orderedMissedIntervals.enumerated()), id: \.offset) { index, interval in
                let intervalKeyValue = intervalKey(for: interval)
                let isSelected = selectedIntervals.contains(index)
                let isCompleted = completedIntervals.contains(intervalKeyValue)
                
                IntervalRowView(
                    index: index,
                    interval: interval,
                    isSelected: isSelected,
                    isCompleted: isCompleted,
                    onTap: {
                        if !completedIntervals.contains(intervalKeyValue) {
                            if selectedIntervals.contains(index) {
                                selectedIntervals.remove(index)
                            } else {
                                selectedIntervals.insert(index)
                            }
                        }
                    }
                )
                
                if index < orderedMissedIntervals.count - 1 {
                    Divider()
                        .padding(.leading, 20)
                }
            }
        }
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal, 20)
    }
    
    private var bulkActionSection: some View {
        VStack(spacing: 20) {
            quickTagsSection
            
            TextField("What did you accomplish?", text: $bulkText)
                .textInputAutocapitalization(.sentences)
                .disableAutocorrection(false)
                .font(.body)
                .submitLabel(.done)
                .focused($isTextFieldFocused)
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .strokeBorder(.quaternary, lineWidth: 0.5)
                )
            
            HStack(spacing: 12) {
                Button("Log Selected") {
                    markSelectedAsCompleted()
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    bulkText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    ? .secondary
                    : Color.blue,
                    in: RoundedRectangle(cornerRadius: 16, style: .continuous)
                )
                .disabled(bulkText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                
                Button("Skip") {
                    selectedIntervals.removeAll()
                    bulkText = ""
                }
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    Color(.systemGray5),
                    in: RoundedRectangle(cornerRadius: 16, style: .continuous)
                )
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(.quaternary, lineWidth: 0.5)
                )
        )
        .padding(.horizontal, 20)
        .padding(.top, 24)
        .padding(.bottom, 40)
    }
    
    private var completionOverlay: some View {
        VStack(spacing: 24) {
            // Checkmark animation
            ZStack {
                Circle()
                    .fill(.green.opacity(0.1))
                    .frame(width: 120, height: 120)
                
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(.green)
                    .scaleEffect(completionScale)
                    .animation(.spring(response: 0.6, dampingFraction: 0.6), value: completionScale)
            }
            
            VStack(spacing: 8) {
                Text("All Caught Up!")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.primary)
                
                Text("Well done 🎉")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(40)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .strokeBorder(.quaternary, lineWidth: 0.5)
                )
        )
        .frame(maxWidth: 300)
        .scaleEffect(completionScale)
        .opacity(completionOpacity)
        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: completionScale)
        .animation(.easeInOut(duration: 0.3), value: completionOpacity)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                if !showingCompletion {
                    mainContent
                }
                
                if showingCompletion {
                    completionOverlay
                }
            }
            .onSubmit {
                // Dismiss keyboard when Done is pressed
                isTextFieldFocused = false
                // Force dismiss keyboard as backup
                DispatchQueue.main.async {
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }
            }
            .onTapGesture {
                // Dismiss keyboard when tapping outside text field
                isTextFieldFocused = false
            }
        }
        .onChange(of: completedIntervals) { _, newValue in
            handleCompletedIntervalsChange(newValue)
        }
        .onChange(of: entries) { _, newValue in
            handleEntriesChange(newValue)
        }
    }
    
    private func handleCompletedIntervalsChange(_ newValue: Set<String>) {
        // Simple check: if we have no missed intervals left, show completion
        checkForCompletion()
    }
    
    private func cleanupCompletedIntervals() {
        // When missed intervals change, we need to check if any of the current
        // completed intervals are no longer in the missed intervals list
        // and remove them from completedIntervals to avoid showing green checkmarks
        // for intervals that are no longer considered "missed"
        let currentIntervalKeys = Set(orderedMissedIntervals.map { interval in
            intervalKey(for: interval)
        })
        
        // Remove completed intervals that are no longer in the missed intervals list
        completedIntervals = completedIntervals.intersection(currentIntervalKeys)
    }
    
    private func handleEntriesChange(_ newValue: [LogEntry]) {
        intervalTimer.updateTimerState(with: entries)
        cleanupCompletedIntervals()
        checkForCompletion()
    }
    
    private func checkForCompletion() {
        // Get fresh missed intervals from the timer
        let currentMissedIntervals = intervalTimer.getMissedIntervals(for: entries)
        
        // Show completion if:
        // 1. No missed intervals remain
        // 2. We have at least one entry (prevent showing on empty state)
        // 3. We're not already showing completion
        if currentMissedIntervals.isEmpty && !entries.isEmpty && !showingCompletion {
            showCompletionAnimation()
        }
    }
    
    private var quickTagsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Quick Tags")
                .font(.headline.weight(.semibold))
                .foregroundStyle(.primary)
            
            if customTags.isEmpty {
                Text("No quick tags available")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 8)
            } else {
                FlowLayout(spacing: 8) {
                    ForEach(customTags, id: \.self) { tag in
                        TagButtonWithFeedback(
                            title: tag,
                            action: {
                                addTagToText(tag)
                            }
                        )
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
    
    private func addTagToText(_ tag: String) {
        let trimmed = bulkText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmed.isEmpty {
            // First tag - just add it
            bulkText = tag
        } else {
            // Subsequent tag - add ", [tag]"
            bulkText = trimmed + ", " + tag
        }
    }
    
    private func markSelectedAsCompleted() {
        let text = bulkText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        
        // Get the original missed intervals in chronological order (not reversed)
        let originalMissedIntervals = intervalTimer.getMissedIntervals(for: entries)
        
        for index in selectedIntervals {
            guard index < orderedMissedIntervals.count else { continue }
            let interval = orderedMissedIntervals[index]
            
            // Find the corresponding interval in the original chronological order
            // Since orderedMissedIntervals is reversed, we need to map the index correctly
            let originalIndex = originalMissedIntervals.count - 1 - index
            guard originalIndex >= 0 && originalIndex < originalMissedIntervals.count else { continue }
            let originalInterval = originalMissedIntervals[originalIndex]
            
            let newEntry = LogEntry(
                text: text,
                tags: [],
                timestamp: Date(),
                timePeriodStart: originalInterval.start,
                timePeriodEnd: originalInterval.end
            )
            
            // Save to Core Data first
            coreDataManager.addLogEntry(newEntry)
            
            // Then add to UI
            entries.insert(newEntry, at: 0)
            
            // Mark this interval as completed using its time period as key
            let intervalKey = intervalKey(for: originalInterval)
            completedIntervals.insert(intervalKey)
        }
        
        selectedIntervals.removeAll()
        bulkText = ""
        
        // Check if we're now caught up
        checkForCompletion()
    }
    
    private func showCompletionAnimation() {
        showingCompletion = true
        completionOpacity = 1
        completionScale = 1.0
        
        // Auto-dismiss after animation
        // Change this value to adjust how long the completion animation shows
        let autoDismissDelay: TimeInterval = 1.0 // seconds
        
        DispatchQueue.main.asyncAfter(deadline: .now() + autoDismissDelay) {
            withAnimation(.easeInOut(duration: 0.3)) {
                completionOpacity = 0
                completionScale = 0.8
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                dismiss()
            }
        }
    }
}

// MARK: - IntervalRowView

struct IntervalRowView: View {
    let index: Int
    let interval: (start: Date, end: Date)
    let isSelected: Bool
    let isCompleted: Bool
    let onTap: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("\(interval.start.formatted(date: .omitted, time: .shortened)) - \(interval.end.formatted(date: .omitted, time: .shortened))")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.primary)
                
                Text("\(Int(interval.end.timeIntervalSince(interval.start) / 60)) minutes")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.blue)
            } else if isCompleted {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
    }
}

#Preview {
    let sampleIntervals = [
        (start: Date().addingTimeInterval(-3600), end: Date().addingTimeInterval(-3300)),
        (start: Date().addingTimeInterval(-3300), end: Date().addingTimeInterval(-3000))
    ]
    
    CatchUpView(entries: .constant([]), customTags: .constant(["Work", "Meeting", "Break"]), missedIntervals: sampleIntervals, intervalTimer: IntervalTimer())
} 

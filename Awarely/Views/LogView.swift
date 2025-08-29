//
//  LogView.swift
//  Awarely
//
//  Created by Evan Chen on 8/23/25.
//

import SwiftUI

struct TagButtonWithFeedback: View {
    let title: String
    let action: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            // Haptic feedback
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
            
            // Visual feedback
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = true
            }
            
            // Execute the action
            action()
            
            // Reset visual feedback
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.easeInOut(duration: 0.1)) {
                    isPressed = false
                }
            }
        }) {
            HStack(spacing: 6) {
                Image(systemName: "plus")
                    .font(.caption2)
                    .foregroundStyle(.blue)
                
                Text(title)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.blue)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color.blue.opacity(isPressed ? 0.2 : 0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .strokeBorder(Color.blue.opacity(isPressed ? 0.5 : 0.3), lineWidth: 1)
                    )
            )
            .scaleEffect(isPressed ? 0.95 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct LogView: View {
    @Binding var entries: [LogEntry]
    @Binding var newEntry: String
    @Binding var selectedTags: Set<String>
    @Binding var customTags: [String]
    @FocusState var isFieldFocused: Bool
    @State private var showingCustomTags = false
    @State private var showingCatchUpFlow = false
    @State private var showingSuccessAnimation = false
    @ObservedObject var intervalTimer: IntervalTimer
    @Binding var shouldNavigateToHome: Bool
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var coreDataManager: CoreDataManager
    
    private var reminderIntervalText: String {
        // Get the reminder interval from Core Data or use default 30 minutes
        let userProfile = coreDataManager.getUserProfile()
        let reminderInterval = userProfile?.reminderInterval ?? 30 * 60
        let reminderMinutes = Int(reminderInterval / 60)
        return "\(reminderMinutes)"
    }
    
    private var isLoggingMissedInterval: Bool {
        // Only show red if we're in late grace period AND there's already a previous entry
        // Otherwise, show blue/green to encourage logging
        return intervalTimer.isLateGracePeriod && intervalTimer.hasEntryForPreviousInterval(entries: entries)
    }
    
    private var isLoggingDisabled: Bool {
        let currentInterval = getCurrentLoggingInterval()
        
        // If we're in late grace period, allow logging even if there's an entry
        // This allows users to update their late entry
        if intervalTimer.isLateGracePeriod {
            return false
        }
        
        // Check if we already have an entry for this interval
        let hasEntry = entries.contains { entry in
            let entryStart = entry.timePeriodStart
            let entryEnd = entry.timePeriodEnd
            return abs(entryStart.timeIntervalSince(currentInterval.start)) < 60 && 
                   abs(entryEnd.timeIntervalSince(currentInterval.end)) < 60
        }
        
        return hasEntry
    }
    
    private var shouldNavigateBack: Bool {
        // Never navigate back - let TimerOverlay handle the display
        return false
    }
    
    private func getCurrentLoggingInterval() -> (start: Date, end: Date, isLateGrace: Bool) {
        let now = Date()
        let calendar = Calendar.current
        let userProfile = coreDataManager.getUserProfile()
        let reminderInterval = userProfile?.reminderInterval ?? 30 * 60
        let intervalMinutes = Int(reminderInterval / 60)
        let intervalDuration: TimeInterval = TimeInterval(intervalMinutes * 60)
        
        // Get grace periods from Core Data
        let gracePeriodMinutes = userProfile?.loggingGracePeriod ?? 5
        _ = Int(gracePeriodMinutes) // Default to 5 minutes
        
        // Calculate interval boundaries
        let currentMinute = calendar.component(.minute, from: now)
        let intervalStartMinute: Int
        if currentMinute < intervalMinutes {
            intervalStartMinute = 0
        } else {
            intervalStartMinute = intervalMinutes
        }
        
        var components = calendar.dateComponents([.year, .month, .day, .hour], from: now)
        components.minute = intervalStartMinute
        components.second = 0
        
        let currentIntervalStart = calendar.date(from: components) ?? now
        let currentIntervalEnd = currentIntervalStart.addingTimeInterval(intervalDuration)
        let previousIntervalStart = currentIntervalStart.addingTimeInterval(-intervalDuration)
        let previousIntervalEnd = currentIntervalStart
        
        // Use IntervalTimer's state to determine if we're in late grace period
        if intervalTimer.isLateGracePeriod {
            // Late grace: log for previous interval
            return (start: previousIntervalStart, end: previousIntervalEnd, isLateGrace: true)
        } else {
            // Normal case: log for current interval
            return (start: currentIntervalStart, end: currentIntervalEnd, isLateGrace: false)
        }
    }
    
    private func getMissedIntervals() -> [(start: Date, end: Date)] {
        return intervalTimer.getMissedIntervals(for: entries)
    }
    
    private func getLoggingWindowString() -> String {
        let interval = getCurrentLoggingInterval()
        let startTime = interval.start.formatted(date: .omitted, time: .shortened)
        let endTime = interval.end.formatted(date: .omitted, time: .shortened)
        
        // Only show "(Late)" if we're in late grace period AND there's already a previous entry
        if interval.isLateGrace && intervalTimer.hasEntryForPreviousInterval(entries: entries) {
            return "\(startTime) - \(endTime) (Late)"
        } else {
            return "\(startTime) - \(endTime)"
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
                
                ScrollView {
                    VStack(spacing: 0) {
                        // Header
                        logHeader
                        
                        // Catch-up Section
                        catchUpSection
                        
                        // Quick Tags Section
                        quickTagsSection
                        
                        // Customize Tags Section
                        customizeTagsSection
                        
                        // Input Section
                        inputSection
                        
                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 40)
                    .padding(.bottom, 20)
                }
                .onTapGesture {
                    // Dismiss keyboard when tapping outside text field
                    isFieldFocused = false
                }
            }
            .sheet(isPresented: $showingCustomTags) {
                CustomTagsView(customTags: $customTags)
            }
            .sheet(isPresented: $showingCatchUpFlow) {
                CatchUpView(entries: $entries, customTags: $customTags, missedIntervals: getMissedIntervals(), intervalTimer: intervalTimer)
            }
            .overlay {
                if showingSuccessAnimation || (!intervalTimer.isLoggingWindow || isLoggingDisabled) {
                    // Glass-morphism background that's always present
                    Rectangle()
                        .fill(.ultraThinMaterial)
                        .ignoresSafeArea()
                        .overlay {
                            if showingSuccessAnimation {
                                successAnimationContent
                            } else if !intervalTimer.isLoggingWindow || isLoggingDisabled {
                                TimerOverlay(
                                    intervalTimer: intervalTimer, 
                                    entries: $entries, 
                                    customTags: $customTags,
                                    showTimeUntilNextIntervalEnd: isLoggingDisabled
                                )
                            }
                        }
                }
            }
        }

        .onChange(of: entries) { _, _ in
            intervalTimer.updateTimerState(with: entries)
        }
        .onAppear {
            intervalTimer.updateTimerState(with: entries)
        }
    }
    
    private var logHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            VStack(alignment: .leading, spacing: 4) {
                Text("What did you do?")
                    .font(.largeTitle.weight(.bold))
                    .foregroundStyle(.primary)
                
                Text("Log your activity for the past \(reminderIntervalText) minutes")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            // Time period indicator
            VStack(spacing: 8) {
                HStack {
                    Image(systemName: "clock")
                        .font(.subheadline)
                        .foregroundStyle(isLoggingMissedInterval ? .red : .blue)
                    
                    Text("Logging for: \(getLoggingWindowString())")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(isLoggingMissedInterval ? .red : .blue)
                    
                    Spacer()
                }
                

                

            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(isLoggingMissedInterval ? Color.red.opacity(0.1) : Color.blue.opacity(0.1))
            )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.bottom, 24)
    }
    
    private var catchUpSection: some View {
        VStack(spacing: 0) {
            if !getMissedIntervals().isEmpty {
                Button(action: { showingCatchUpFlow = true }) {
                    HStack {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.subheadline)
                            .foregroundStyle(.orange)
                        
                        Text("Catch up on \(getMissedIntervals().count) missed intervals")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.orange)
                        
                        Spacer()
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(Color.orange.opacity(0.1))
                    )
                }
                .padding(.top, -8)
                .padding(.bottom, 20)
            }
        }
    }
    
    private var quickTagsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Quick Tags")
                .font(.headline.weight(.semibold))
                .foregroundStyle(.primary)
            
            if customTags.isEmpty {
                Text("Add custom tags to quickly log common activities")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity, alignment: .leading)
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
        .padding(.bottom, 20)
    }
    
    private var customizeTagsSection: some View {
        VStack(spacing: 12) {
            Button(action: {
                showingCustomTags = true
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "slider.horizontal.3")
                        .font(.subheadline)
                    Text("Customize Quick Tags")
                        .font(.subheadline.weight(.medium))
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .foregroundStyle(.primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
        }
        .padding(.bottom, 24)
    }
    
    private var inputSection: some View {
        VStack(spacing: 20) {
            VStack(spacing: 12) {
                TextField("Describe what you did...", text: $newEntry, axis: .vertical)
                    .textInputAutocapitalization(.sentences)
                    .disableAutocorrection(false)
                    .focused($isFieldFocused)
                    .submitLabel(.done)
                    .onSubmit { addEntry() }
                    .font(.body)
                    .lineLimit(3...6)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .strokeBorder(.quaternary, lineWidth: 0.5)
                    )

            }
            
            Button(action: addEntry) {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 18, weight: .semibold))
                    Text("Log Activity")
                        .font(.headline.weight(.semibold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    (newEntry.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoggingDisabled)
                    ? .secondary 
                    : Color.blue,
                    in: RoundedRectangle(cornerRadius: 16, style: .continuous)
                )
            }
            .disabled(newEntry.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoggingDisabled)
            .scaleEffect((newEntry.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoggingDisabled) ? 0.98 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: newEntry.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoggingDisabled)
            
            if isLoggingDisabled {
                Text("Already logged for this time period")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.top, 8)
            }
        }
    }
    
    private func addTagToText(_ tag: String) {
        let trimmed = newEntry.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmed.isEmpty {
            // First tag - just add it
            newEntry = tag
        } else {
            // Subsequent tag - add ", [tag]"
            newEntry = trimmed + ", " + tag
        }
        
        // Don't automatically focus the text field - let user decide if they want to type more
    }
    
    private func addEntry() {
        let trimmed = newEntry.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        let currentInterval = getCurrentLoggingInterval()
        
        let newLogEntry = LogEntry(
            text: trimmed,
            tags: [], // No longer using selectedTags since we're embedding tags in text
            timestamp: Date(),
            timePeriodStart: currentInterval.start,
            timePeriodEnd: currentInterval.end
        )
        
        // Save to Core Data
        coreDataManager.addLogEntry(newLogEntry)
        
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            entries.insert(newLogEntry, at: 0)
        }
        
        newEntry = ""
        isFieldFocused = true
        
        // Show success animation
        withAnimation(.easeInOut(duration: 0.3)) {
            showingSuccessAnimation = true
        }
        
        // Hide success animation after 1.5 seconds and show TimerOverlay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.easeInOut(duration: 0.3)) {
                showingSuccessAnimation = false
            }
        }
    }
    
    private var successAnimationContent: some View {
        VStack(spacing: 24) {
            // Success checkmark with animation
            ZStack {
                Circle()
                    .fill(.green)
                    .frame(width: 80, height: 80)
                    .scaleEffect(showingSuccessAnimation ? 1.0 : 0.5)
                    .animation(.spring(response: 0.6, dampingFraction: 0.6).delay(0.1), value: showingSuccessAnimation)
                
                Image(systemName: "checkmark")
                    .font(.system(size: 40, weight: .bold))
                    .foregroundStyle(.white)
                    .scaleEffect(showingSuccessAnimation ? 1.0 : 0.0)
                    .animation(.spring(response: 0.6, dampingFraction: 0.6).delay(0.3), value: showingSuccessAnimation)
            }
            
            // Success text
            VStack(spacing: 8) {
                Text("Activity Logged!")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.primary)
                    .opacity(showingSuccessAnimation ? 1.0 : 0.0)
                    .animation(.easeInOut(duration: 0.4).delay(0.4), value: showingSuccessAnimation)
                
                Text("Your activity has been recorded")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .opacity(showingSuccessAnimation ? 1.0 : 0.0)
                    .animation(.easeInOut(duration: 0.4).delay(0.5), value: showingSuccessAnimation)
            }
        }
        .padding(40)
    }
}

struct CustomTagsView: View {
    @Binding var customTags: [String]
    @Environment(\.dismiss) private var dismiss
    @State private var newTag = ""
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Add new tag section
                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Add New Tag")
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(.primary)
                        
                        Text("Create quick tags for common activities")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    HStack(spacing: 12) {
                        TextField("Enter tag name...", text: $newTag)
                            .textFieldStyle(.roundedBorder)
                            .focused($isTextFieldFocused)
                            .onSubmit {
                                addTag()
                            }
                        
                        Button(action: addTag) {
                            HStack(spacing: 6) {
                                Image(systemName: "plus")
                                    .font(.subheadline.weight(.semibold))
                                Text("Add")
                                    .font(.subheadline.weight(.semibold))
                            }
                            .foregroundStyle(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(
                                newTag.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                ? Color.gray
                                : Color.blue,
                                in: RoundedRectangle(cornerRadius: 12, style: .continuous)
                            )
                        }
                        .disabled(newTag.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        .scaleEffect(newTag.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.95 : 1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: newTag.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
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
                .padding(.horizontal, 20)
                .padding(.top, 20)
                
                // Tags list
                VStack(spacing: 0) {
                    HStack {
                        Text("Your Tags")
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(.primary)
                        
                        Spacer()
                        
                        Text("\(customTags.count) tag\(customTags.count == 1 ? "" : "s")")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(.ultraThinMaterial)
                            )
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 24)
                    .padding(.bottom, 16)
                    
                    if customTags.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "tag")
                                .font(.system(size: 32))
                                .foregroundStyle(.secondary)
                            
                            Text("No tags yet")
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                    } else {
                        List {
                            ForEach(customTags, id: \.self) { tag in
                                HStack(spacing: 12) {
                                    Image(systemName: "tag.fill")
                                        .font(.subheadline)
                                        .foregroundStyle(.blue)
                                    
                                    Text(tag)
                                        .font(.body)
                                        .foregroundStyle(.primary)
                                    
                                    Spacer()
                                    
                                    Button(action: {
                                        deleteTag(tag)
                                    }) {
                                        Image(systemName: "trash")
                                            .font(.subheadline)
                                            .foregroundStyle(.red)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                                .padding(.vertical, 4)
                                .swipeActions(edge: .trailing) {
                                    Button("Delete", role: .destructive) {
                                        deleteTag(tag)
                                    }
                                }
                            }
                        }
                        .listStyle(.plain)
                    }
                }
                
                Spacer()
            }
            .navigationTitle("Quick Tags")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.blue)
                }
            }
        }
        .onTapGesture {
            // Dismiss keyboard when tapping outside
            isTextFieldFocused = false
        }
    }
    
    private func addTag() {
        let trimmed = newTag.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty && !customTags.contains(trimmed) else { return }
        
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            customTags.append(trimmed)
        }
        
        newTag = ""
        isTextFieldFocused = false
        
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
    }
    
    private func deleteTag(_ tag: String) {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            customTags.removeAll { $0 == tag }
        }
        
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
    }
}

struct FlowLayout: Layout {
    let spacing: CGFloat
    
    init(spacing: CGFloat = 8) {
        self.spacing = spacing
    }
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: LayoutSubviews, cache: inout ()) -> CGSize {
        let result = FlowResult(
            in: proposal.replacingUnspecifiedDimensions().width,
            subviews: subviews,
            spacing: spacing
        )
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: LayoutSubviews, cache: inout ()) {
        let result = FlowResult(
            in: bounds.width,
            subviews: subviews,
            spacing: spacing
        )
        
        for (index, subview) in subviews.enumerated() {
            let position = result.positions[index]
            subview.place(at: CGPoint(x: position.x + bounds.minX, y: position.y + bounds.minY), proposal: .unspecified)
        }
    }
}

struct FlowResult {
    let positions: [CGPoint]
    let size: CGSize
    
    init(in maxWidth: CGFloat, subviews: LayoutSubviews, spacing: CGFloat) {
        var positions: [CGPoint] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0
        var maxWidthUsed: CGFloat = 0
        
        for subview in subviews {
            let subviewSize = subview.sizeThatFits(.unspecified)
            
            if currentX + subviewSize.width > maxWidth && currentX > 0 {
                // Move to next line
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }
            
            positions.append(CGPoint(x: currentX, y: currentY))
            currentX += subviewSize.width + spacing
            lineHeight = max(lineHeight, subviewSize.height)
            maxWidthUsed = max(maxWidthUsed, currentX - spacing)
        }
        
        self.positions = positions
        self.size = CGSize(width: maxWidthUsed, height: currentY + lineHeight)
    }
}

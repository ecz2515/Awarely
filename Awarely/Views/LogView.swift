//
//  LogView.swift
//  Awarely
//
//  Created by Evan Chen on 8/23/25.
//

import SwiftUI

struct LogView: View {
    @Binding var entries: [LogEntry]
    @Binding var newEntry: String
    @Binding var selectedTags: Set<String>
    @Binding var customTags: [String]
    @FocusState var isFieldFocused: Bool
    @State private var showingCustomTags = false
    @ObservedObject var intervalTimer: IntervalTimer
    
    private var gracePeriodText: String {
        let gracePeriod = UserDefaults.standard.integer(forKey: "loggingGracePeriod")
        let gracePeriodMinutes = gracePeriod > 0 ? gracePeriod : 15
        return "\(gracePeriodMinutes)"
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
            }
            .sheet(isPresented: $showingCustomTags) {
                CustomTagsView(customTags: $customTags)
            }
            .overlay {
                if !intervalTimer.isLoggingWindow {
                    TimerOverlay(intervalTimer: intervalTimer)
                }
            }
        }
    }
    
    private var logHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("What did you do?")
                        .font(.largeTitle.weight(.bold))
                        .foregroundStyle(.primary)
                    
                    Text("Log your activity for the past 30 minutes")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    Text("Grace period: \(gracePeriodText) minutes before interval ends")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Image(systemName: "timer")
                        .font(.title2)
                        .foregroundStyle(.orange)
                        .opacity(0.7)
                    
                    if intervalTimer.isLoggingWindow {
                        Text("Logging window")
                            .font(.caption)
                            .foregroundStyle(.green)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(.green.opacity(0.1), in: Capsule())
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.bottom, 24)
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
                        Button(action: {
                            addTagToText(tag)
                        }) {
                            Text(tag)
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(.blue)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Color.blue.opacity(0.1), in: Capsule())
                        }
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
                    (newEntry.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || !intervalTimer.isLoggingWindow)
                    ? .secondary 
                    : Color.blue,
                    in: RoundedRectangle(cornerRadius: 16, style: .continuous)
                )
            }
            .disabled(newEntry.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || !intervalTimer.isLoggingWindow)
            .scaleEffect((newEntry.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || !intervalTimer.isLoggingWindow) ? 0.98 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: newEntry.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || !intervalTimer.isLoggingWindow)
            
            if !intervalTimer.isLoggingWindow {
                Text("Logging is only available during the grace period")
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
        
        // Focus the text field and move cursor to end
        isFieldFocused = true
    }
    
    private func addEntry() {
        let trimmed = newEntry.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        // Check if we're within the logging grace period
        if !intervalTimer.isLoggingWindow {
            // Show an alert or message that logging is not allowed outside the grace period
            return
        }
        
        let newLogEntry = LogEntry(
            text: trimmed,
            tags: [], // No longer using selectedTags since we're embedding tags in text
            timestamp: Date()
        )
        
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            entries.insert(newLogEntry, at: 0)
        }
        
        newEntry = ""
        isFieldFocused = true
    }
}

struct CustomTagsView: View {
    @Binding var customTags: [String]
    @Environment(\.dismiss) private var dismiss
    @State private var newTag = ""
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Add new tag section
                VStack(spacing: 16) {
                    HStack {
                        TextField("Add new tag...", text: $newTag)
                            .textFieldStyle(.roundedBorder)
                        
                        Button("Add") {
                            addTag()
                        }
                        .disabled(newTag.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        .foregroundStyle(.blue)
                    }
                }
                .padding(20)
                .background(Color(.systemGray6))
                
                // Tags list
                List {
                    ForEach(customTags, id: \.self) { tag in
                        HStack {
                            Text(tag)
                                .font(.body)
                            Spacer()
                        }
                        .swipeActions(edge: .trailing) {
                            Button("Delete", role: .destructive) {
                                deleteTag(tag)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Custom Tags")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func addTag() {
        let trimmed = newTag.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty && !customTags.contains(trimmed) else { return }
        
        customTags.append(trimmed)
        newTag = ""
    }
    
    private func deleteTag(_ tag: String) {
        customTags.removeAll { $0 == tag }
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

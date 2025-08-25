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
    @FocusState var isFieldFocused: Bool
    let commonTags: [String]
    
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
                    logHeader
                    
                    // Tags Section
                    tagsSection
                    
                    // Input Section
                    inputSection
                    
                    Spacer()
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
                }
                
                Spacer()
                
                Image(systemName: "timer")
                    .font(.title2)
                    .foregroundStyle(.orange)
                    .opacity(0.7)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 16)
    }
    
    private var tagsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Tags")
                .font(.headline.weight(.semibold))
                .padding(.horizontal, 20)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(commonTags, id: \.self) { tag in
                        TagButton(
                            title: tag,
                            isSelected: selectedTags.contains(tag)
                        ) {
                            if selectedTags.contains(tag) {
                                selectedTags.remove(tag)
                            } else {
                                selectedTags.insert(tag)
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
        }
        .padding(.bottom, 20)
    }
    
    private var inputSection: some View {
        VStack(spacing: 16) {
            VStack(spacing: 12) {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(.blue)
                        .opacity(0.7)
                    
                    TextField("Describe what you did...", text: $newEntry, axis: .vertical)
                        .textInputAutocapitalization(.sentences)
                        .disableAutocorrection(false)
                        .focused($isFieldFocused)
                        .submitLabel(.done)
                        .onSubmit { addEntry() }
                        .font(.body)
                        .lineLimit(3...6)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .strokeBorder(.quaternary, lineWidth: 0.5)
                )
                
                // Selected tags display
                if !selectedTags.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(Array(selectedTags), id: \.self) { tag in
                                HStack(spacing: 4) {
                                    Text(tag)
                                        .font(.caption.weight(.medium))
                                    Button(action: {
                                        selectedTags.remove(tag)
                                    }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .font(.caption)
                                    }
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(.blue.opacity(0.1), in: Capsule())
                                .foregroundStyle(.blue)
                            }
                        }
                        .padding(.horizontal, 4)
                    }
                }
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
                    newEntry.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty 
                    ? .secondary 
                    : Color.blue,
                    in: RoundedRectangle(cornerRadius: 16, style: .continuous)
                )
            }
            .disabled(newEntry.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .scaleEffect(newEntry.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.98 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: newEntry.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding(.horizontal, 20)
    }
    
    private func addEntry() {
        let trimmed = newEntry.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        let newLogEntry = LogEntry(
            text: trimmed,
            tags: Array(selectedTags),
            timestamp: Date()
        )
        
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            entries.insert(newLogEntry, at: 0)
        }
        
        newEntry = ""
        selectedTags.removeAll()
        isFieldFocused = true
    }
}

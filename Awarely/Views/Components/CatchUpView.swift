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
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    // Header
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
                    
                    // Missed intervals list
                    LazyVStack(spacing: 0) {
                        ForEach(Array(missedIntervals.enumerated()), id: \.offset) { index, interval in
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
                                
                                if selectedIntervals.contains(index) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(.blue)
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(Color(.systemBackground))
                            .contentShape(Rectangle())
                            .onTapGesture {
                                if selectedIntervals.contains(index) {
                                    selectedIntervals.remove(index)
                                } else {
                                    selectedIntervals.insert(index)
                                }
                            }
                            
                            if index < missedIntervals.count - 1 {
                                Divider()
                                    .padding(.leading, 20)
                            }
                        }
                    }
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal, 20)
                    
                    // Bulk action section at bottom
                    if !selectedIntervals.isEmpty {
                        VStack(spacing: 16) {
                            // Quick Tags Section
                            quickTagsSection
                            
                            TextField("What did you do during these intervals?", text: $bulkText, axis: .vertical)
                                .textInputAutocapitalization(.sentences)
                                .disableAutocorrection(false)
                                .font(.body)
                                .lineLimit(2...4)
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
    }
    
    private var quickTagsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Tags")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)
            
            if customTags.isEmpty {
                Text("No quick tags available")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 4)
            } else {
                FlowLayout(spacing: 8) {
                    ForEach(customTags, id: \.self) { tag in
                        Button(action: {
                            addTagToText(tag)
                        }) {
                            Text(tag)
                                .font(.caption.weight(.medium))
                                .foregroundStyle(.blue)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Color.blue.opacity(0.1), in: Capsule())
                        }
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
        
        for index in selectedIntervals {
            guard index < missedIntervals.count else { continue }
            let interval = missedIntervals[index]
            
            let newEntry = LogEntry(
                text: text,
                tags: [],
                timestamp: Date(),
                timePeriodStart: interval.start,
                timePeriodEnd: interval.end
            )
            
            entries.insert(newEntry, at: 0)
        }
        
        selectedIntervals.removeAll()
        bulkText = ""
    }
}

#Preview {
    let sampleIntervals = [
        (start: Date().addingTimeInterval(-3600), end: Date().addingTimeInterval(-3300)),
        (start: Date().addingTimeInterval(-3300), end: Date().addingTimeInterval(-3000))
    ]
    
    CatchUpView(entries: .constant([]), customTags: .constant(["Work", "Meeting", "Break"]), missedIntervals: sampleIntervals)
}

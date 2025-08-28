//
//  EnhancedEntryRow.swift
//  Awarely
//
//  Created by Evan Chen on 8/23/25.
//

import SwiftUI

struct EnhancedEntryRow: View {
    let entry: LogEntry
    let customTags: [String]
    var onEdit: ((LogEntry) -> Void)? = nil
    var onDelete: ((UUID) -> Void)? = nil
    @State private var isPressed = false
    @State private var isEditing = false
    @State private var draftText: String = ""
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(entry.timePeriodString)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.blue)
                
                Spacer()
                HStack(spacing: 8) {
                    if onDelete != nil {
                        Button {
                            onDelete?(entry.id)
                        } label: {
                            Image(systemName: "trash")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(.red)
                                .padding(6)
                                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                        }
                    }
                    
                    Button {
                        draftText = entry.text
                        isEditing = true
                    } label: {
                        Image(systemName: "square.and.pencil")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.secondary)
                            .padding(6)
                            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }
                }
            }
            
            Text(entry.text)
                .font(.body.weight(.medium))
                .foregroundStyle(.primary)
                .lineLimit(nil)
            
            
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 18)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(.quaternary, lineWidth: 0.5)
                )
        )
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.easeInOut(duration: 0.1)) {
                    isPressed = false
                }
            }
        }
        .sheet(isPresented: $isEditing) {
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
                            // Header Section
                            headerSection
                            
                            // Quick Tags Section
                            if !customTags.isEmpty {
                                quickTagsSection
                            }
                            
                            // Text Input Section
                            textInputSection
                            
                            Spacer(minLength: 40)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        .padding(.bottom, 100)
                    }
                }
                .navigationTitle("Edit Entry")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { 
                            isEditing = false 
                        }
                        .foregroundStyle(.secondary)
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") {
                            var updated = entry
                            updated.text = draftText.trimmingCharacters(in: .whitespacesAndNewlines)
                            onEdit?(updated)
                            isEditing = false
                        }
                        .fontWeight(.semibold)
                        .disabled(draftText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
            }
            .onAppear {
                // Focus the text field when the sheet appears
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    isTextFieldFocused = true
                }
            }
        }
    }
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Time period info
            HStack {
                Image(systemName: "clock")
                    .font(.subheadline)
                    .foregroundStyle(.blue)
                
                Text("Editing entry for: \(entry.timePeriodString)")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.blue)
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.blue.opacity(0.1))
            )
            
            // Original timestamp
            HStack {
                Image(systemName: "calendar")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Text("Originally logged at \(entry.timeString)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Spacer()
            }
        }
    }
    
    private var quickTagsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Quick Tags")
                .font(.headline.weight(.semibold))
                .foregroundStyle(.primary)
            
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
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(.quaternary, lineWidth: 0.5)
                )
        )
    }
    
    private var textInputSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("What did you do?")
                .font(.headline.weight(.semibold))
                .foregroundStyle(.primary)
            
            VStack(spacing: 12) {
                TextField("Describe your activity...", text: $draftText, axis: .vertical)
                    .textInputAutocapitalization(.sentences)
                    .disableAutocorrection(false)
                    .focused($isTextFieldFocused)
                    .submitLabel(.done)
                    .font(.body)
                    .lineLimit(3...8)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(.ultraThinMaterial)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .strokeBorder(.quaternary, lineWidth: 0.5)
                            )
                    )
                
                // Character count and save status
                HStack {
                    Text("\(draftText.count) characters")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Spacer()
                    
                    if !draftText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.caption)
                                .foregroundStyle(.green)
                            
                            Text("Ready to save")
                                .font(.caption)
                                .foregroundStyle(.green)
                        }
                    } else {
                        HStack(spacing: 4) {
                            Image(systemName: "exclamationmark.circle.fill")
                                .font(.caption)
                                .foregroundStyle(.orange)
                            
                            Text("Entry cannot be empty")
                                .font(.caption)
                                .foregroundStyle(.orange)
                        }
                    }
                }
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
    }
    
    private func addTagToText(_ tag: String) {
        let trimmed = draftText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmed.isEmpty {
            // First tag - just add it
            draftText = tag
        } else {
            // Subsequent tag - add ", [tag]"
            draftText = trimmed + ", " + tag
        }
        
        // Focus the text field and move cursor to end
        isTextFieldFocused = true
    }
}

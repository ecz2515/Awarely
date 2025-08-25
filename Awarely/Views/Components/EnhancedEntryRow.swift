//
//  EnhancedEntryRow.swift
//  Awarely
//
//  Created by Evan Chen on 8/23/25.
//

import SwiftUI

struct EnhancedEntryRow: View {
    let entry: LogEntry
    var onEdit: ((LogEntry) -> Void)? = nil
    @State private var isPressed = false
    @State private var isEditing = false
    @State private var draftText: String = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(entry.timeString)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.ultraThinMaterial, in: Capsule())
                
                Spacer()
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
                VStack(spacing: 16) {
                    TextEditor(text: $draftText)
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(Color(.systemGray6))
                        )
                        .frame(minHeight: 160)
                }
                .padding(20)
                .navigationTitle("Edit Entry")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { isEditing = false }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") {
                            var updated = entry
                            updated.text = draftText.trimmingCharacters(in: .whitespacesAndNewlines)
                            onEdit?(updated)
                            isEditing = false
                        }
                        .disabled(draftText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
            }
        }
    }
}

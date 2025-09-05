import SwiftUI

struct TagsStepView: View {
    @Binding var selectedTags: [String]
    @State private var newTag = ""
    @FocusState private var isTextFieldFocused: Bool
    @Binding var textFieldBorderFlash: Bool
    @Binding var isKeyboardVisible: Bool
    let onReturnPressed: () -> Void
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 0) {
                    Spacer(minLength: 60)
                    
                    // Header
                    VStack(spacing: 16) {
                        Image(systemName: "tag.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(.purple)
                        
                        VStack(spacing: 8) {
                            Text("Quick Tags")
                                .font(.largeTitle.weight(.bold))
                                .foregroundStyle(.primary)
                                .multilineTextAlignment(.center)
                            
                            Text("Add some common activities you do for quick access during logging")
                                .font(.title3)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .padding(.horizontal, 32)
                    .padding(.bottom, 40)
                    
                    // Tag Creation Section
                    VStack(spacing: 20) {
                        // Add new tag input
                        HStack(spacing: 12) {
                            TextField("Enter tag name...", text: $newTag)
                                .focused($isTextFieldFocused)
                                .submitLabel(.done)
                                .onSubmit {
                                    let trimmed = newTag.trimmingCharacters(in: .whitespacesAndNewlines)
                                    if !trimmed.isEmpty {
                                        addTag()
                                    } else {
                                        // Just dismiss the keyboard
                                        isTextFieldFocused = false
                                    }
                                }
                                .onChange(of: newTag) { _, newValue in
                                    // Limit to 40 characters
                                    if newValue.count > 40 {
                                        newTag = String(newValue.prefix(40))
                                    }
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(Color(.systemBackground))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                .strokeBorder(
                                                    textFieldBorderFlash ? Color.red : Color(.systemGray4), 
                                                    lineWidth: textFieldBorderFlash ? 2 : 1
                                                )
                                        )
                                )
                            
                            Button(action: addTag) {
                                Text("Add")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.white)
                                    .frame(width: 80, height: 44)
                                    .background(
                                        newTag.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                        ? Color.gray
                                        : Color.blue,
                                        in: RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    )
                            }
                            .disabled(newTag.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                            .buttonStyle(PlainButtonStyle())
                        }
                        
                        // Created tags display
                        if !selectedTags.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Your Quick Tags (\(selectedTags.count))")
                                    .font(.headline.weight(.semibold))
                                    .foregroundStyle(.primary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                
                                FlowLayout(spacing: 8) {
                                    ForEach(selectedTags, id: \.self) { tag in
                                        HStack(spacing: 6) {
                                            Text(tag)
                                                .font(.subheadline.weight(.medium))
                                                .foregroundStyle(.blue)
                                            
                                            Button(action: {
                                                removeTag(tag)
                                            }) {
                                                Image(systemName: "xmark")
                                                    .font(.caption2)
                                                    .foregroundStyle(.blue)
                                            }
                                        }
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(
                                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                                .fill(Color.blue.opacity(0.1))
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                                                        .strokeBorder(Color.blue.opacity(0.3), lineWidth: 1)
                                                )
                                        )
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                    }
                    .padding(.horizontal, 32)
                    
                    Spacer(minLength: 60)
                }
                .frame(minHeight: geometry.size.height)
            }
        }
        .onTapGesture {
            // Dismiss keyboard when tapping outside text field
            isTextFieldFocused = false
        }
        .onChange(of: isTextFieldFocused) { focused in
            isKeyboardVisible = focused
        }
    }
    
    private func addTag() {
        let trimmed = newTag.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty && !selectedTags.contains(trimmed) else { return }
        
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            selectedTags.insert(trimmed, at: 0) // Insert at the beginning
        }
        
        newTag = ""
        isTextFieldFocused = true // Keep focus for adding multiple tags
        
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
    }
    
    private func removeTag(_ tag: String) {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            selectedTags.removeAll { $0 == tag }
        }
        
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
    }
}

#Preview {
    TagsStepView(
        selectedTags: .constant(["Read", "Exercise"]),
        textFieldBorderFlash: .constant(false),
        isKeyboardVisible: .constant(false),
        onReturnPressed: {}
    )
}

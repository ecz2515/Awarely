import SwiftUI

struct TagsStepView: View {
    @Binding var selectedTags: Set<String>
    let availableTags: [String]
    
    var body: some View {
        VStack(spacing: 40) {
            // Header
            VStack(spacing: 16) {
                Image(systemName: "tag.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(.purple)
                
                VStack(spacing: 8) {
                    Text("Quick activity tags")
                        .font(.largeTitle.weight(.bold))
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.center)
                    
                    Text("Select tags for activities you want to track")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            
            // Tags Grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                ForEach(availableTags, id: \.self) { tag in
                    Button(action: {
                        if selectedTags.contains(tag) {
                            selectedTags.remove(tag)
                        } else {
                            selectedTags.insert(tag)
                        }
                    }) {
                        HStack {
                            Text(tag)
                                .font(.headline.weight(.medium))
                                .foregroundStyle(selectedTags.contains(tag) ? .white : .primary)
                            
                            Spacer()
                            
                            if selectedTags.contains(tag) {
                                Image(systemName: "checkmark")
                                    .font(.headline.weight(.semibold))
                                    .foregroundStyle(.white)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(selectedTags.contains(tag) ? Color.purple : Color(.systemGray6))
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, 20)
            
            // Info text
            VStack(spacing: 8) {
                Text("You can add more tags later")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                Text("Selected: \(selectedTags.count)")
                    .font(.caption)
                    .foregroundStyle(.blue)
            }
            
            Spacer()
        }
        .padding(.horizontal, 20)
    }
}

#Preview {
    TagsStepView(
        selectedTags: .constant(["Read", "Exercise"]),
        availableTags: ["Read", "Exercise", "Meditate", "Work", "Journal"]
    )
}

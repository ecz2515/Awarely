import SwiftUI

struct ActiveDaysStepView: View {
    @Binding var activeDaysPreset: ActiveDaysPreset
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            // Header
            VStack(spacing: 16) {
                Image(systemName: "calendar")
                    .font(.system(size: 60))
                    .foregroundStyle(.green)
                
                VStack(spacing: 8) {
                    Text("When are you active?")
                        .font(.largeTitle.weight(.bold))
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.center)
                    
                    Text("Choose when you'd like to receive reminders")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            
            // Options
            VStack(spacing: 16) {
                ForEach(ActiveDaysPreset.allCases, id: \.self) { preset in
                    Button(action: {
                        activeDaysPreset = preset
                    }) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(preset.rawValue)
                                    .font(.headline.weight(.semibold))
                                    .foregroundStyle(.primary)
                                
                                Text(preset.description)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            
                            Spacer()
                            
                            if activeDaysPreset == preset {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.title2)
                                    .foregroundStyle(.blue)
                            } else {
                                Image(systemName: "circle")
                                    .font(.title2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(activeDaysPreset == preset ? Color.blue.opacity(0.1) : Color(.systemGray6))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .stroke(activeDaysPreset == preset ? Color.blue : Color.clear, lineWidth: 2)
                                )
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, 20)
            
            Spacer()
        }
        .padding(.horizontal, 20)
    }
}

#Preview {
    ActiveDaysStepView(activeDaysPreset: .constant(.weekdays))
}

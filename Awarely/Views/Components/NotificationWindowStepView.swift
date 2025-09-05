import SwiftUI

struct NotificationWindowStepView: View {
    @Binding var startTime: Date
    @Binding var endTime: Date
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            // Header
            VStack(spacing: 16) {
                Image(systemName: "clock.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(.orange)
                
                VStack(spacing: 8) {
                    Text("Reminder window")
                        .font(.largeTitle.weight(.bold))
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.center)
                    
                    Text("When should we send you reminders?")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(.horizontal, 32)
            
            // Compact Time Pickers
            VStack(spacing: 30) {
                VStack(spacing: 12) {
                    Text("Start time")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.primary)
                    
                    DatePicker("Start time", selection: $startTime, displayedComponents: .hourAndMinute)
                        .datePickerStyle(.compact)
                        .labelsHidden()
                }
                
                VStack(spacing: 12) {
                    Text("End time")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.primary)
                    
                    DatePicker("End time", selection: $endTime, displayedComponents: .hourAndMinute)
                        .datePickerStyle(.compact)
                        .labelsHidden()
                }
            }
            .padding(.horizontal, 32)
            
            Spacer()
        }
        .onAppear {
            // Set minute interval to 30 minutes (only show :00 and :30)
            UIDatePicker.appearance().minuteInterval = 30
            
            // Round initial times to nearest half hour
            startTime = roundToNearestHalfHour(startTime)
            endTime = roundToNearestHalfHour(endTime)
            
            // Ensure end time is after start time
            if endTime <= startTime {
                let calendar = Calendar.current
                if let newEndTime = calendar.date(byAdding: .hour, value: 9, to: startTime) {
                    endTime = roundToNearestHalfHour(newEndTime)
                }
            }
        }
        .onDisappear {
            // Reset minute interval back to default
            UIDatePicker.appearance().minuteInterval = 1
        }
    }
    
    private func roundToNearestHalfHour(_ date: Date) -> Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: date)
        
        let minute = components.minute ?? 0
        let roundedMinute: Int
        
        if minute < 15 {
            roundedMinute = 0
        } else if minute < 45 {
            roundedMinute = 30
        } else {
            roundedMinute = 0
            // If we're rounding up to the next hour, we need to handle that
            let hour = components.hour ?? 0
            let newHour = (hour + 1) % 24
            return calendar.date(bySettingHour: newHour, minute: 0, second: 0, of: date) ?? date
        }
        
        return calendar.date(bySettingHour: components.hour ?? 0, minute: roundedMinute, second: 0, of: date) ?? date
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

#Preview {
    NotificationWindowStepView(
        startTime: .constant(Calendar.current.date(from: DateComponents(hour: 9, minute: 0)) ?? Date()),
        endTime: .constant(Calendar.current.date(from: DateComponents(hour: 18, minute: 0)) ?? Date())
    )
}

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
                    Text("Daily reminder window")
                        .font(.largeTitle.weight(.bold))
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.center)
                    
                    Text("When should we send you reminders?")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            
            // Time Pickers
            VStack(spacing: 24) {
                VStack(spacing: 12) {
                    Text("Start time")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.primary)
                    
                    DatePicker("", selection: $startTime, displayedComponents: .hourAndMinute)
                        .datePickerStyle(.wheel)
                        .labelsHidden()
                        .frame(maxWidth: .infinity)
                }
                
                VStack(spacing: 12) {
                    Text("End time")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.primary)
                    
                    DatePicker("", selection: $endTime, displayedComponents: .hourAndMinute)
                        .datePickerStyle(.wheel)
                        .labelsHidden()
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, 40)
            
            // Info text
            Text("We'll only send reminders during these hours")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .onAppear {
            // Ensure end time is after start time
            if endTime <= startTime {
                let calendar = Calendar.current
                if let newEndTime = calendar.date(byAdding: .hour, value: 9, to: startTime) {
                    endTime = newEndTime
                }
            }
        }
    }
}

#Preview {
    NotificationWindowStepView(
        startTime: .constant(Calendar.current.date(from: DateComponents(hour: 9, minute: 0)) ?? Date()),
        endTime: .constant(Calendar.current.date(from: DateComponents(hour: 18, minute: 0)) ?? Date())
    )
}

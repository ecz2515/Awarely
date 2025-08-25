import SwiftUI

struct TimerOverlay: View {
    @ObservedObject var intervalTimer: IntervalTimer
    
    var body: some View {
        ZStack {
            // Blurred background
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                // Timer icon
                Image(systemName: "timer")
                    .font(.system(size: 48, weight: .light))
                    .foregroundStyle(.orange)
                
                // Timer text
                VStack(spacing: 8) {
                    Text("Next check-in in")
                        .font(.title2.weight(.medium))
                        .foregroundStyle(.primary)
                    
                    Text(intervalTimer.formatTimeRemaining())
                        .font(.system(size: 48, weight: .bold, design: .monospaced))
                        .foregroundStyle(.orange)
                        .contentTransition(.numericText())
                }
                
                // Next interval time
                VStack(spacing: 4) {
                    Text("Next interval at")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    Text(intervalTimer.nextIntervalDate.formatted(date: .omitted, time: .shortened))
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.primary)
                }
                
                // Motivational message
                Text("Take a moment to reflect on what you've been working on")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            .padding(40)
        }
    }
}

#Preview {
    TimerOverlay(intervalTimer: IntervalTimer())
}

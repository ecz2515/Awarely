import SwiftUI

struct TimerOverlay: View {
    @ObservedObject var intervalTimer: IntervalTimer
    @Binding var entries: [LogEntry]
    @Binding var customTags: [String]
    @State private var showingCatchUpFlow = false
    var showTimeUntilNextIntervalEnd: Bool = false
    
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
                    Text(showTimeUntilNextIntervalEnd ? intervalTimer.formatTimeUntilNextIntervalEnd() : intervalTimer.formatTimeRemaining())
                        .font(.system(size: 48, weight: .bold, design: .monospaced))
                        .foregroundStyle(.orange)
                        .contentTransition(.numericText())
                    
                    Text("until next check-in")
                        .font(.title2.weight(.medium))
                        .foregroundStyle(.primary)
                }
                
                // Motivational message
                Text("Take a moment to reflect on what you've been working on")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                
                // Catch-up button (only show if there are missed intervals)
                if !intervalTimer.getMissedIntervals(for: entries).isEmpty {
                    Button(action: { showingCatchUpFlow = true }) {
                        HStack {
                            Image(systemName: "clock.arrow.circlepath")
                                .font(.subheadline)
                                .foregroundStyle(.orange)
                            
                            Text("Catch up on \(intervalTimer.getMissedIntervals(for: entries).count) missed intervals")
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(.orange)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(Color.orange.opacity(0.1))
                        )
                    }
                    .padding(.top, 16)
                }
            }
            .padding(40)
            .sheet(isPresented: $showingCatchUpFlow) {
                CatchUpView(entries: $entries, customTags: $customTags, missedIntervals: intervalTimer.getMissedIntervals(for: entries), intervalTimer: intervalTimer)
            }
        }
    }
}

#Preview {
    TimerOverlay(intervalTimer: IntervalTimer(), entries: .constant([]), customTags: .constant([]))
}

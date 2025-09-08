import SwiftUI

struct TimerOverlay: View {
    @ObservedObject var intervalTimer: IntervalTimer
    @Binding var entries: [LogEntry]
    @Binding var customTags: [String]
    @State private var showingCatchUpFlow = false
    @State private var showingCustomTags = false
    var showTimeUntilNextIntervalEnd: Bool = false
    
    var body: some View {
        ZStack {
            // Blurred background
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                // Check if we're in the overnight gap
                if intervalTimer.isInOvernightGap() {
                    // Overnight gap state
                    Image(systemName: "moon.zzz.fill")
                        .font(.system(size: 48, weight: .light))
                        .foregroundStyle(.blue)
                    
                    VStack(spacing: 8) {
                        Text("See you at \(intervalTimer.formatFirstCheckInTimeTomorrow())")
                            .font(.title2.weight(.bold))
                            .foregroundStyle(.primary)
                        
                        Text("Sleep well! Logging resumes tomorrow")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
                // Check if we're past the logging end time (but not in overnight gap)
                else if intervalTimer.isPastLoggingEndTime() {
                    // Done for the day state
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 48, weight: .light))
                        .foregroundStyle(.green)
                    
                    VStack(spacing: 8) {
                        Text("Done for the day!")
                            .font(.title2.weight(.bold))
                            .foregroundStyle(.primary)
                        
                        Text("Great work today! See you tomorrow")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    
                    // Catch-up button (show if there are missed intervals, even when done for the day)
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
                } else {
                    // Timer state
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
            }
            .padding(40)
            
            // Customize Tags button in top-right corner
            VStack {
                HStack {
                    Spacer()
                    Button(action: { showingCustomTags = true }) {
                        HStack(spacing: 6) {
                            Image(systemName: "tag")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            
                            Text("Quick Tags")
                                .font(.caption.weight(.medium))
                                .foregroundStyle(.secondary)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(.ultraThinMaterial)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .strokeBorder(.quaternary, lineWidth: 0.5)
                                )
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                Spacer()
            }
            .padding(.top, 20)
            .padding(.trailing, 20)
        }
        .sheet(isPresented: $showingCatchUpFlow) {
            CatchUpView(entries: $entries, customTags: $customTags, missedIntervals: intervalTimer.getMissedIntervals(for: entries), intervalTimer: intervalTimer)
        }
        .sheet(isPresented: $showingCustomTags) {
            CustomTagsView(customTags: $customTags)
        }
    }
}

#Preview {
    TimerOverlay(intervalTimer: IntervalTimer(), entries: .constant([]), customTags: .constant([]))
}

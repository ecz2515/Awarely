import Foundation
import Combine

class IntervalTimer: ObservableObject {
    @Published var timeRemaining: TimeInterval = 0
    @Published var isLoggingWindow: Bool = false
    @Published var nextIntervalDate: Date = Date()
    
    private var timer: Timer?
    private let interval: TimeInterval = 30 * 60 // 30 minutes
    
    init() {
        calculateNextInterval()
        startTimer()
    }
    
    deinit {
        timer?.invalidate()
    }
    
    private func calculateNextInterval() {
        let calendar = Calendar.current
        let now = Date()
        
        // Get the current minute
        let currentMinute = calendar.component(.minute, from: now)
        
        // Calculate minutes until next half-hour (00 or 30)
        let minutesUntilNext: Int
        if currentMinute < 30 {
            minutesUntilNext = 30 - currentMinute
        } else {
            minutesUntilNext = 60 - currentMinute
        }
        
        // Calculate next interval date
        nextIntervalDate = calendar.date(byAdding: .minute, value: minutesUntilNext, to: now) ?? now
        
        // Set seconds to 0 for clean intervals
        nextIntervalDate = calendar.date(bySetting: .second, value: 0, of: nextIntervalDate) ?? nextIntervalDate
        
        // Schedule notification for the next interval
        NotificationManager.shared.scheduleLoggingReminder(at: nextIntervalDate)
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateTimer()
        }
    }
    
    private func updateTimer() {
        let now = Date()
        timeRemaining = nextIntervalDate.timeIntervalSince(now)
        
        // Check if we're in the logging window (last 5 minutes of the interval)
        let loggingWindowDuration: TimeInterval = 5 * 60 // 5 minutes
        isLoggingWindow = timeRemaining <= loggingWindowDuration
        
        // If time is up, calculate next interval
        if timeRemaining <= 0 {
            calculateNextInterval()
        }
    }
    
    func formatTimeRemaining() -> String {
        let minutes = Int(timeRemaining) / 60
        let seconds = Int(timeRemaining) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    func getTimeUntilNextInterval() -> TimeInterval {
        return timeRemaining
    }
    
    func isInLoggingWindow() -> Bool {
        return isLoggingWindow
    }
}

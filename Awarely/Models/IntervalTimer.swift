import Foundation
import Combine

class IntervalTimer: ObservableObject {
    @Published var timeRemaining: TimeInterval = 0
    @Published var isLoggingWindow: Bool = false
    @Published var isLateGracePeriod: Bool = false
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
        
        // Calculate the next interval start minute (00 or 30)
        let nextIntervalMinute: Int
        if currentMinute < 30 {
            nextIntervalMinute = 30
        } else {
            nextIntervalMinute = 0
            // If we're past 30, we need to go to the next hour
        }
        
        // Create the next interval date
        var components = calendar.dateComponents([.year, .month, .day, .hour], from: now)
        
        // If we're going to the next hour (past 30 minutes)
        if currentMinute >= 30 {
            components.hour = (components.hour ?? 0) + 1
        }
        
        components.minute = nextIntervalMinute
        components.second = 0
        
        nextIntervalDate = calendar.date(from: components) ?? now
        
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
        
        // Get configured grace period from UserDefaults
        let gracePeriodMinutes = UserDefaults.standard.integer(forKey: "loggingGracePeriod")
        let gracePeriod = gracePeriodMinutes > 0 ? gracePeriodMinutes : 5 // Default to 5 minutes
        let lateGracePeriod: TimeInterval = 5 * 60 // 5 minutes late grace period
        
        // Check if we're in early grace period (before interval ends)
        let isInEarlyGrace = timeRemaining <= TimeInterval(gracePeriod * 60) && timeRemaining > 0
        
        // Check if we're in late grace period (after previous interval ends)
        let previousIntervalEnd = getPreviousIntervalEnd()
        let timeSincePreviousIntervalEnd = now.timeIntervalSince(previousIntervalEnd)
        let isInLateGrace = timeSincePreviousIntervalEnd <= lateGracePeriod && timeSincePreviousIntervalEnd > 0
        
        // Update logging window state
        isLoggingWindow = isInEarlyGrace || isInLateGrace
        isLateGracePeriod = isInLateGrace
        
        // If time is up, calculate next interval
        if timeRemaining <= 0 {
            calculateNextInterval()
        }
    }
    
    // MARK: - Entry-based State Updates
    
    func updateTimerState(with entries: [LogEntry]) {
        let now = Date()
        timeRemaining = nextIntervalDate.timeIntervalSince(now)
        
        // Get configured grace period from UserDefaults
        let gracePeriodMinutes = UserDefaults.standard.integer(forKey: "loggingGracePeriod")
        let gracePeriod = gracePeriodMinutes > 0 ? gracePeriodMinutes : 5 // Default to 5 minutes
        let lateGracePeriod: TimeInterval = 5 * 60 // 5 minutes late grace period
        
        // Check if we're in early grace period (before interval ends)
        let isInEarlyGrace = timeRemaining <= TimeInterval(gracePeriod * 60) && timeRemaining > 0
        
        // Check if we're in late grace period (after previous interval ends)
        let previousIntervalEnd = getPreviousIntervalEnd()
        let timeSincePreviousIntervalEnd = now.timeIntervalSince(previousIntervalEnd)
        let isInLateGraceTime = timeSincePreviousIntervalEnd <= lateGracePeriod && timeSincePreviousIntervalEnd > 0
        
        // Check if there's already an entry for the previous interval
        let hasPreviousIntervalEntry = hasEntryForPreviousInterval(entries: entries)
        
        // Only show late grace period if we're in the time window AND there's no entry for the previous interval
        let isInLateGrace = isInLateGraceTime && !hasPreviousIntervalEntry
        
        // Update logging window state
        isLoggingWindow = isInEarlyGrace || isInLateGrace
        isLateGracePeriod = isInLateGrace
        
        // If time is up, calculate next interval
        if timeRemaining <= 0 {
            calculateNextInterval()
        }
    }
    
    private func hasEntryForPreviousInterval(entries: [LogEntry]) -> Bool {
        let previousIntervalStart = getPreviousIntervalStart()
        let previousIntervalEnd = getPreviousIntervalEnd()
        
        return entries.contains { entry in
            let entryStart = entry.timePeriodStart
            let entryEnd = entry.timePeriodEnd
            return abs(entryStart.timeIntervalSince(previousIntervalStart)) < 60 && 
                   abs(entryEnd.timeIntervalSince(previousIntervalEnd)) < 60
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
    
    // MARK: - Interval Information
    
    func getCurrentIntervalStart() -> Date {
        let calendar = Calendar.current
        let now = Date()
        
        // Get the current minute
        let currentMinute = calendar.component(.minute, from: now)
        
        // Calculate the start of the current interval
        let intervalStartMinute: Int
        if currentMinute < 30 {
            intervalStartMinute = 0
        } else {
            intervalStartMinute = 30
        }
        
        // Create the interval start date
        var components = calendar.dateComponents([.year, .month, .day, .hour], from: now)
        components.minute = intervalStartMinute
        components.second = 0
        
        return calendar.date(from: components) ?? now
    }
    
    func getCurrentIntervalEnd() -> Date {
        let intervalStart = getCurrentIntervalStart()
        return intervalStart.addingTimeInterval(interval)
    }
    
    func getPreviousIntervalStart() -> Date {
        let currentStart = getCurrentIntervalStart()
        return currentStart.addingTimeInterval(-interval)
    }
    
    func getPreviousIntervalEnd() -> Date {
        return getCurrentIntervalStart()
    }
    
    func getIntervalString(for startDate: Date, endDate: Date) -> String {
        let startTime = startDate.formatted(date: .omitted, time: .shortened)
        let endTime = endDate.formatted(date: .omitted, time: .shortened)
        return "\(startTime) - \(endTime)"
    }
    
    // MARK: - Missed Intervals Utility
    
    func getMissedIntervals(for entries: [LogEntry]) -> [(start: Date, end: Date)] {
        let reminderInterval = UserDefaults.standard.double(forKey: "reminderInterval")
        let intervalMinutes = reminderInterval > 0 ? Int(reminderInterval / 60) : 30
        let intervalDuration: TimeInterval = TimeInterval(intervalMinutes * 60)
        
        let now = Date()
        
        // Get notification start time from UserDefaults, default to 9 AM today if not set
        let defaults = UserDefaults.standard
        let notificationStartTime: Date
        if let savedStartTime = defaults.object(forKey: "notificationStartTime") as? Date {
            // Use the saved start time, but if it's from a previous day, use today's start time
            let calendar = Calendar.current
            let today = calendar.startOfDay(for: now)
            let savedStartComponents = calendar.dateComponents([.hour, .minute], from: savedStartTime)
            notificationStartTime = calendar.date(bySettingHour: savedStartComponents.hour ?? 9, 
                                                minute: savedStartComponents.minute ?? 0, 
                                                second: 0, 
                                                of: today) ?? now
        } else {
            // Default to 9 AM today
            let calendar = Calendar.current
            let today = calendar.startOfDay(for: now)
            notificationStartTime = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: today) ?? now
        }
        
        var missedIntervals: [(start: Date, end: Date)] = []
        
        // Start from the notification start time and check each interval until now
        var currentIntervalStart = notificationStartTime
        
        while currentIntervalStart < now {
            let intervalEnd = currentIntervalStart.addingTimeInterval(intervalDuration)
            
            // Skip if this interval is in the future
            if intervalEnd > now {
                break
            }
            
            // Check if we have an entry for this interval
            let hasEntry = entries.contains { entry in
                let entryStart = entry.timePeriodStart
                let entryEnd = entry.timePeriodEnd
                return abs(entryStart.timeIntervalSince(currentIntervalStart)) < 60 && 
                       abs(entryEnd.timeIntervalSince(intervalEnd)) < 60
            }
            
            if !hasEntry {
                missedIntervals.append((start: currentIntervalStart, end: intervalEnd))
            }
            
            // Move to next interval
            currentIntervalStart = intervalEnd
        }
        
        return missedIntervals
    }
    


    private func getCurrentLoggingInterval() -> (start: Date, end: Date, isLateGrace: Bool) {
        let now = Date()
        let calendar = Calendar.current
        let reminderInterval = UserDefaults.standard.double(forKey: "reminderInterval")
        let intervalMinutes = reminderInterval > 0 ? Int(reminderInterval / 60) : 30
        let intervalDuration: TimeInterval = TimeInterval(intervalMinutes * 60)
        
        // Calculate interval boundaries
        let currentMinute = calendar.component(.minute, from: now)
        let intervalStartMinute: Int
        if currentMinute < intervalMinutes {
            intervalStartMinute = 0
        } else {
            intervalStartMinute = intervalMinutes
        }
        
        var components = calendar.dateComponents([.year, .month, .day, .hour], from: now)
        components.minute = intervalStartMinute
        components.second = 0
        
        let currentIntervalStart = calendar.date(from: components) ?? now
        let currentIntervalEnd = currentIntervalStart.addingTimeInterval(intervalDuration)
        let previousIntervalStart = currentIntervalStart.addingTimeInterval(-intervalDuration)
        let previousIntervalEnd = currentIntervalStart
        
        // Use IntervalTimer's state to determine if we're in late grace period
        if isLateGracePeriod {
            // Late grace: log for previous interval
            return (start: previousIntervalStart, end: previousIntervalEnd, isLateGrace: true)
        } else {
            // Normal case: log for current interval
            return (start: currentIntervalStart, end: currentIntervalEnd, isLateGrace: false)
        }
    }
}

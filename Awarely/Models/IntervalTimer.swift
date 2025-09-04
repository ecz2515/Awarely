import Foundation
import Combine

class IntervalTimer: ObservableObject {
    @Published var timeRemaining: TimeInterval = 0
    @Published var isLoggingWindow: Bool = false
    @Published var isLateGracePeriod: Bool = false
    @Published var nextIntervalDate: Date = Date()
    @Published var nextIntervalEndDate: Date = Date()
    
    private var timer: Timer?
    private let interval: TimeInterval = 30 * 60 // 30 minutes
    private var entries: [LogEntry] = []
    
    init() {
        calculateNextInterval()
        startTimer()
    }
    
    deinit {
        timer?.invalidate()
    }
    
    // MARK: - Entries Management
    
    func setEntries(_ entries: [LogEntry]) {
        self.entries = entries
        updateTimerState()
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
        nextIntervalEndDate = nextIntervalDate.addingTimeInterval(interval)
        
        // Only schedule notification if it's within the notification time window
        if isWithinNotificationTimeWindow(nextIntervalDate) {
            NotificationManager.shared.scheduleLoggingReminder(at: nextIntervalDate)
        }
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateTimerState()
        }
    }
    
    private func updateTimerState() {
        let now = Date()
        timeRemaining = nextIntervalDate.timeIntervalSince(now)
        
        // Get configured grace period from Core Data
        let gracePeriodMinutes = CoreDataManager.shared.getUserProfile()?.loggingGracePeriod ?? 5
        let gracePeriod = Int(gracePeriodMinutes)
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
    
    // MARK: - Entry-based State Updates (Legacy method for backward compatibility)
    
    func updateTimerState(with entries: [LogEntry]) {
        self.entries = entries
        updateTimerState()
    }
    
    func hasEntryForPreviousInterval(entries: [LogEntry]) -> Bool {
        let previousIntervalStart = getPreviousIntervalStart()
        let previousIntervalEnd = getPreviousIntervalEnd()
        
        return entries.contains { entry in
            let entryStart = entry.timePeriodStart
            let entryEnd = entry.timePeriodEnd
            return abs(entryStart.timeIntervalSince(previousIntervalStart)) < 60 && 
                   abs(entryEnd.timeIntervalSince(previousIntervalEnd)) < 60
        }
    }
    
    func hasEntryForCurrentInterval(entries: [LogEntry]) -> Bool {
        let currentIntervalStart = getCurrentIntervalStart()
        let currentIntervalEnd = getCurrentIntervalEnd()
        
        return entries.contains { entry in
            let entryStart = entry.timePeriodStart
            let entryEnd = entry.timePeriodEnd
            return abs(entryStart.timeIntervalSince(currentIntervalStart)) < 60 && 
                   abs(entryEnd.timeIntervalSince(currentIntervalEnd)) < 60
        }
    }
    
    func formatTimeRemaining() -> String {
        let minutes = Int(timeRemaining) / 60
        let seconds = Int(timeRemaining) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    func formatTimeUntilNextIntervalEnd() -> String {
        let timeUntilEnd = getTimeUntilNextIntervalEnd()
        let minutes = Int(timeUntilEnd) / 60
        let seconds = Int(timeUntilEnd) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    func getTimeUntilNextInterval() -> TimeInterval {
        return timeRemaining
    }
    
    func getTimeUntilNextIntervalEnd() -> TimeInterval {
        return nextIntervalEndDate.timeIntervalSince(Date())
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
    
    // MARK: - Notification Time Window
    
    private func isWithinNotificationTimeWindow(_ date: Date) -> Bool {
        let calendar = Calendar.current
        let userProfile = CoreDataManager.shared.getUserProfile()
        
        // Get notification start time
        let notificationStartTime: Date
        if let savedStartTime = userProfile?.notificationStartTime {
            // Use the saved start time, but if it's from a previous day, use today's start time
            let today = calendar.startOfDay(for: date)
            let savedStartComponents = calendar.dateComponents([.hour, .minute], from: savedStartTime)
            notificationStartTime = calendar.date(bySettingHour: savedStartComponents.hour ?? 9, 
                                                minute: savedStartComponents.minute ?? 0, 
                                                second: 0, 
                                                of: today) ?? date
        } else {
            // Default to 9 AM today
            let today = calendar.startOfDay(for: date)
            notificationStartTime = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: today) ?? date
        }
        
        // Get notification end time
        let notificationEndTime: Date
        if let savedEndTime = userProfile?.notificationEndTime {
            // Use the saved end time, but if it's from a previous day, use today's end time
            let today = calendar.startOfDay(for: date)
            let savedEndComponents = calendar.dateComponents([.hour, .minute], from: savedEndTime)
            notificationEndTime = calendar.date(bySettingHour: savedEndComponents.hour ?? 18, 
                                              minute: savedEndComponents.minute ?? 0, 
                                              second: 0, 
                                              of: today) ?? date
        } else {
            // Default to 6 PM today
            let today = calendar.startOfDay(for: date)
            notificationEndTime = calendar.date(bySettingHour: 18, minute: 0, second: 0, of: today) ?? date
        }
        
        // Check if the date is within the notification time window
        return date >= notificationStartTime && date <= notificationEndTime
    }
    
    // MARK: - Missed Intervals Utility
    
    func getMissedIntervals(for entries: [LogEntry]) -> [(start: Date, end: Date)] {
        let userProfile = CoreDataManager.shared.getUserProfile()
        let reminderInterval = userProfile?.reminderInterval ?? 30 * 60
        let intervalMinutes = Int(reminderInterval / 60)
        let intervalDuration: TimeInterval = TimeInterval(intervalMinutes * 60)
        
        let now = Date()
        
        // Get notification start time from Core Data, default to 9 AM today if not set
        let calendar = Calendar.current
        let notificationStartTime: Date
        if let savedStartTime = userProfile?.notificationStartTime {
            // Use the saved start time, but if it's from a previous day, use today's start time
            let today = calendar.startOfDay(for: now)
            let savedStartComponents = calendar.dateComponents([.hour, .minute], from: savedStartTime)
            notificationStartTime = calendar.date(bySettingHour: savedStartComponents.hour ?? 9, 
                                                minute: savedStartComponents.minute ?? 0, 
                                                second: 0, 
                                                of: today) ?? now
        } else {
            // Default to 9 AM today
            let today = calendar.startOfDay(for: now)
            notificationStartTime = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: today) ?? now
        }
        
        var missedIntervals: [(start: Date, end: Date)] = []
        
        // Get notification end time
        let notificationEndTime: Date
        if let savedEndTime = userProfile?.notificationEndTime {
            // Use the saved end time, but if it's from a previous day, use today's end time
            let today = calendar.startOfDay(for: now)
            let savedEndComponents = calendar.dateComponents([.hour, .minute], from: savedEndTime)
            notificationEndTime = calendar.date(bySettingHour: savedEndComponents.hour ?? 18, 
                                              minute: savedEndComponents.minute ?? 0, 
                                              second: 0, 
                                              of: today) ?? now
        } else {
            // Default to 6 PM today
            let today = calendar.startOfDay(for: now)
            notificationEndTime = calendar.date(bySettingHour: 18, minute: 0, second: 0, of: today) ?? now
        }
        
        // Start from the notification start time and check each interval until the end time or now (whichever is earlier)
        var currentIntervalStart = notificationStartTime
        let endTime = min(notificationEndTime, now)
        
        while currentIntervalStart < endTime {
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
    
    // MARK: - End of Day Logic
    
    func isPastLoggingEndTime() -> Bool {
        let calendar = Calendar.current
        let now = Date()
        let userProfile = CoreDataManager.shared.getUserProfile()
        
        // Get notification end time
        let notificationEndTime: Date
        if let savedEndTime = userProfile?.notificationEndTime {
            // Use the saved end time, but if it's from a previous day, use today's end time
            let today = calendar.startOfDay(for: now)
            let savedEndComponents = calendar.dateComponents([.hour, .minute], from: savedEndTime)
            notificationEndTime = calendar.date(bySettingHour: savedEndComponents.hour ?? 18, 
                                              minute: savedEndComponents.minute ?? 0, 
                                              second: 0, 
                                              of: today) ?? now
        } else {
            // Default to 6 PM today
            let today = calendar.startOfDay(for: now)
            notificationEndTime = calendar.date(bySettingHour: 18, minute: 0, second: 0, of: today) ?? now
        }
        
        return now > notificationEndTime
    }
    
    func getTimeUntilTomorrowStart() -> TimeInterval {
        let calendar = Calendar.current
        let now = Date()
        let userProfile = CoreDataManager.shared.getUserProfile()
        
        // Get tomorrow's start time
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: now) ?? now
        let tomorrowStart = calendar.startOfDay(for: tomorrow)
        
        // Get notification start time
        let notificationStartTime: Date
        if let savedStartTime = userProfile?.notificationStartTime {
            // Use the saved start time, but for tomorrow
            let savedStartComponents = calendar.dateComponents([.hour, .minute], from: savedStartTime)
            notificationStartTime = calendar.date(bySettingHour: savedStartComponents.hour ?? 9, 
                                                minute: savedStartComponents.minute ?? 0, 
                                                second: 0, 
                                                of: tomorrowStart) ?? tomorrowStart
        } else {
            // Default to 9 AM tomorrow
            notificationStartTime = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: tomorrowStart) ?? tomorrowStart
        }
        
        return notificationStartTime.timeIntervalSince(now)
    }
    
    func formatTimeUntilTomorrowStart() -> String {
        let timeUntilStart = getTimeUntilTomorrowStart()
        let hours = Int(timeUntilStart) / 3600
        let minutes = Int(timeUntilStart) % 3600 / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

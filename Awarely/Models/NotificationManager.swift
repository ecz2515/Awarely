import Foundation
import UserNotifications

class NotificationManager: ObservableObject {
    static let shared = NotificationManager()
    
    private init() {}
    
    // MARK: - Notification Messages
    
    private let notificationMessages = [
        "Time to Log Your Activity",
        "Quick check-in time!",
        "It's time to log your progress",
        "Let's capture this moment",
        "Time to check in with yourself",
        "Reflect on your work",
        "Time to log your thoughts",
        "Check-in reminder",
        "Logging time!",
        "Reflection moment",
        "Activity check-in",
        "Progress update time",
        "Mindful moment",
        "Daily check-in",
        "Activity log time"
    ]
    
    private let notificationBodies = [
        "What have you been working on?",
        "How's it going?",
        "What's your focus?",
        "How productive are you?",
        "What's been on your mind?",
        "How do you feel?",
        "What's your main activity?",
        "How's your energy?",
        "What have you accomplished?",
        "What's your highlight?",
        "How would you describe this time?",
        "What's been important?",
        "What's your current task?",
        "How's your progress?",
        "What's been your focus?"
    ]
    
    // MARK: - Day Started Notification Messages
    
    private let dayStartedMessages = [
        "Good morning! Your logging day begins now",
        "Good morning! Logging day starts now",
        "Your logging day has begun",
        "Good morning! Ready to start logging",
        "Logging day begins now",
        "Good morning! Time to start logging",
        "Your day of logging begins now",
        "Good morning! Logging starts now",
        "Logging day begins",
        "Good morning! Ready to log"
    ]
    
    private let dayStartedBodies = [
        "First check-in in 30 minutes",
        "We'll check in with you in 30 minutes",
        "First reminder in 30 minutes",
        "Check-in reminders start in 30 minutes",
        "First logging reminder in 30 minutes",
        "We'll remind you to log in 30 minutes",
        "First check-in reminder in 30 minutes",
        "Logging reminders begin in 30 minutes",
        "First reminder in 30 minutes",
        "Check-in starts in 30 minutes"
    ]
    
    private func getRandomNotificationSound() -> UNNotificationSound {
        let sounds = [
            UNNotificationSound.default,
            UNNotificationSound.defaultCritical,
            UNNotificationSound(named: UNNotificationSoundName("Tink")),
            UNNotificationSound(named: UNNotificationSoundName("Chime")),
            UNNotificationSound(named: UNNotificationSoundName("Glass"))
        ]
        
        let randomIndex = Int.random(in: 0..<sounds.count)
        return sounds[randomIndex] ?? UNNotificationSound.default
    }
    
    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Notification permission error: \(error)")
                }
            }
        }
    }
    
    func checkNotificationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                // Only log if there's an issue
                if settings.authorizationStatus != .authorized {
                    print("Notification authorization status: \(settings.authorizationStatus.rawValue)")
                }
            }
        }
        
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            DispatchQueue.main.async {
                // Only log if there are no pending notifications when there should be some
                if requests.isEmpty {
                    print("No pending notifications scheduled")
                }
            }
        }
    }
    
    func debugNotificationTimes() {
        let userProfile = CoreDataManager.shared.getUserProfile()
        
        if userProfile?.notificationStartTime == nil || userProfile?.notificationEndTime == nil {
            print("Notification times not set - notifications will not be scheduled")
        }
    }
    
    func debugScheduledNotifications() {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            DispatchQueue.main.async {
                if requests.isEmpty {
                    print("No notifications scheduled")
                }
            }
        }
    }
    
    func debugNotificationScheduling() {
        debugNotificationTimes()
        debugScheduledNotifications()
    }
    
    func getNotificationAuthorizationStatus(completion: @escaping (UNAuthorizationStatus) -> Void) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                completion(settings.authorizationStatus)
            }
        }
    }
    
    func isNotificationPermissionGranted(completion: @escaping (Bool) -> Void) {
        getNotificationAuthorizationStatus { status in
            completion(status == .authorized)
        }
    }
    
    func scheduleLoggingReminder(at date: Date) {
        // Check if notifications are enabled in user settings
        let userProfile = CoreDataManager.shared.getUserProfile()
        if let profile = userProfile, !profile.notificationEnabled {
            return
        }
        
        // Check if the notification is within the allowed time window
        if !isWithinNotificationTimeWindow(date) {
            return
        }
        
        let content = UNMutableNotificationContent()
        content.title = notificationMessages.randomElement() ?? "Time to Log Your Activity"
        content.body = notificationBodies.randomElement() ?? "Take a moment to reflect on what you've been working on for the past 30 minutes."
        content.sound = getRandomNotificationSound()
        content.categoryIdentifier = "LOGGING_REMINDER"
        content.threadIdentifier = "awarely-logging"
        
        // Create trigger for the specific date
        let dateComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: dateComponents,
            repeats: false
        )
        
        // Create request
        let identifier = "logging-reminder-\(date.timeIntervalSince1970)"
        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )
        
        // Schedule notification
        UNUserNotificationCenter.current().add(request) { error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Error scheduling notification: \(error)")
                }
            }
        }
    }
    
    func scheduleDayStartedNotification(at date: Date) {
        // Check if notifications are enabled in user settings
        let userProfile = CoreDataManager.shared.getUserProfile()
        if let profile = userProfile, !profile.notificationEnabled {
            return
        }
        
        let content = UNMutableNotificationContent()
        content.title = dayStartedMessages.randomElement() ?? "Good morning! Your logging day begins now"
        content.body = dayStartedBodies.randomElement() ?? "Take a moment to set your intentions for today"
        content.sound = UNNotificationSound.default // Use default sound for gentler morning notification
        content.categoryIdentifier = "DAY_STARTED"
        content.threadIdentifier = "awarely-day-started"
        
        // Create trigger for the specific date
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date),
            repeats: false
        )
        
        // Create request
        let request = UNNotificationRequest(
            identifier: "day-started-\(date.timeIntervalSince1970)",
            content: content,
            trigger: trigger
        )
        
        // Schedule notification
        UNUserNotificationCenter.current().add(request) { error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Error scheduling day started notification: \(error)")
                }
            }
        }
    }
    
    func cancelAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
    
    func dismissAllDeliveredNotifications() {
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
    }
    
    func cancelNotification(for date: Date) {
        let identifier = "logging-reminder-\(date.timeIntervalSince1970)"
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
    }
    
    // MARK: - Enhanced Scheduling for Background Fetch
    
    func scheduleNotificationsForNextHours(hours: Int) {
        // For background fetch, schedule for the next 3 days to ensure day boundary coverage
        // This ensures notifications work even if background fetch is unreliable
        scheduleNotificationsForNextDays(days: 3)
    }
    
    func scheduleNotificationsForToday() {
        // Schedule notifications for the next 3 days to ensure continuous coverage
        scheduleNotificationsForNextDays(days: 3)
    }
    
    func scheduleNotificationsForNextDays(days: Int = 7) {
        let calendar = Calendar.current
        let now = Date()
        
        let userProfile = CoreDataManager.shared.getUserProfile()
        
        // Check if notification times are set - if not, don't schedule anything
        guard let savedStartTime = userProfile?.notificationStartTime,
              let savedEndTime = userProfile?.notificationEndTime else {
            print("📅 No notification times set - skipping scheduling")
            return
        }
        
        let startComponents = calendar.dateComponents([.hour, .minute], from: savedStartTime)
        let endComponents = calendar.dateComponents([.hour, .minute], from: savedEndTime)
        
        // iOS keeps up to 64 pending notifications. Leave headroom for system use; cap at 60.
        let maxPendingToSchedule = 60
        
        // Collect all candidate triggers first
        enum CandidateType { case dayStarted, logging }
        struct Candidate {
            let date: Date
            let type: CandidateType
        }
        var candidates: [Candidate] = []
        
        for dayOffset in 0..<days {
            guard let futureDate = calendar.date(byAdding: .day, value: dayOffset, to: now) else {
                continue
            }
            
            let targetDay = calendar.startOfDay(for: futureDate)
            
            guard let startTime = calendar.date(bySettingHour: startComponents.hour ?? 0,
                                               minute: startComponents.minute ?? 0,
                                               second: 0,
                                               of: targetDay) else {
                continue
            }
            
            // Compute end time (may roll to next day if before start)
            let endTime: Date
            if let tempEndTime = calendar.date(bySettingHour: endComponents.hour ?? 0,
                                             minute: endComponents.minute ?? 0,
                                             second: 0,
                                             of: targetDay) {
                if tempEndTime <= startTime {
                    guard let nextDayEndTime = calendar.date(byAdding: .day, value: 1, to: tempEndTime) else { continue }
                    endTime = nextDayEndTime
                } else {
                    endTime = tempEndTime
                }
            } else {
                continue
            }
            
            if startTime > now {
                candidates.append(Candidate(date: startTime, type: .dayStarted))
            }
            
            // Generate 30-min logging reminders
            var currentInterval = startTime.addingTimeInterval(30 * 60)
            let intervalDuration: TimeInterval = 30 * 60
            while currentInterval <= endTime {
                if currentInterval > now {
                    candidates.append(Candidate(date: currentInterval, type: .logging))
                }
                currentInterval = currentInterval.addingTimeInterval(intervalDuration)
            }
        }
        
        // Sort and cap
        candidates.sort { $0.date < $1.date }
        print("📅 Generated \(candidates.count) candidate notifications over next \(days) days")
        if candidates.count > maxPendingToSchedule {
            print("📅 Capping to \(maxPendingToSchedule) earliest notifications")
        }
        let limited = candidates.prefix(maxPendingToSchedule)
        
        // Schedule
        var dayStartedScheduled = 0
        var totalLoggingScheduled = 0
        for candidate in limited {
            switch candidate.type {
            case .dayStarted:
                scheduleDayStartedNotification(at: candidate.date)
                dayStartedScheduled += 1
            case .logging:
                scheduleLoggingReminder(at: candidate.date)
                totalLoggingScheduled += 1
            }
        }
        
        if let firstDate = limited.first?.date, let lastDate = limited.last?.date {
            print("📅 Scheduling window: \(firstDate) → \(lastDate)")
        }
        print("📅 Scheduled \(dayStartedScheduled) day-started + \(totalLoggingScheduled) logging notifications (cap \(maxPendingToSchedule)) over next \(days) days")
    }
    
    // MARK: - Settings Change Handling
    
    func rescheduleNotificationsForSettingsChange() {
        print("🔧 Settings change detected - rescheduling notifications")
        
        // Log the new settings
        let userProfile = CoreDataManager.shared.getUserProfile()
        if let startTime = userProfile?.notificationStartTime,
           let endTime = userProfile?.notificationEndTime {
            let calendar = Calendar.current
            let startComponents = calendar.dateComponents([.hour, .minute], from: startTime)
            let endComponents = calendar.dateComponents([.hour, .minute], from: endTime)
            print("🔧 New times: \(startComponents.hour ?? 0):\(String(format: "%02d", startComponents.minute ?? 0)) - \(endComponents.hour ?? 0):\(String(format: "%02d", endComponents.minute ?? 0))")
        }
        
        // Cancel all existing notifications
        cancelAllNotifications()
        
        // Reschedule with new settings for the next 3 days
        scheduleNotificationsForNextDays(days: 3)
    }
    

    // MARK: - Logging Grace Period Validation
    
    func isWithinLoggingGracePeriod(for targetTime: Date) -> Bool {
        let defaults = UserDefaults.standard
        let gracePeriodMinutes = defaults.integer(forKey: "loggingGracePeriod")
        let gracePeriod = gracePeriodMinutes > 0 ? gracePeriodMinutes : 5 // Default to 5 minutes
        
        let now = Date()
        let timeDifference = now.timeIntervalSince(targetTime)
        let gracePeriodSeconds = TimeInterval(gracePeriod * 60)
        
        // Allow logging if the target time is within the grace period before now
        return timeDifference >= 0 && timeDifference <= gracePeriodSeconds
    }
    
    func getLoggingGracePeriod() -> Int {
        let defaults = UserDefaults.standard
        let gracePeriod = defaults.integer(forKey: "loggingGracePeriod")
        return gracePeriod > 0 ? gracePeriod : 5 // Default to 5 minutes
    }
    
    // MARK: - Notification Time Window
    
    private func isWithinNotificationTimeWindow(_ date: Date) -> Bool {
        let calendar = Calendar.current
        let userProfile = CoreDataManager.shared.getUserProfile()
        
        // Check if notification times are set - if not, return false
        guard let savedStartTime = userProfile?.notificationStartTime,
              let savedEndTime = userProfile?.notificationEndTime else {
            return false
        }
        
        // For cross-day scenarios, we need to check if the date falls within ANY day's notification window
        // Let's check both the current day and the previous day's window
        
        let savedStartComponents = calendar.dateComponents([.hour, .minute], from: savedStartTime)
        let savedEndComponents = calendar.dateComponents([.hour, .minute], from: savedEndTime)
        
        // Check current day's window
        let today = calendar.startOfDay(for: date)
        if let notificationStartTime = calendar.date(bySettingHour: savedStartComponents.hour ?? 0, 
                                                   minute: savedStartComponents.minute ?? 0, 
                                                   second: 0, 
                                                   of: today) {
            
            // Handle end time - if it's earlier than start time, it should be the next day
            let notificationEndTime: Date
            if let tempEndTime = calendar.date(bySettingHour: savedEndComponents.hour ?? 0, 
                                            minute: savedEndComponents.minute ?? 0, 
                                            second: 0, 
                                            of: today) {
                // If end time is earlier than start time, it's the next day
                if tempEndTime <= notificationStartTime {
                    if let nextDayEndTime = calendar.date(byAdding: .day, value: 1, to: tempEndTime) {
                        notificationEndTime = nextDayEndTime
                    } else {
                        return false
                    }
                } else {
                    notificationEndTime = tempEndTime
                }
            } else {
                return false
            }
            
            // Check if the date is within the current day's notification time window
            let isWithinCurrentDay = date >= notificationStartTime && date <= notificationEndTime
            
            if isWithinCurrentDay {
                return true
            }
        }
        
        // Check previous day's window (for cross-day scenarios)
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today) ?? today
        if let prevDayStartTime = calendar.date(bySettingHour: savedStartComponents.hour ?? 0, 
                                              minute: savedStartComponents.minute ?? 0, 
                                              second: 0, 
                                              of: yesterday) {
            
            // Handle end time - if it's earlier than start time, it should be the next day (which is today)
            let prevDayEndTime: Date
            if let tempEndTime = calendar.date(bySettingHour: savedEndComponents.hour ?? 0, 
                                            minute: savedEndComponents.minute ?? 0, 
                                            second: 0, 
                                            of: yesterday) {
                // If end time is earlier than start time, it's the next day (today)
                if tempEndTime <= prevDayStartTime {
                    if let nextDayEndTime = calendar.date(byAdding: .day, value: 1, to: tempEndTime) {
                        prevDayEndTime = nextDayEndTime
                    } else {
                        return false
                    }
                } else {
                    prevDayEndTime = tempEndTime
                }
            } else {
                return false
            }
            
            // Check if the date is within the previous day's notification time window
            let isWithinPrevDay = date >= prevDayStartTime && date <= prevDayEndTime
            
            if isWithinPrevDay {
                return true
            }
        }
        
        return false
    }
}

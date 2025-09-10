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
                if granted {
                    print("✅ Notification permission granted")
                } else if let error = error {
                    print("❌ Notification permission error: \(error)")
                } else {
                    print("❌ Notification permission denied by user")
                }
            }
        }
    }
    
    func checkNotificationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                print("📱 Notification Settings:")
                print("   Authorization Status: \(settings.authorizationStatus.rawValue)")
                print("   Alert Setting: \(settings.alertSetting.rawValue)")
                print("   Badge Setting: \(settings.badgeSetting.rawValue)")
                print("   Sound Setting: \(settings.soundSetting.rawValue)")
            }
        }
        
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            DispatchQueue.main.async {
                print("📅 Pending Notifications: \(requests.count)")
                for request in requests {
                    if let trigger = request.trigger as? UNCalendarNotificationTrigger {
                        print("   - \(request.identifier): \(trigger.nextTriggerDate() ?? Date())")
                    }
                }
            }
        }
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
        print("🔔 Attempting to schedule logging reminder for \(date)")
        
        // Check if notifications are enabled in user settings
        let userProfile = CoreDataManager.shared.getUserProfile()
        if let profile = userProfile, !profile.notificationEnabled {
            print("⚠️ Notification not scheduled for \(date) - notifications disabled in settings")
            return
        }
        
        // Check if the notification is within the allowed time window
        if !isWithinNotificationTimeWindow(date) {
            print("⚠️ Notification not scheduled for \(date) - outside notification time window")
            return
        }
        
        print("✅ Logging reminder passed all checks for \(date)")
        
        let content = UNMutableNotificationContent()
        content.title = notificationMessages.randomElement() ?? "Time to Log Your Activity"
        content.body = notificationBodies.randomElement() ?? "Take a moment to reflect on what you've been working on for the past 30 minutes."
        content.sound = getRandomNotificationSound()
        content.categoryIdentifier = "LOGGING_REMINDER"
        content.threadIdentifier = "awarely-logging"
        
        // Create trigger for the specific date
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date),
            repeats: false
        )
        
        // Create request
        let request = UNNotificationRequest(
            identifier: "logging-reminder-\(date.timeIntervalSince1970)",
            content: content,
            trigger: trigger
        )
        
        // Schedule notification
        UNUserNotificationCenter.current().add(request) { error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ Error scheduling notification: \(error)")
                } else {
                    print("✅ Notification scheduled for \(date)")
                }
            }
        }
    }
    
    func scheduleDayStartedNotification(at date: Date) {
        print("🌅 Attempting to schedule day started notification for \(date)")
        
        // Check if notifications are enabled in user settings
        let userProfile = CoreDataManager.shared.getUserProfile()
        if let profile = userProfile, !profile.notificationEnabled {
            print("⚠️ Day started notification not scheduled for \(date) - notifications disabled in settings")
            return
        }
        
        print("✅ Day started notification passed all checks for \(date)")
        
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
                    print("❌ Error scheduling day started notification: \(error)")
                } else {
                    print("✅ Day started notification scheduled for \(date)")
                }
            }
        }
    }
    
    func cancelAllNotifications() {
        print("🗑️ Cancelling all pending notifications")
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        print("✅ All pending notifications cancelled")
    }
    
    func dismissAllDeliveredNotifications() {
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
        print("✅ Dismissed all delivered notifications")
    }
    
    func cancelNotification(for date: Date) {
        let identifier = "logging-reminder-\(date.timeIntervalSince1970)"
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
    }
    
    // MARK: - Enhanced Scheduling for Background Fetch
    
    func scheduleNotificationsForNextHours(hours: Int) {
        print("🔄 Background fetch triggered - scheduling notifications for next 3 days")
        // For background fetch, schedule for the next 3 days to ensure day boundary coverage
        // This ensures notifications work even if background fetch is unreliable
        scheduleNotificationsForNextDays(days: 3)
    }
    
    func scheduleNotificationsForToday() {
        print("📱 App launch/settings change - scheduling notifications for next 3 days")
        // Schedule notifications for the next 3 days to ensure continuous coverage
        scheduleNotificationsForNextDays(days: 3)
    }
    
    func scheduleNotificationsForNextDays(days: Int = 7) {
        print("📅 Starting to schedule notifications for next \(days) days")
        let calendar = Calendar.current
        let now = Date()
        print("⏰ Current time: \(now)")
        
        var totalScheduled = 0
        
        for dayOffset in 0..<days {
            guard let futureDate = calendar.date(byAdding: .day, value: dayOffset, to: now) else { continue }
            print("📆 Processing day \(dayOffset): \(futureDate)")
            
            let userProfile = CoreDataManager.shared.getUserProfile()
            
            // Get notification time window for this day
            let startTime: Date
            let endTime: Date
            
            if let savedStartTime = userProfile?.notificationStartTime,
               let savedEndTime = userProfile?.notificationEndTime {
                let targetDay = calendar.startOfDay(for: futureDate)
                let startComponents = calendar.dateComponents([.hour, .minute], from: savedStartTime)
                let endComponents = calendar.dateComponents([.hour, .minute], from: savedEndTime)
                
                startTime = calendar.date(bySettingHour: startComponents.hour ?? 9, 
                                        minute: startComponents.minute ?? 0, 
                                        second: 0, 
                                        of: targetDay) ?? futureDate
                endTime = calendar.date(bySettingHour: endComponents.hour ?? 18, 
                                      minute: endComponents.minute ?? 0, 
                                      second: 0, 
                                      of: targetDay) ?? futureDate
            } else {
                // Default times
                let targetDay = calendar.startOfDay(for: futureDate)
                startTime = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: targetDay) ?? futureDate
                endTime = calendar.date(bySettingHour: 18, minute: 0, second: 0, of: targetDay) ?? futureDate
            }
            
            // Schedule day started notification at the start time
            // Only schedule if it's for today and the start time hasn't passed by more than 1 hour
            // This allows for the day started notification even if the app is opened slightly after start time
            let oneHourAgo = now.addingTimeInterval(-60 * 60)
            print("🕘 Day \(dayOffset) - Start time: \(startTime), End time: \(endTime)")
            print("🕘 One hour ago: \(oneHourAgo)")
            
            if startTime > oneHourAgo {
                print("✅ Scheduling day started notification for \(startTime)")
                scheduleDayStartedNotification(at: startTime)
            } else {
                print("⏭️ Skipping day started notification for \(startTime) - too far in the past")
            }
            
            // Calculate all 30-minute intervals within the time window
            // First logging reminder should be at the END of the first interval (30 minutes after start time)
            var currentInterval = startTime.addingTimeInterval(30 * 60) // First logging reminder is 30 minutes after day starts (end of first interval)
            let intervalDuration: TimeInterval = 30 * 60 // 30 minutes
            
            print("⏰ Day \(dayOffset) - First logging reminder at: \(currentInterval)")
            var dayScheduledCount = 0
            
            while currentInterval < endTime {
                // Only schedule if the interval is in the future
                if currentInterval > now {
                    scheduleLoggingReminder(at: currentInterval)
                    totalScheduled += 1
                    dayScheduledCount += 1
                } else {
                    print("⏭️ Skipping past interval: \(currentInterval)")
                }
                currentInterval = currentInterval.addingTimeInterval(intervalDuration)
            }
            
            print("📊 Day \(dayOffset) scheduled \(dayScheduledCount) logging reminders")
        }
        
        print("📅 Scheduled \(totalScheduled) notifications for next \(days) days")
    }
    
    // MARK: - Settings Change Handling
    
    func rescheduleNotificationsForSettingsChange() {
        print("⚙️ Settings changed - rescheduling all notifications")
        // Cancel all existing notifications
        cancelAllNotifications()
        
        // Reschedule with new settings for the next 3 days
        scheduleNotificationsForNextDays(days: 3)
        
        print("🔄 Rescheduled notifications due to settings change")
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
        print("🕐 Checking if \(date) is within notification time window")
        
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
        let isWithin = date >= notificationStartTime && date <= notificationEndTime
        print("🕐 Time window check: \(date) is \(isWithin ? "WITHIN" : "OUTSIDE") window (\(notificationStartTime) - \(notificationEndTime))")
        return isWithin
    }
}

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
    
    func scheduleLoggingReminder(at date: Date) {
        // Check if the notification is within the allowed time window
        if !isWithinNotificationTimeWindow(date) {
            print("⚠️ Notification not scheduled for \(date) - outside notification time window")
            return
        }
        
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
    
    func cancelAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
    
    func cancelNotification(for date: Date) {
        let identifier = "logging-reminder-\(date.timeIntervalSince1970)"
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
    }
    
    // MARK: - Enhanced Scheduling for Background Fetch
    
    func scheduleNotificationsForNextHours(hours: Int) {
        let calendar = Calendar.current
        let now = Date()
        let userProfile = CoreDataManager.shared.getUserProfile()
        
        // Get notification time window
        let startTime: Date
        let endTime: Date
        
        if let savedStartTime = userProfile?.notificationStartTime,
           let savedEndTime = userProfile?.notificationEndTime {
            let today = calendar.startOfDay(for: now)
            let startComponents = calendar.dateComponents([.hour, .minute], from: savedStartTime)
            let endComponents = calendar.dateComponents([.hour, .minute], from: savedEndTime)
            
            startTime = calendar.date(bySettingHour: startComponents.hour ?? 9, 
                                    minute: startComponents.minute ?? 0, 
                                    second: 0, 
                                    of: today) ?? now
            endTime = calendar.date(bySettingHour: endComponents.hour ?? 18, 
                                  minute: endComponents.minute ?? 0, 
                                  second: 0, 
                                  of: today) ?? now
        } else {
            // Default times
            let today = calendar.startOfDay(for: now)
            startTime = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: today) ?? now
            endTime = calendar.date(bySettingHour: 18, minute: 0, second: 0, of: today) ?? now
        }
        
        // Calculate the target end time (now + specified hours)
        let targetEndTime = calendar.date(byAdding: .hour, value: hours, to: now) ?? now
        let effectiveEndTime = min(endTime, targetEndTime)
        
        // Calculate all 30-minute intervals within the time window
        var currentInterval = startTime
        let intervalDuration: TimeInterval = 30 * 60 // 30 minutes
        
        var scheduledCount = 0
        while currentInterval < effectiveEndTime {
            // Only schedule if the interval is in the future
            if currentInterval > now {
                scheduleLoggingReminder(at: currentInterval)
                scheduledCount += 1
            }
            currentInterval = currentInterval.addingTimeInterval(intervalDuration)
        }
        
        print("📅 Background fetch: Scheduled \(scheduledCount) notifications for next \(hours) hours")
    }
    
    func scheduleNotificationsForToday() {
        let calendar = Calendar.current
        let now = Date()
        let userProfile = CoreDataManager.shared.getUserProfile()
        
        // Get notification time window
        let startTime: Date
        let endTime: Date
        
        if let savedStartTime = userProfile?.notificationStartTime,
           let savedEndTime = userProfile?.notificationEndTime {
            let today = calendar.startOfDay(for: now)
            let startComponents = calendar.dateComponents([.hour, .minute], from: savedStartTime)
            let endComponents = calendar.dateComponents([.hour, .minute], from: savedEndTime)
            
            startTime = calendar.date(bySettingHour: startComponents.hour ?? 9, 
                                    minute: startComponents.minute ?? 0, 
                                    second: 0, 
                                    of: today) ?? now
            endTime = calendar.date(bySettingHour: endComponents.hour ?? 18, 
                                  minute: endComponents.minute ?? 0, 
                                  second: 0, 
                                  of: today) ?? now
        } else {
            // Default times
            let today = calendar.startOfDay(for: now)
            startTime = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: today) ?? now
            endTime = calendar.date(bySettingHour: 18, minute: 0, second: 0, of: today) ?? now
        }
        
        // Calculate all 30-minute intervals within the time window
        var currentInterval = startTime
        let intervalDuration: TimeInterval = 30 * 60 // 30 minutes
        
        var scheduledCount = 0
        while currentInterval < endTime {
            // Only schedule if the interval is in the future
            if currentInterval > now {
                scheduleLoggingReminder(at: currentInterval)
                scheduledCount += 1
            }
            currentInterval = currentInterval.addingTimeInterval(intervalDuration)
        }
        
        print("📅 Scheduled \(scheduledCount) notifications for today from \(startTime.formatted(date: .omitted, time: .shortened)) to \(endTime.formatted(date: .omitted, time: .shortened))")
    }
    
    func scheduleNotificationsForNextDays(days: Int = 7) {
        let calendar = Calendar.current
        let now = Date()
        
        var totalScheduled = 0
        
        for dayOffset in 0..<days {
            guard let futureDate = calendar.date(byAdding: .day, value: dayOffset, to: now) else { continue }
            
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
            
            // Calculate all 30-minute intervals within the time window
            var currentInterval = startTime
            let intervalDuration: TimeInterval = 30 * 60 // 30 minutes
            
            while currentInterval < endTime {
                // Only schedule if the interval is in the future
                if currentInterval > now {
                    scheduleLoggingReminder(at: currentInterval)
                    totalScheduled += 1
                }
                currentInterval = currentInterval.addingTimeInterval(intervalDuration)
            }
        }
        
        print("📅 Scheduled \(totalScheduled) notifications for next \(days) days")
    }
    
    // MARK: - Settings Change Handling
    
    func rescheduleNotificationsForSettingsChange() {
        // Cancel all existing notifications
        cancelAllNotifications()
        
        // Reschedule with new settings
        scheduleNotificationsForToday()
        
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
}

import Foundation
import UserNotifications

class NotificationManager: ObservableObject {
    static let shared = NotificationManager()
    
    private init() {}
    
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
        content.title = "Time to Log Your Activity"
        content.body = "Take a moment to reflect on what you've been working on for the past 30 minutes."
        content.sound = .default
        
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

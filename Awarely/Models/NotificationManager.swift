import Foundation
import UserNotifications

class NotificationManager: ObservableObject {
    static let shared = NotificationManager()
    
    private init() {}
    
    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if granted {
                print("Notification permission granted")
            } else if let error = error {
                print("Notification permission error: \(error)")
            }
        }
    }
    
    func scheduleLoggingReminder(at date: Date) {
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
            if let error = error {
                print("Error scheduling notification: \(error)")
            } else {
                print("Notification scheduled for \(date)")
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
}

//
//  AwarelyApp.swift
//  Awarely
//
//  Created by Evan Chen on 8/23/25.
//

import SwiftUI
import UserNotifications

@main
struct AwarelyApp: App {
    @StateObject private var coreDataManager = CoreDataManager.shared
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(coreDataManager)
                .dismissKeyboardOnTap()
        }
    }
}

// MARK: - App Delegate for Background Fetch and Notification Handling
class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Set minimum background fetch interval
        UIApplication.shared.setMinimumBackgroundFetchInterval(UIApplication.backgroundFetchIntervalMinimum)
        
        // Set notification delegate
        UNUserNotificationCenter.current().delegate = self
        
        // Set up notification categories
        setupNotificationCategories()
        
        return true
    }
    
    func application(_ application: UIApplication, performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        print("🔄 Background fetch triggered by iOS")
        // Schedule notifications for the next 3 days when woken up by iOS (hybrid approach)
        NotificationManager.shared.scheduleNotificationsForNextHours(hours: 4)
        print("🔄 Background fetch completed")
        completionHandler(.newData)
    }
    
    // MARK: - Notification Setup
    
    private func setupNotificationCategories() {
        // Create a category for logging reminders
        let loggingCategory = UNNotificationCategory(
            identifier: "LOGGING_REMINDER",
            actions: [],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )
        
        // Register the category
        UNUserNotificationCenter.current().setNotificationCategories([loggingCategory])
        print("✅ Notification categories set up")
    }
    
    // MARK: - UNUserNotificationCenterDelegate
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        // Handle notification tap - navigate to LogView
        print("🔔 Notification tapped: \(response.notification.request.identifier)")
        print("🔔 Notification content: \(response.notification.request.content.title)")
        
        // Post notification to navigate to LogView
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .navigateToLogView, object: nil)
        }
        
        completionHandler()
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Show notification even when app is in foreground
        print("🔔 Notification received while app is in foreground: \(notification.request.identifier)")
        completionHandler([.banner, .sound])
    }
}

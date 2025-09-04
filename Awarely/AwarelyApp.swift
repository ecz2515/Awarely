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

// MARK: - App Delegate for Background Fetch
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Set minimum background fetch interval
        UIApplication.shared.setMinimumBackgroundFetchInterval(UIApplication.backgroundFetchIntervalMinimum)
        return true
    }
    
    func application(_ application: UIApplication, performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        // Schedule notifications for the next few hours when woken up by iOS
        NotificationManager.shared.scheduleNotificationsForNextHours(hours: 4)
        completionHandler(.newData)
    }
}

import Foundation
import CoreData
import SwiftUI

class CoreDataManager: ObservableObject {
    static let shared = CoreDataManager()
    
    private let container: NSPersistentContainer
    
    var viewContext: NSManagedObjectContext {
        container.viewContext
    }
    
    private init() {
        container = NSPersistentContainer(name: "Awarely")
        
        container.loadPersistentStores { description, error in
            if let error = error {
                print("Core Data failed to load: \(error.localizedDescription)")
            }
        }
        
        // Enable automatic merging of changes
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
    
    // MARK: - User Profile Management
    
    func fetchOrCreateUserProfile() -> UserProfile {
        let request: NSFetchRequest<UserProfile> = UserProfile.fetchRequest()
        request.fetchLimit = 1
        
        do {
            let results = try viewContext.fetch(request)
            if let existingProfile = results.first {
                return existingProfile
            } else {
                // Create new profile
                let newProfile = UserProfile(context: viewContext)
                newProfile.id = UUID()
                newProfile.createdAt = Date()
                newProfile.name = "User"
                newProfile.notificationEnabled = true
                newProfile.reminderInterval = 30 * 60
                newProfile.loggingGracePeriod = 5
                newProfile.customTags = ["Read", "Practice", "Work", "Journal", "Exercise", "Meditate", "Meetings"] as NSArray
                newProfile.isPremiumUser = false
                
                // Set default notification times
                let calendar = Calendar.current
                let today = calendar.startOfDay(for: Date())
                newProfile.notificationStartTime = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: today)
                newProfile.notificationEndTime = calendar.date(bySettingHour: 18, minute: 0, second: 0, of: today)
                
                try viewContext.save()
                return newProfile
            }
        } catch {
            print("Error fetching or creating user profile: \(error)")
            // Create new profile as fallback
            let newProfile = UserProfile(context: viewContext)
            newProfile.id = UUID()
            newProfile.createdAt = Date()
            newProfile.name = "User"
            return newProfile
        }
    }
    
    func saveUserProfile() {
        do {
            try viewContext.save()
        } catch {
            print("Error saving user profile: \(error)")
        }
    }
    
    // MARK: - Log Entries Management
    
    func fetchAllLogEntries() -> [LogEntry] {
        let request: NSFetchRequest<PersistentLogEntry> = PersistentLogEntry.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \PersistentLogEntry.timestamp, ascending: false)]
        
        do {
            let results = try viewContext.fetch(request)
            return results.map { entry in
                LogEntry(
                    id: entry.id ?? UUID(),
                    text: entry.text ?? "",
                    tags: (entry.tags as? [String]) ?? [],
                    timestamp: entry.timestamp ?? Date(),
                    timePeriodStart: entry.timePeriodStart ?? Date(),
                    timePeriodEnd: entry.timePeriodEnd ?? Date()
                )
            }
        } catch {
            print("Error fetching log entries: \(error)")
            return []
        }
    }
    
    func addLogEntry(_ entry: LogEntry) {
        // Check if entry already exists
        let request: NSFetchRequest<PersistentLogEntry> = PersistentLogEntry.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", entry.id as CVarArg)
        
        do {
            let results = try viewContext.fetch(request)
            if results.isEmpty {
                // Entry doesn't exist, create new one
                let persistentEntry = PersistentLogEntry(context: viewContext)
                persistentEntry.id = entry.id
                persistentEntry.text = entry.text
                persistentEntry.tags = entry.tags as NSArray
                persistentEntry.timestamp = entry.timestamp
                persistentEntry.timePeriodStart = entry.timePeriodStart
                persistentEntry.timePeriodEnd = entry.timePeriodEnd
                
                // Associate with user profile
                let userProfile = fetchOrCreateUserProfile()
                persistentEntry.userProfile = userProfile
                
                saveContext()
            }
            // If entry already exists, do nothing (avoid duplicates)
        } catch {
            print("Error checking for existing entry: \(error)")
        }
    }
    
    func updateLogEntry(_ entry: LogEntry) {
        let request: NSFetchRequest<PersistentLogEntry> = PersistentLogEntry.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", entry.id as CVarArg)
        
        do {
            let results = try viewContext.fetch(request)
            if let existingEntry = results.first {
                existingEntry.text = entry.text
                existingEntry.tags = entry.tags as NSArray
                existingEntry.timestamp = entry.timestamp
                existingEntry.timePeriodStart = entry.timePeriodStart
                existingEntry.timePeriodEnd = entry.timePeriodEnd
                saveContext()
            }
        } catch {
            print("Error updating log entry: \(error)")
        }
    }
    
    func deleteLogEntry(withId id: UUID) {
        let request: NSFetchRequest<PersistentLogEntry> = PersistentLogEntry.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        
        do {
            let results = try viewContext.fetch(request)
            if let entryToDelete = results.first {
                viewContext.delete(entryToDelete)
                saveContext()
            }
        } catch {
            print("Error deleting log entry: \(error)")
        }
    }
    
    func deleteAllLogEntries() {
        let request: NSFetchRequest<NSFetchRequestResult> = PersistentLogEntry.fetchRequest()
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: request)
        
        do {
            try viewContext.execute(deleteRequest)
            saveContext()
        } catch {
            print("Error deleting all log entries: \(error)")
        }
    }
    
    // MARK: - Settings Management
    
    func updateNotificationSettings(enabled: Bool, interval: TimeInterval, startTime: Date?, endTime: Date?, gracePeriod: Int) {
        let userProfile = fetchOrCreateUserProfile()
        userProfile.notificationEnabled = enabled
        userProfile.reminderInterval = interval
        userProfile.notificationStartTime = startTime
        userProfile.notificationEndTime = endTime
        userProfile.loggingGracePeriod = Int32(gracePeriod)
        
        saveContext()
    }
    
    func updateCustomTags(_ tags: [String]) {
        let userProfile = fetchOrCreateUserProfile()
        userProfile.customTags = tags as NSArray
        saveContext()
    }
    
    // MARK: - Profile Management
    
    func updateUserName(_ name: String) {
        let userProfile = fetchOrCreateUserProfile()
        userProfile.name = name
        saveContext()
    }
    
    func getUserProfile() -> UserProfile? {
        let request: NSFetchRequest<UserProfile> = UserProfile.fetchRequest()
        request.fetchLimit = 1
        
        do {
            let results = try viewContext.fetch(request)
            return results.first
        } catch {
            print("Error fetching user profile: \(error)")
            return nil
        }
    }
    
    // MARK: - Private Methods
    
    private func saveContext() {
        do {
            try viewContext.save()
        } catch {
            print("Error saving context: \(error)")
        }
    }
}

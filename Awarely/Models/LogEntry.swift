//
//  LogEntry.swift
//  Awarely
//
//  Created by Evan Chen on 8/23/25.
//

import Foundation

struct LogEntry: Identifiable, Codable, Equatable {
    let id: UUID
    var text: String
    var tags: [String]
    let timestamp: Date
    let timePeriodStart: Date
    let timePeriodEnd: Date
    
    init(id: UUID = UUID(), text: String, tags: [String] = [], timestamp: Date, timePeriodStart: Date, timePeriodEnd: Date) {
        self.id = id
        self.text = text
        self.tags = tags
        self.timestamp = timestamp
        self.timePeriodStart = timePeriodStart
        self.timePeriodEnd = timePeriodEnd
    }
    
    // Backward compatibility initializer for existing entries
    init(id: UUID = UUID(), text: String, tags: [String] = [], timestamp: Date) {
        self.id = id
        self.text = text
        self.tags = tags
        self.timestamp = timestamp
        
        // Calculate time period based on timestamp for backward compatibility
        let calendar = Calendar.current
        let minute = calendar.component(.minute, from: timestamp)
        
        // Determine the interval start minute
        let intervalStartMinute: Int
        if minute < 30 {
            intervalStartMinute = 0
        } else {
            intervalStartMinute = 30
        }
        
        // Create interval start date
        var components = calendar.dateComponents([.year, .month, .day, .hour], from: timestamp)
        components.minute = intervalStartMinute
        components.second = 0
        
        self.timePeriodStart = calendar.date(from: components) ?? timestamp
        self.timePeriodEnd = self.timePeriodStart.addingTimeInterval(30 * 60) // 30 minutes
    }
    
    var timeString: String {
        timestamp.formatted(date: .omitted, time: .shortened)
    }
    
    var dateString: String {
        timestamp.formatted(date: .abbreviated, time: .omitted)
    }
    
    var timePeriodString: String {
        let startTime = timePeriodStart.formatted(date: .omitted, time: .shortened)
        let endTime = timePeriodEnd.formatted(date: .omitted, time: .shortened)
        return "\(startTime) - \(endTime)"
    }
    
    var timePeriodDuration: String {
        let duration = timePeriodEnd.timeIntervalSince(timePeriodStart)
        let minutes = Int(duration / 60)
        return "\(minutes) min"
    }
}

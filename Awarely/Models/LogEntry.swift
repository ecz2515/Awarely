//
//  LogEntry.swift
//  Awarely
//
//  Created by Evan Chen on 8/23/25.
//

import Foundation

struct LogEntry: Identifiable, Codable {
    let id: UUID
    var text: String
    var tags: [String]
    let timestamp: Date
    
    init(id: UUID = UUID(), text: String, tags: [String] = [], timestamp: Date) {
        self.id = id
        self.text = text
        self.tags = tags
        self.timestamp = timestamp
    }
    
    var timeString: String {
        timestamp.formatted(date: .omitted, time: .shortened)
    }
    
    var dateString: String {
        timestamp.formatted(date: .abbreviated, time: .omitted)
    }
}

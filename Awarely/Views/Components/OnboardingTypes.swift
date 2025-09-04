import Foundation

enum ActiveDaysPreset: String, CaseIterable {
    case weekdays = "Weekdays"
    case daily = "Daily"
    
    var description: String {
        switch self {
        case .weekdays: return "Monday to Friday"
        case .daily: return "Every day"
        }
    }
}

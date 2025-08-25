# Awarely

A lightweight productivity tracker built with SwiftUI that helps you stay mindful of how you spend your time throughout the day.

## Features

- **Timed Check-ins**: Get prompted every 30 minutes (or custom interval) to log your activities
- **Quick Logging**: Simple, frictionless entry system for capturing what you've been doing
- **Activity Timeline**: Review your day's activities in a chronological timeline
- **Satisfaction Ratings**: Rate your productivity and satisfaction for each entry
- **Smart Tagging**: Tag common activities for better organization and pattern recognition
- **Insightful Statistics**: View entry counts and average productivity over weekly/monthly periods
- **Pattern Recognition**: Spot trends in your productivity and focus patterns
- **Minimal Design**: Clean, distraction-free interface focused on awareness

## How It Works

Awarely is designed around a simple habit: regular check-ins throughout your day. Here's the workflow:

1. **Set Your Interval**: Choose how often you want to be prompted (default: 30 minutes)
2. **Quick Log**: When prompted, jot down what you've been working on
3. **Rate & Tag**: Add a satisfaction rating and relevant tags
4. **Review & Reflect**: Later, review your timeline to spot patterns and insights

## Getting Started

### Prerequisites

- iOS 15.0 or later
- Xcode 13.0 or later (for development)

### Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/Awarely.git
   ```

2. Open the project in Xcode:
   ```bash
   cd Awarely
   open Awarely.xcodeproj
   ```

3. Build and run the project on your device or simulator

## Project Structure

```
Awarely/
├── Awarely/
│   ├── Assets.xcassets/          # App icons and colors
│   ├── AwarelyApp.swift          # Main app entry point
│   ├── ContentView.swift         # Root view
│   ├── Item.swift               # Core data model
│   ├── Models/
│   │   └── LogEntry.swift       # Log entry data model
│   └── Views/
│       ├── Components/          # Reusable UI components
│       │   ├── ActionButton.swift
│       │   ├── EnhancedEntryRow.swift
│       │   ├── StatCard.swift
│       │   └── TagButton.swift
│       ├── EntriesListView.swift # Timeline view
│       ├── HomeView.swift       # Main dashboard
│       ├── LogView.swift        # Entry creation/editing
│       └── ProfileView.swift    # Settings and stats
├── AwarelyTests/                # Unit tests
└── AwarelyUITests/              # UI tests
```

## Development

### Architecture

Awarely is built using:
- **SwiftUI** for the user interface
- **Core Data** for data persistence
- **MVVM** architecture pattern
- **Combine** for reactive programming

### Key Components

- **LogEntry**: Core data model representing individual time entries
- **HomeView**: Main dashboard with statistics and quick actions
- **LogView**: Entry creation and editing interface
- **EntriesListView**: Timeline view of all entries
- **ProfileView**: Settings, statistics, and user preferences

## Screenshots

*[Screenshots will be added here]*

## Contributing

We welcome contributions! Please feel free to submit a Pull Request. For major changes, please open an issue first to discuss what you would like to change.

### Development Setup

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- Built with SwiftUI
- Inspired by the need for mindful productivity tracking
- Thanks to the SwiftUI community for inspiration and guidance

## Support

If you have any questions or need help, please:
- Open an issue on GitHub
- Check the existing issues for solutions
- Review the code documentation

---

**Awarely** - Stay mindful of your time, one check-in at a time.
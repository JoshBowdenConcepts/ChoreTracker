# ChoreTracker

An iOS chore tracking app with advanced recurrence patterns, multi-user household support via CloudKit sharing, and comprehensive task management features.

## Features

- **Advanced Recurrence Patterns**: Support for complex scheduling (e.g., "3rd Monday of every month", "30th of month or last day if shorter")
- **CloudKit Integration**: Private database with automatic iCloud sync across devices
- **Supervised Accounts**: Parent-controlled accounts with review workflow for chore completions
- **Goal Tracking**: Daily goal completion with streak tracking and statistics
- **Multi-User Support**: Household sharing via CloudKit with granular permissions
- **Privacy-First**: COPPA compliant, Kids Category ready, no third-party analytics

## Architecture

- **SwiftUI**: Modern declarative UI framework
- **CloudKit**: Private database for data storage and sync
- **Core Data**: Local persistence with CloudKit integration
- **Combine**: Reactive programming for data flow

## Requirements

- iOS 18.0+
- Xcode 16.0+ (or latest version supporting iOS 18)
- Active Apple Developer account (for CloudKit)

## Project Status

🚧 **In Planning Phase**

See [chore_tracker_plan.md](./chore_tracker_plan.md) for the complete development plan.

## Privacy & Security

This app is designed with privacy and security as top priorities:

- All data stored in user's iCloud account (CloudKit private database)
- No third-party analytics or tracking
- COPPA compliant for supervised accounts
- Designed for Kids Category compliance
- No external data transmission

See the plan document for detailed privacy and security practices.

## Development Phases

1. **Phase 1**: Core Foundation - Basic data models and CloudKit setup
2. **Phase 2**: Recurrence Engine - Complex scheduling patterns
3. **Phase 3**: Multi-User & Sharing - CloudKit sharing implementation
4. **Phase 3.5**: Supervised Accounts & Parent Review
5. **Phase 4**: Advanced Features - Notifications, statistics, analytics
6. **Phase 5**: Polish - UI refinements and testing

## License

_To be determined_

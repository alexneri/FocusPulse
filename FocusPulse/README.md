# FocusPulse - iOS Pomodoro Timer

A minimalist Pomodoro focus timer for iOS built with SwiftUI that helps users enhance productivity through structured work-break cycles.

## 🎯 Features

### Core Timer Functionality
- **Pomodoro Timer**: 25-minute work sessions with 5-minute short breaks
- **Long Breaks**: 15-minute breaks after every 4 work sessions
- **Customizable Durations**: Adjustable timer lengths for work and break sessions
- **Background Operation**: Timer continues running when app is in background
- **Visual Progress**: Beautiful circular progress indicator with smooth animations

### User Experience
- **Clean Interface**: Minimalist design using only SwiftUI primitives and SF Symbols
- **Accessibility**: Full VoiceOver support and dynamic type compatibility
- **Dark Mode**: Automatic light/dark mode support
- **Haptic Feedback**: Tactile feedback for timer events
- **Sound Effects**: Audio notifications for session transitions

### Productivity Tracking
- **Statistics Dashboard**: Track daily focus time, completed sessions, and streaks
- **Session History**: Detailed log of all completed and interrupted sessions
- **Progress Visualization**: Charts and metrics to monitor productivity trends
- **Export Data**: Share or backup productivity statistics

### Customization
- **Flexible Settings**: Customize timer durations and behavior preferences
- **Auto-Start Options**: Automatically transition between work and break sessions
- **Audio Preferences**: Control sound effects and haptic feedback
- **Music Integration**: Ready for Apple Music integration (Phase 2)

## 🏗️ Architecture

### MVVM Pattern
The app follows the Model-View-ViewModel architecture pattern:

- **Models**: Data structures for timer state, sessions, and settings
- **ViewModels**: `TimerEngine` manages business logic and state
- **Views**: SwiftUI views for UI presentation

### Key Components

#### TimerEngine (`ViewModels/TimerEngine.swift`)
- Core timer functionality and state management
- Session lifecycle management (work → break → long break)
- Background timer continuation
- Audio and haptic feedback integration
- Statistics tracking and session logging

#### Models (`Models/TimerModels.swift`)
- `TimerState`: Enum managing timer states (idle, running, paused, completed)
- `SessionType`: Work and break session types with durations
- `TimerSettings`: User preferences and configuration
- `CompletedSession`: Session history data model

#### Views
- **MainTimerView**: Primary interface with circular progress and controls
- **CircularProgressView**: Custom animated progress indicator
- **SettingsView**: Comprehensive settings with sliders and toggles
- **StatisticsView**: Productivity metrics and session history

## 🎨 Design System

### Visual Style
- **Theme**: iOS system colors with automatic dark mode
- **Typography**: SF Pro Display for timer, SF Pro Text for UI
- **Colors**: System Blue (primary), Green (success), Orange (breaks), Red (stop)
- **Spacing**: Native iOS spacing with 20px margins, 16px gutters

### UI Components
- **Circular Progress**: 240pt diameter with 8pt stroke weight
- **Control Buttons**: Circular buttons with SF Symbols and shadow effects
- **Metric Cards**: Clean cards with color-coded icons and values
- **Form Elements**: Native iOS form styling with grouped sections

## 📱 Screen Architecture

### Main Timer Screen
- Large circular progress indicator with time display
- Session type indicator with color coding
- Primary play/pause button with contextual stop/skip buttons
- Cycle progress indicator showing current position
- Navigation to settings and statistics

### Settings Screen
- Duration sliders for work, short break, and long break
- Audio and haptic preference toggles
- Auto-start behavior settings
- Data management options
- App information section

### Statistics Screen
- Time period selector (Daily/Weekly/Monthly)
- Key metrics cards (focus time, sessions, streak, completion rate)
- Chart visualization placeholder
- Recent session history with completion status

## 🔧 Technical Implementation

### State Management
- `@StateObject` for timer engine lifecycle management
- `@Published` properties for reactive UI updates
- `@ObservedObject` for shared state across views
- Combine framework for reactive programming

### Timer Implementation
- Foundation `Timer` for precise countdown functionality
- Background task handling for continued operation
- State persistence across app lifecycle
- Automatic session transitions with customizable delays

### User Interface
- SwiftUI declarative syntax for modern iOS development
- Geometry readers for responsive layout
- Custom view modifiers for consistent styling
- Accessibility labels and hints for VoiceOver

### Audio & Haptics
- AVFoundation audio session management
- UIImpactFeedbackGenerator for haptic feedback
- Configurable sound effects system
- Background audio compatibility

## 🚀 Getting Started

### Requirements
- iOS 15.0+
- Xcode 14.0+
- Swift 5.7+

### Installation
1. Clone the repository
2. Open `FocusPulse.xcodeproj` in Xcode
3. Select your target device or simulator
4. Build and run the project

### Project Structure
```
FocusPulse/
├── Models/
│   └── TimerModels.swift           # Core data models
├── ViewModels/
│   └── TimerEngine.swift           # Business logic and state management
├── Views/
│   ├── MainTimerView.swift         # Primary timer interface
│   ├── SettingsView.swift          # Configuration screen
│   ├── StatisticsView.swift        # Productivity metrics
│   └── Components/
│       └── CircularProgressView.swift  # Custom progress indicator
├── Assets.xcassets/                # App icons and colors
├── ContentView.swift               # Root view controller
└── FocusPulseApp.swift            # App entry point
```

## 🎯 Usage

### Starting a Focus Session
1. Launch the app to see the main timer screen
2. Tap the large blue play button to start a 25-minute work session
3. The circular progress indicator shows remaining time
4. Timer continues running even when app is backgrounded

### Customizing Settings
1. Tap the gear icon in the top-right corner
2. Adjust work and break durations using sliders
3. Configure auto-start behavior for seamless sessions
4. Enable/disable sound effects and haptic feedback

### Viewing Statistics
1. Tap the chart icon in the top-left corner
2. Switch between Daily, Weekly, and Monthly views
3. Review key metrics: focus time, completed sessions, streaks
4. Browse recent session history with completion status

## 🔮 Future Enhancements

### Phase 2 Features
- Apple Music integration for automatic playback control
- Home screen widgets for quick timer access
- Cloud sync for cross-device session data
- Advanced analytics and productivity insights

### Phase 3 Features
- Social features and team challenges
- Calendar integration for scheduled focus blocks
- Custom session types and goals
- Shortcuts app integration

## 🤝 Contributing

This project follows iOS development best practices:
- Clean, readable code with comprehensive documentation
- SOLID principles and separation of concerns
- Comprehensive accessibility support
- Performance optimization and memory management

## 📄 License

This project is for demonstration purposes and follows the comprehensive system design specified in the project documentation.

---

**FocusPulse** - Enhancing productivity through focused work sessions with a clean, intuitive iOS experience. 
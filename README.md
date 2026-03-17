# SnakeGame

Universal SwiftUI snake game for iPhone and iPad.

## Features

- Universal layout for iPhone and iPad
- SwiftUI-based game UI with touch and keyboard controls
- Three difficulty modes: `Chill`, `Classic`, `Frenzy`
- Countdown, pause/resume, game over summary
- Per-difficulty best score tracking
- Local stats for recent rounds, longest snake, and total games
- Sound and haptic feedback with persistent settings
- Unit tests for the game engine and session state machine

## Project Structure

```text
SnakeGame/
├── App/         App entry and root container view
├── Core/        Game rules, model, session state, difficulty types
├── UI/          Menu, board, HUD, controls, overlays, theme
├── Stores/      Persistent settings and stats stores
├── Services/    Audio and haptic feedback service
└── Resources/   Info.plist, launch screen, sounds, assets

SnakeGameTests/  Engine and model unit tests
```

## Key Files

- `SnakeGame/App/SnakeGameApp.swift`: app entry point
- `SnakeGame/App/ContentView.swift`: root container that switches between menu and game flows
- `SnakeGame/Core/SnakeGameEngine.swift`: pure game engine with deterministic random support for tests
- `SnakeGame/Core/SnakeGameModel.swift`: timer, lifecycle, state machine, stats integration
- `SnakeGame/Stores/GameSettingsStore.swift`: persistent sound and haptics settings
- `SnakeGame/Stores/GameStatsStore.swift`: persistent scores and round history

## Architecture

The project keeps the game rules separate from UI concerns:

- `SnakeGameEngine` is a pure rules engine. It advances the snake one tick at a time and returns a `TickResult`.
- `SnakeGameModel` is the session controller. It owns the timer, app lifecycle handling, countdown flow, and persistence hooks.
- SwiftUI views render state only. They do not create timers or write to `UserDefaults` directly.
- Settings and stats are stored in dedicated stores so they remain testable and easy to replace later.

## Requirements

- Xcode 16 or newer
- iOS Simulator or iOS device target supported by the installed Xcode toolchain

## Build

```bash
xcodebuild \
  -project SnakeGame.xcodeproj \
  -scheme SnakeGame \
  -sdk iphonesimulator \
  -configuration Debug \
  -derivedDataPath ./DerivedData \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO \
  build
```

## Test

```bash
xcodebuild \
  -project SnakeGame.xcodeproj \
  -scheme SnakeGame \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.2' \
  -derivedDataPath ./DerivedData_tests \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO \
  test
```

## Gameplay Notes

- The board size is currently fixed at `18 x 18`.
- Backgrounding the app pauses the round.
- Returning to the foreground resumes through a 3-second countdown.
- Keyboard input supports arrow keys and `WASD` when hardware keyboard input is available.

## Repository Hygiene

- Generated build output such as `DerivedData*`, `.xcresult`, and user-specific Xcode state are ignored via `.gitignore`.
- The workspace root is expected to stay limited to source, tests, project files, and documentation.

---
inclusion: fileMatch
fileMatchPattern: '{**/*.swift,**/*.xib,**/*.storyboard,**/Package.swift,**/Info.plist}'
name: ios-standards
description: 'iOS/Swift development standards — SwiftUI, MVVM+Combine, naming conventions, project structure, accessibility, performance. Use when writing or reviewing Swift/SwiftUI code.'
---

# iOS Development Standards

## Language & Version

- Swift 5.9+ with strict concurrency checking enabled
- Minimum deployment target: iOS 17.0
- Use `@available` annotations for APIs newer than deployment target
- Enable all strict concurrency warnings in build settings

## Architecture

**MVVM + Repository + Coordinator** is the standard pattern:

- **Model:** Pure data structs (Codable, Hashable, Sendable)
- **View:** SwiftUI views — declarative, stateless, composable
- **ViewModel:** @MainActor ObservableObject — owns state, exposes published properties, calls services
- **Repository:** Data access layer — abstracts remote vs local, handles offline-first logic
- **Coordinator:** Navigation logic — keeps views unaware of navigation graph
- **Service:** Business logic — stateless, protocol-defined, injected

## Naming Conventions

| Type               | Convention                          | Example                                       |
| ------------------ | ----------------------------------- | --------------------------------------------- |
| Types              | UpperCamelCase                      | `TripPlanningViewModel`                       |
| Properties/Methods | lowerCamelCase                      | `isNavigationActive`                          |
| Protocols          | Adjective or noun + Protocol suffix | `TripServiceProtocol`                         |
| Enum cases         | lowerCamelCase                      | `case navigating`                             |
| Constants          | lowerCamelCase                      | `static let maxCacheSizeMB = 500`             |
| Boolean properties | `is`, `has`, `should`, `can` prefix | `isOffline`, `hasDownloaded`                  |
| Actions            | verb phrase                         | `didTapStartTrip()`, `handleRouteDeviation()` |
| Files              | Match primary type name             | `TripPlanningView.swift`                      |

## SwiftUI Rules

1. View body < 50 lines — extract subviews
2. Use `@StateObject` for ViewModels created by the view
3. Use `@ObservedObject` for ViewModels passed from parent
4. Use `@Environment(\.dismiss)` over manual dismissal
5. Prefer `.task {}` over `.onAppear {}` for async work
6. Always provide meaningful `accessibilityLabel` for non-text elements
7. Support Dynamic Type (never hardcode font sizes, use `.font(.title)` etc.)
8. Support dark mode (use semantic colors from asset catalog)
9. Use `ViewModifier` for reusable styling
10. Prefer composition over nesting (extract, don't indent)

## Accessibility (MANDATORY)

- Every interactive element MUST have an accessibility label
- Every image MUST have `accessibilityLabel` or be marked `.accessibilityHidden(true)` if decorative
- Use `.accessibilityHint` for non-obvious actions
- Support VoiceOver navigation order (`.accessibilitySortPriority`)
- Test with Accessibility Inspector
- Minimum touch target: 44x44pt (Apple HIG)

## Performance

- Use `LazyVStack` / `LazyHStack` for scrollable lists
- Use `.task` with cancellation (structured concurrency handles this)
- Avoid `@Published` for high-frequency updates — use Combine `.throttle`
- Image loading: always use async loading + disk cache (Kingfisher)
- Core Data: use `NSFetchedResultsController` for live queries
- Animations: 60fps target, use `.animation(.default, value:)` not `.animation(.default)`
- Minimize view re-renders: use `@Observable` (iOS 17+) or fine-grained `@Published`

## Error Handling

- Define domain-specific error enums conforming to `LocalizedError`
- Never use `try!` or `fatalError()` in production code
- Use `Result` type for synchronous fallible operations
- Use `async throws` for asynchronous fallible operations
- Surface errors to user via toast/banner — never crash silently
- Log errors with structured logging (os.Logger)

## Security

- Store tokens in Keychain (never UserDefaults)
- Use certificate pinning for API calls
- Sanitize user inputs before API calls
- Use App Transport Security (no arbitrary loads)
- Biometric auth via LocalAuthentication framework
- Never log sensitive data (tokens, passwords, PII)

## Dependency Management

- Swift Package Manager ONLY (no CocoaPods, no Carthage)
- Pin exact versions in Package.resolved
- Prefer first-party Apple frameworks over third-party when equivalent
- Audit dependencies for security before adding

## Git & Source Control

- One feature per branch
- PR must pass: SwiftLint, build, unit tests, UI tests
- Commit message format: `feat(tripPlanning): add waypoint reordering`
- Tag releases: `v1.0.0`, `v1.1.0-beta.1`

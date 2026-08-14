---
inclusion: fileMatch
fileMatchPattern: '{**/CarPlay/**/*,**/*CarPlay*,**/*CPTemplate*,**/*CPNavigation*}'
name: ios-carplay
description: 'CarPlay development guidelines — template architecture, navigation sessions, audio sessions, Apple HIG for automotive. Use when implementing CarPlay features.'
---

# CarPlay Development Standards

## Architecture

CarPlay runs as a SEPARATE scene from the phone app. They share the same process but have independent UI lifecycles.

### Scene Configuration (Info.plist)

```xml
<key>UIApplicationSceneManifest</key>
<dict>
  <key>UISceneConfigurations</key>
  <dict>
    <key>CPTemplateApplicationSceneSessionRoleApplication</key>
    <array>
      <dict>
        <key>UISceneConfigurationName</key>
        <string>CarPlay</string>
        <key>UISceneDelegateClassName</key>
        <string>$(PRODUCT_MODULE_NAME).CarPlaySceneDelegate</string>
      </dict>
    </array>
  </dict>
</dict>
```

### Scene Delegate Pattern

```swift
final class CarPlaySceneDelegate: UIResponder, CPTemplateApplicationSceneDelegate {
    var interfaceController: CPInterfaceController?
    var mapTemplate: CPMapTemplate?
    private var navigationSession: CPNavigationSession?

    func templateApplicationScene(
        _ templateApplicationScene: CPTemplateApplicationScene,
        didConnect interfaceController: CPInterfaceController
    ) {
        self.interfaceController = interfaceController
        let mapTemplate = CPMapTemplate()
        mapTemplate.mapDelegate = self
        self.mapTemplate = mapTemplate
        interfaceController.setRootTemplate(mapTemplate, animated: true)
    }

    func templateApplicationScene(
        _ templateApplicationScene: CPTemplateApplicationScene,
        didDisconnect interfaceController: CPInterfaceController
    ) {
        self.interfaceController = nil
        self.mapTemplate = nil
    }
}
```

## Template Hierarchy for Navigation Apps

```
CPMapTemplate (root)
├── CPNavigationSession (active navigation)
│   ├── CPTrip
│   │   ├── CPRouteChoice[]
│   │   └── MKMapItem[] (waypoints)
│   └── CPManeuver[] (turn-by-turn instructions)
├── CPNowPlayingTemplate (audio/podcast)
├── CPListTemplate (trip list, stop list)
├── CPGridTemplate (quick actions)
└── CPAlertTemplate (alerts, hazards)
```

## Navigation Session Lifecycle

1. **Plan trip:** Create `CPTrip` from route data
2. **Start navigation:** `mapTemplate.startNavigationSession(for: trip)`
3. **Update maneuvers:** Push `CPManeuver` objects as user approaches turns
4. **Handle re-routing:** Cancel session, create new trip, start new session
5. **End navigation:** `navigationSession.finishTrip()` or `cancelTrip()`

### CPManeuver Configuration

```swift
func createManeuver(for step: RouteStep) -> CPManeuver {
    let maneuver = CPManeuver()
    maneuver.instructionVariants = [step.instruction]  // Multiple lengths for display
    maneuver.initialTravelEstimates = CPTravelEstimates(
        distanceRemaining: Measurement(value: step.distanceMeters, unit: .meters),
        timeRemaining: step.estimatedTime
    )
    maneuver.symbolSet = CPImageSet(
        lightContentImage: step.turnIcon.light,
        darkContentImage: step.turnIcon.dark
    )
    return maneuver
}
```

## Apple HIG Requirements (MANDATORY)

1. **No custom drawing** — use templates only (CPMapTemplate, CPListTemplate, etc.)
2. **Maximum 5 list items** per CPListTemplate section
3. **Maximum 2 rows of text** per list item
4. **Button images: 44x44pt** maximum, template-rendered (SF Symbols preferred)
5. **Minimize driver distraction** — voice interaction primary, touch secondary
6. **No video, no scrolling text, no animations** on car display
7. **Respond to button presses within 1 second**
8. **Test at both day and night appearances**

## Audio Session for CarPlay

CarPlay navigation apps need proper audio session configuration:

```swift
func configureAudioSession() throws {
    let session = AVAudioSession.sharedInstance()
    try session.setCategory(
        .playback,
        mode: .spokenAudio,
        options: [.duckOthers, .interruptSpokenAudioAndMixWithOthers]
    )
    try session.setActive(true)
}
```

Key rules:

- Category: `.playback` (not `.ambient`)
- Mode: `.spokenAudio` for podcast content
- Options: `.duckOthers` to lower music during announcements
- Handle interruptions (phone calls, Siri) via `AVAudioSession.interruptionNotification`

## Now Playing Template

```swift
func setupNowPlaying() {
    let nowPlayingTemplate = CPNowPlayingTemplate.shared
    nowPlayingTemplate.add(self)  // CPNowPlayingTemplateObserver

    // Buttons: skip, repeat, custom ("Tell me more")
    let skipButton = CPNowPlayingPlaybackRateButton(handler: { [weak self] _ in
        self?.skipSegment()
    })
    nowPlayingTemplate.updateNowPlayingButtons([skipButton])
}
```

## Map Interaction

```swift
extension CarPlaySceneDelegate: CPMapTemplateDelegate {
    func mapTemplate(_ mapTemplate: CPMapTemplate, panWith direction: CPMapTemplate.PanDirection) {
        // Handle user panning the map
    }

    func mapTemplate(_ mapTemplate: CPMapTemplate, didEndPanGestureWithVelocity velocity: CGPoint) {
        // Re-center on user location after pan
    }

    func mapTemplateDidShowPanningInterface(_ mapTemplate: CPMapTemplate) {
        // Show pan controls
    }
}
```

## Testing CarPlay

1. **Xcode CarPlay Simulator:** Window > Devices and Simulators > connect CarPlay
2. **Test both connected and disconnected states**
3. **Test audio session interruptions** (simulate phone call)
4. **Test with limited connectivity** (Network Link Conditioner)
5. **Verify template limits** (5 items, 2 text rows)
6. **Test day/night mode transitions**
7. **Verify background audio continues when CarPlay disconnects**

## State Synchronization

The CarPlay scene and phone scene share state:

- Navigation state (route, position, maneuvers)
- Audio playback state (now playing, queue)
- Trip state (active, paused)

Use a shared `NavigationStateManager` (actor) to avoid race conditions between scenes.

## Entitlements

```xml
<!-- Required for CarPlay navigation -->
<key>com.apple.developer.carplay-navigation</key>
<true/>
```

Apply for the CarPlay navigation entitlement through Apple Developer portal BEFORE submitting to TestFlight/App Store.

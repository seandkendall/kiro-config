---
inclusion: fileMatch
fileMatchPattern: '{**/*.swift,**/Audio/**/*,**/Podcast/**/*,**/Music/**/*}'
name: ios-audio-standards
description: "iOS audio standards — AVAudioSession, audio ducking/smart-fade, MusicKit integration, background audio, CarPlay audio. Use when implementing audio playback or music features."
---

# iOS Audio Standards

## AVAudioSession Configuration

### Session Categories

```swift
final class AudioSessionManager {
    static let shared = AudioSessionManager()
    
    func configure() throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(
            .playback,                    // Continue in background
            mode: .spokenAudio,           // Optimize for speech
            options: [
                .duckOthers,              // Lower other audio during our playback
                .interruptSpokenAudioAndMixWithOthers
            ]
        )
        try session.setActive(true, options: .notifyOthersOnDeactivation)
        
        // Listen for interruptions (phone calls, Siri, etc.)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleInterruption),
            name: AVAudioSession.interruptionNotification,
            object: nil
        )
    }
    
    @objc private func handleInterruption(_ notification: Notification) {
        guard let info = notification.userInfo,
              let typeValue = info[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue)
        else { return }
        
        switch type {
        case .began:
            // Pause podcast, note position
            break
        case .ended:
            guard let optionsValue = info[AVAudioSessionInterruptionOptionKey] as? UInt else { return }
            let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
            if options.contains(.shouldResume) {
                // Resume podcast playback
            }
        @unknown default: break
        }
    }
}
```

## Smart-Fade (Music <-> Podcast)

The core UX: when a podcast segment triggers, music volume fades down, podcast plays, then music fades back up.

```swift
actor SmartFadeController {
    private let musicPlayer: MusicPlayerProtocol
    private let podcastPlayer: PodcastPlayerProtocol
    private let fadeDuration: TimeInterval = 2.0
    private let duckLevel: Float = 0.15  // 15% volume during podcast
    
    func triggerPodcastSegment(_ segment: PodcastSegment) async {
        // 1. Fade music down (2 seconds)
        await musicPlayer.fadeVolume(to: duckLevel, duration: fadeDuration)
        
        // 2. Play podcast segment at full volume
        await podcastPlayer.play(segment)
        
        // 3. Wait for segment to finish (or user skip)
        await podcastPlayer.awaitCompletion()
        
        // 4. Fade music back up (2 seconds)
        await musicPlayer.fadeVolume(to: musicPlayer.userVolume, duration: fadeDuration)
    }
    
    func skipCurrentSegment() async {
        await podcastPlayer.stop()
        await musicPlayer.fadeVolume(to: musicPlayer.userVolume, duration: 0.5)
    }
}
```

### Volume Fade Implementation

```swift
extension AVAudioPlayer {
    func fadeVolume(to target: Float, duration: TimeInterval) async {
        let steps = 20
        let interval = duration / Double(steps)
        let volumeStep = (target - volume) / Float(steps)
        
        for _ in 0..<steps {
            volume += volumeStep
            try? await Task.sleep(for: .milliseconds(Int(interval * 1000)))
        }
        volume = target  // Ensure exact final value
    }
}
```

## MusicKit Integration

### Authorization

```swift
import MusicKit

func requestMusicAccess() async -> MusicAuthorization.Status {
    let status = await MusicAuthorization.request()
    return status
}
```

### Playback Control

```swift
final class MusicService: ObservableObject {
    private let player = ApplicationMusicPlayer.shared
    
    @Published var isPlaying = false
    @Published var nowPlaying: MusicKit.Song?
    @Published var currentArtwork: Artwork?
    
    var userVolume: Float = 0.8
    
    func play(playlist: Playlist) async throws {
        player.queue = [playlist]
        try await player.play()
        isPlaying = true
    }
    
    func pause() {
        player.pause()
        isPlaying = false
    }
    
    func skip() async throws {
        try await player.skipToNextEntry()
    }
    
    func setVolume(_ level: Float) {
        // MusicKit doesn't expose volume directly — use MPVolumeView or system volume
        // For ducking: use AVAudioSession.duckOthers option instead
    }
    
    func observeNowPlaying() {
        // Use player.state publisher for real-time updates
        Task {
            for await state in player.state.objectWillChange.values {
                await MainActor.run {
                    self.isPlaying = player.state.playbackStatus == .playing
                    self.nowPlaying = player.queue.currentEntry?.item as? Song
                }
            }
        }
    }
}
```

### Playlist Browsing

```swift
func fetchUserPlaylists() async throws -> [Playlist] {
    let request = MusicLibraryRequest<Playlist>()
    let response = try await request.response()
    return Array(response.items)
}

func searchPlaylists(query: String) async throws -> [Playlist] {
    var request = MusicCatalogSearchRequest(term: query, types: [Playlist.self])
    request.limit = 20
    let response = try await request.response()
    return Array(response.playlists)
}
```

## Podcast Audio Player

```swift
final class PodcastPlayer: ObservableObject {
    private var audioPlayer: AVAudioPlayer?
    @Published var isPlaying = false
    @Published var currentSegment: PodcastSegment?
    @Published var progress: Double = 0  // 0.0 to 1.0
    
    private var completionContinuation: CheckedContinuation<Void, Never>?
    
    func play(_ segment: PodcastSegment) async {
        guard let localURL = AudioCacheManager.shared.localURL(for: segment.id) else {
            // Content not cached — skip silently (offline-first rule)
            return
        }
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: localURL)
            audioPlayer?.delegate = self
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
            currentSegment = segment
            isPlaying = true
        } catch {
            // Log error, don't surface to user
            os_log(.error, "Failed to play segment: \(error)")
        }
    }
    
    func awaitCompletion() async {
        await withCheckedContinuation { continuation in
            completionContinuation = continuation
        }
    }
    
    func stop() {
        audioPlayer?.stop()
        isPlaying = false
        completionContinuation?.resume()
        completionContinuation = nil
    }
}

extension PodcastPlayer: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        isPlaying = false
        completionContinuation?.resume()
        completionContinuation = nil
    }
}
```

## Background Audio

### Info.plist

```xml
<key>UIBackgroundModes</key>
<array>
    <string>audio</string>
    <string>location</string>
</array>
```

### Now Playing Info

```swift
import MediaPlayer

func updateNowPlayingInfo(segment: PodcastSegment) {
    var info = [String: Any]()
    info[MPMediaItemPropertyTitle] = segment.title
    info[MPMediaItemPropertyArtist] = "RoadCast"
    info[MPMediaItemPropertyPlaybackDuration] = segment.duration
    info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = audioPlayer?.currentTime ?? 0
    info[MPNowPlayingInfoPropertyPlaybackRate] = 1.0
    MPNowPlayingInfoCenter.default().nowPlayingInfo = info
}
```

### Remote Command Center

```swift
func setupRemoteCommands() {
    let center = MPRemoteCommandCenter.shared()
    
    center.playCommand.addTarget { [weak self] _ in
        self?.resume()
        return .success
    }
    center.pauseCommand.addTarget { [weak self] _ in
        self?.pause()
        return .success
    }
    center.nextTrackCommand.addTarget { [weak self] _ in
        self?.skipSegment()
        return .success
    }
}
```

## Geofence-Triggered Playback

```swift
final class ContentTriggerService: CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    private let smartFade: SmartFadeController
    private var activeGeofences: [String: PodcastSegment] = [:]
    
    func registerGeofences(for segments: [PodcastSegment]) {
        for segment in segments {
            let region = CLCircularRegion(
                center: segment.triggerCoordinate,
                radius: segment.triggerRadius,
                identifier: segment.id
            )
            region.notifyOnEntry = true
            region.notifyOnExit = false
            locationManager.startMonitoring(for: region)
            activeGeofences[segment.id] = segment
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        guard let segment = activeGeofences[region.identifier] else { return }
        Task {
            await smartFade.triggerPodcastSegment(segment)
        }
    }
}
```

## Rules

1. ALWAYS configure AVAudioSession before any playback
2. ALWAYS handle interruptions gracefully (phone calls, Siri)
3. NEVER play audio without checking if a segment is cached locally
4. ALWAYS update MPNowPlayingInfoCenter for lock screen / CarPlay display
5. ALWAYS register remote command targets for hardware controls
6. Smart-fade duration: 2 seconds down, 2 seconds up (never instant)
7. Duck level: 15% (audible but not competing with speech)
8. If no music is playing when podcast triggers, just play podcast (no fade needed)
9. Respect user's "Chill mode" — reduce trigger frequency, don't suppress audio quality
10. CarPlay and phone app share the same audio session — coordinate via shared state actor

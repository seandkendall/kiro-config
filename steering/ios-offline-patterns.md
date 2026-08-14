---
inclusion: fileMatch
fileMatchPattern: '{**/*.swift,**/CoreData/**/*,**/Persistence/**/*,**/Cache/**/*,**/Offline/**/*}'
name: ios-offline-patterns
description: 'Offline-first iOS patterns — Core Data, NWPathMonitor, cache management, sync strategies, silent failover. Use when implementing offline capabilities or data persistence.'
---

# iOS Offline-First Patterns

## Core Principle

The user must NEVER notice connectivity loss. All critical features (navigation, podcast playback, trip data) must work identically offline. The app silently fails over to cached data and syncs when connectivity returns.

## Connectivity Monitoring

```swift
import Network

actor ConnectivityMonitor {
    enum ConnectionState: Sendable {
        case excellent   // >5 Mbps, <100ms latency
        case good        // 1-5 Mbps, <500ms latency
        case poor        // <1 Mbps or >500ms latency
        case offline     // No connectivity
    }

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "connectivity")
    @Published private(set) var state: ConnectionState = .offline

    func start() {
        monitor.pathUpdateHandler = { [weak self] path in
            Task { await self?.evaluate(path) }
        }
        monitor.start(queue: queue)
    }

    private func evaluate(_ path: NWPath) {
        guard path.status == .satisfied else {
            state = .offline
            return
        }
        // Evaluate quality based on interface type and constraints
        if path.usesInterfaceType(.wifi) && !path.isConstrained {
            state = .excellent
        } else if path.usesInterfaceType(.cellular) && !path.isExpensive {
            state = .good
        } else {
            state = .poor
        }
    }
}
```

## Behavior per Connection State

| State     | Navigation             | Podcast                       | Downloads        | Sync            |
| --------- | ---------------------- | ----------------------------- | ---------------- | --------------- |
| Excellent | Live routing + traffic | Stream if not cached          | Active pre-fetch | Real-time       |
| Good      | Live routing           | Play from cache, fetch next 2 | Opportunistic    | Every 5 min     |
| Poor      | Cached route           | Cache only                    | None             | Queue for later |
| Offline   | Cached route + GPS     | Cache only                    | None             | Queue all       |

## Cache Architecture

### Three-Tier Cache

```swift
protocol CacheLayer {
    func get<T: Codable>(key: String) -> T?
    func set<T: Codable>(key: String, value: T, ttl: TimeInterval?)
    func remove(key: String)
    func clear()
}

// Tier 1: In-memory (NSCache) — hot data, auto-evicted on memory pressure
// Tier 2: Disk (FileManager) — audio files, map tiles, large blobs
// Tier 3: Core Data — structured data (trips, segments, user data)
```

### Content Priority Queue

When downloading content, priority order:

1. Active trip: next 60 minutes of audio segments
2. Active trip: remaining segments
3. Map tiles for route corridor
4. Upcoming trip content (scheduled for future)
5. Background refresh of stale cached content

### Storage Budget

```swift
struct CacheBudget {
    static let audioMaxMB: Int = 2000      // 2GB for podcast audio
    static let mapTilesMaxMB: Int = 1000   // 1GB for offline map tiles
    static let metadataMaxMB: Int = 100    // 100MB for trip/user data

    // User-configurable total limit
    var userLimit: Int = 5000  // 5GB default, configurable in settings
}
```

### LRU Eviction

```swift
final class CacheEvictor {
    func evictIfNeeded(budget: CacheBudget) async {
        let currentSize = await calculateCacheSize()
        guard currentSize > budget.userLimit else { return }

        // Priority-based eviction (lowest priority evicted first):
        // 1. Completed trips older than 30 days (audio)
        // 2. Map tiles for non-active routes
        // 3. Completed trip metadata older than 90 days
        // NEVER evict: active trip content, active navigation tiles
    }
}
```

## Core Data Stack

### Configuration

```swift
final class PersistenceController {
    static let shared = PersistenceController()
    let container: NSPersistentContainer

    init() {
        container = NSPersistentContainer(name: "RoadCast")
        container.loadPersistentStores { description, error in
            if let error { fatalError("Core Data failed: \(error)") }
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }

    func backgroundContext() -> NSManagedObjectContext {
        let context = container.newBackgroundContext()
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return context
    }
}
```

### Sync Conflict Resolution

- **Last-write-wins** for user preferences, profile data
- **Server-wins** for trip content (server is source of truth for generated content)
- **Client-wins** for trip analytics during offline (client has the real GPS data)
- **Merge** for trip waypoints edited collaboratively

## Offline Queue (Pending Operations)

```swift
struct PendingOperation: Codable {
    let id: UUID
    let type: OperationType
    let payload: Data
    let createdAt: Date
    let retryCount: Int
    let maxRetries: Int

    enum OperationType: String, Codable {
        case syncAnalytics
        case reportContent
        case uploadNote
        case updateTripProgress
    }
}

actor OfflineQueue {
    private var queue: [PendingOperation] = []

    func enqueue(_ operation: PendingOperation) {
        queue.append(operation)
        persistToDisk()
    }

    func flush() async {
        // Process in order, retry on failure, DLQ after maxRetries
    }
}
```

## Map Tile Caching (iOS 17+)

```swift
import MapKit

func downloadOfflineTiles(for route: MKRoute, buffer: CLLocationDistance = 10_000) async throws {
    // iOS 17+ offline maps API
    let region = route.polyline.boundingMapRect.insetBy(dx: -buffer, dy: -buffer)
    // Download tiles for the corridor
    // Store download progress for UI feedback
}
```

## Audio File Caching

```swift
actor AudioCacheManager {
    private let fileManager = FileManager.default
    private let cacheDirectory: URL

    func cacheAudioSegment(segmentId: String, from url: URL) async throws -> URL {
        let localPath = cacheDirectory.appendingPathComponent("\(segmentId).mp3")
        guard !fileManager.fileExists(atPath: localPath.path) else {
            return localPath  // Already cached
        }

        let (tempURL, _) = try await URLSession.shared.download(from: url)
        try fileManager.moveItem(at: tempURL, to: localPath)
        return localPath
    }

    func localURL(for segmentId: String) -> URL? {
        let path = cacheDirectory.appendingPathComponent("\(segmentId).mp3")
        return fileManager.fileExists(atPath: path.path) ? path : nil
    }
}
```

## Background App Refresh

```swift
// Register in AppDelegate
func application(_ application: UIApplication, didFinishLaunchingWithOptions options: ...) {
    BGTaskScheduler.shared.register(
        forTaskWithIdentifier: "com.roadcast.content-sync",
        using: nil
    ) { task in
        self.handleContentSync(task: task as! BGProcessingTask)
    }
}

func scheduleContentSync() {
    let request = BGProcessingTaskRequest(identifier: "com.roadcast.content-sync")
    request.requiresNetworkConnectivity = true
    request.requiresExternalPower = false
    try? BGTaskScheduler.shared.submit(request)
}
```

## Rules

1. NEVER show "No internet" errors during navigation or podcast playback
2. NEVER block the UI waiting for network responses (optimistic UI)
3. ALWAYS write locally first, sync later
4. ALWAYS check cache before making a network request
5. ALWAYS handle Core Data migrations gracefully (lightweight preferred)
6. NEVER store large blobs (audio, images) in Core Data — use FileManager + reference
7. ALWAYS respect user's storage budget setting
8. ALWAYS throttle background sync on Low Power Mode

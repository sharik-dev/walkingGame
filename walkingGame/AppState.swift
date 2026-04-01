import Foundation
import CoreLocation
import Combine

extension Notification.Name {
    static let checkpointReached = Notification.Name("checkpointReached")
}

final class AppState: ObservableObject {
    // Steps
    @Published var totalSteps: Int
    @Published var todaySteps: Int = 0

    // World travel
    @Published var virtualDistanceKm: Double
    @Published var playerCoordinate: CLLocationCoordinate2D
    @Published var trail: [CLLocationCoordinate2D] = []
    @Published var currentSegmentIndex: Int
    @Published var segmentProgress: Double

    // Gamification
    @Published var dailyStreak: Int
    @Published var completedCheckpoints: [String]
    @Published var isInTransit = false

    private static let strideMeters: Double = 0.762
    static let stepMultiplier: Double = 10
    static let worldCircumferenceKm: Double = 40_075

    // MARK: - Init

    init() {
        let savedSteps    = UserDefaults.standard.integer(forKey: "totalSteps")
        let savedSeg      = UserDefaults.standard.integer(forKey: "segmentIndex")
        let savedProg     = UserDefaults.standard.double(forKey: "segmentProgress")
        let savedStreak   = UserDefaults.standard.integer(forKey: "dailyStreak")
        let savedCP       = UserDefaults.standard.stringArray(forKey: "completedCheckpoints") ?? []
        let lat           = UserDefaults.standard.double(forKey: "playerLat")
        let lon           = UserDefaults.standard.double(forKey: "playerLon")

        totalSteps           = savedSteps
        currentSegmentIndex  = savedSeg
        segmentProgress      = savedProg
        dailyStreak          = savedStreak
        completedCheckpoints = savedCP
        virtualDistanceKm    = Double(savedSteps) * AppState.strideMeters * AppState.stepMultiplier / 1000.0
        playerCoordinate     = (lat != 0 || lon != 0)
            ? CLLocationCoordinate2D(latitude: lat, longitude: lon)
            : WorldRoute.shared.checkpoints[0].coordinate
    }

    // MARK: - Computed

    var worldProgress: Double { min(virtualDistanceKm / AppState.worldCircumferenceKm, 1.0) }

    var nextCheckpoint: Checkpoint? {
        WorldRoute.shared.segments[safe: currentSegmentIndex]?.to
    }

    var distanceToNextCheckpointKm: Double {
        guard currentSegmentIndex < WorldRoute.shared.segments.count else { return 0 }
        return WorldRoute.shared.segments[currentSegmentIndex].distanceKm * (1.0 - segmentProgress)
    }

    // MARK: - Step

    func addValidatedStep() {
        totalSteps += 1
        todaySteps += 1
        let virtualMeters = AppState.strideMeters * AppState.stepMultiplier
        virtualDistanceKm += virtualMeters / 1000.0
        advance(meters: virtualMeters)
        persist()
    }

    // MARK: - Route advancement

    private func advance(meters: Double) {
        let segs = WorldRoute.shared.segments
        guard !segs.isEmpty else { return }
        let idx = currentSegmentIndex % segs.count
        let seg = segs[idx]
        let segMeters = seg.distanceKm * 1000.0
        segmentProgress += meters / segMeters

        if segmentProgress >= 1.0 {
            let overflow = (segmentProgress - 1.0) * segMeters
            segmentProgress = 0

            if !completedCheckpoints.contains(seg.to.id) {
                completedCheckpoints.append(seg.to.id)
                NotificationCenter.default.post(name: .checkpointReached, object: seg.to)
            }

            currentSegmentIndex = (idx + 1) % segs.count
            if segs[currentSegmentIndex].isOcean {
                DispatchQueue.main.async { self.isInTransit = true }
            }
            if overflow > 0 { advance(meters: overflow) }
        } else {
            interpolatePosition()
        }
    }

    private func interpolatePosition() {
        let segs = WorldRoute.shared.segments
        guard !segs.isEmpty else { return }
        let seg = segs[currentSegmentIndex % segs.count]
        let t = segmentProgress
        let lat = seg.from.coordinate.latitude  + (seg.to.coordinate.latitude  - seg.from.coordinate.latitude)  * t
        let lon = seg.from.coordinate.longitude + (seg.to.coordinate.longitude - seg.from.coordinate.longitude) * t
        playerCoordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
        trail.append(playerCoordinate)
        if trail.count > 500 { trail.removeFirst(50) }
    }

    // MARK: - Setup

    func setStartCoordinate(_ coordinate: CLLocationCoordinate2D) {
        playerCoordinate = coordinate
        UserDefaults.standard.set(coordinate.latitude,  forKey: "playerLat")
        UserDefaults.standard.set(coordinate.longitude, forKey: "playerLon")
    }

    // MARK: - Persistence

    private func persist() {
        UserDefaults.standard.set(totalSteps,            forKey: "totalSteps")
        UserDefaults.standard.set(currentSegmentIndex,   forKey: "segmentIndex")
        UserDefaults.standard.set(segmentProgress,       forKey: "segmentProgress")
        UserDefaults.standard.set(playerCoordinate.latitude,  forKey: "playerLat")
        UserDefaults.standard.set(playerCoordinate.longitude, forKey: "playerLon")
        UserDefaults.standard.set(completedCheckpoints,  forKey: "completedCheckpoints")
    }
}

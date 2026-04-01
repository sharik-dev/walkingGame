import CoreMotion
import SwiftUI

final class PedometerService: ObservableObject {
    private let pedometer = CMPedometer()
    private let motion    = CMMotionManager()

    @Published var stepValidated = false

    var onValidatedStep: (() -> Void)?

    private var lastMag: Double = 0
    private var cooldown = false
    private let threshold: Double = 1.15

    // MARK: - Lifecycle

    func startTracking() {
        startPedometer()
        startAccelerometer()
    }

    func stopTracking() {
        pedometer.stopUpdates()
        motion.stopAccelerometerUpdates()
    }

    func queryToday(completion: @escaping (Int) -> Void) {
        guard CMPedometer.isStepCountingAvailable() else { completion(0); return }
        let start = Calendar.current.startOfDay(for: Date())
        pedometer.queryPedometerData(from: start, to: Date()) { data, _ in
            DispatchQueue.main.async { completion(Int(data?.numberOfSteps ?? 0)) }
        }
    }

    // MARK: - Private

    private func startPedometer() {
        guard CMPedometer.isStepCountingAvailable() else { return }
        pedometer.startUpdates(from: Date()) { _, _ in }
    }

    private func startAccelerometer() {
        guard motion.isAccelerometerAvailable else { return }
        motion.accelerometerUpdateInterval = 0.05
        motion.startAccelerometerUpdates(to: .main) { [weak self] data, _ in
            guard let data, let self else { return }
            let mag = sqrt(data.acceleration.x * data.acceleration.x
                         + data.acceleration.y * data.acceleration.y
                         + data.acceleration.z * data.acceleration.z)
            if mag > self.threshold && self.lastMag <= self.threshold && !self.cooldown {
                self.fireStep()
            }
            self.lastMag = mag
        }
    }

    private func fireStep() {
        cooldown = true
        withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) { stepValidated = true }
        onValidatedStep?()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            withAnimation { self.stepValidated = false }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { self.cooldown = false }
    }
}

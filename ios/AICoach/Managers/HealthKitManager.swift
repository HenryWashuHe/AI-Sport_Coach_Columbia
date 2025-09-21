import Foundation
import HealthKit

final class HealthKitManager: NSObject {
    static let shared = HealthKitManager()

    private let healthStore = HKHealthStore()
    private var session: HKWorkoutSession?
    private var builder: HKLiveWorkoutBuilder?

    private var hrUpdateHandler: ((Double) -> Void)?

    func requestAuthorization(completion: @escaping (Bool, Error?) -> Void) {
        guard HKHealthStore.isHealthDataAvailable() else {
            completion(false, nil)
            return
        }
        let readTypes: Set = [
            HKObjectType.quantityType(forIdentifier: .heartRate)!,
            HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!,
            HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!,
            HKObjectType.workoutType()
        ]
        let shareTypes: Set = [
            HKObjectType.workoutType()
        ]
        healthStore.requestAuthorization(toShare: shareTypes, read: readTypes, completion: completion)
    }

    func startWorkout(activity: HKWorkoutActivityType = .functionalStrengthTraining,
                      location: HKWorkoutSessionLocationType = .indoor,
                      hrHandler: @escaping (Double) -> Void,
                      completion: @escaping (Error?) -> Void) {
        hrUpdateHandler = hrHandler
        let config = HKWorkoutConfiguration()
        config.activityType = activity
        config.locationType = location
        do {
            session = try HKWorkoutSession(healthStore: healthStore, configuration: config)
            builder = session?.associatedWorkoutBuilder()
            builder?.dataSource = HKLiveWorkoutDataSource(healthStore: healthStore, workoutConfiguration: config)
            session?.delegate = self
            builder?.delegate = self
            session?.startActivity(with: Date())
            builder?.beginCollection(withStart: Date()) { success, error in
                completion(error)
            }
        } catch {
            completion(error)
        }
    }

    func endWorkout(completion: @escaping (Error?) -> Void) {
        guard let session, let builder else { completion(nil); return }
        session.end()
        builder.endCollection(withEnd: Date()) { success, error in
            guard error == nil else { completion(error); return }
            builder.finishWorkout { _, err in
                completion(err)
            }
        }
    }
}

extension HealthKitManager: HKWorkoutSessionDelegate {
    func workoutSession(_ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState, from fromState: HKWorkoutSessionState, date: Date) {}
    func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {}
}

extension HealthKitManager: HKLiveWorkoutBuilderDelegate {
    func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {}

    func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder, didCollectDataOf types: Set<HKSampleType>) {
        guard let hrType = HKObjectType.quantityType(forIdentifier: .heartRate), types.contains(hrType) else { return }
        if let stats = workoutBuilder.statistics(for: hrType), let value = stats.mostRecentQuantity()?.doubleValue(for: HKUnit.count().unitDivided(by: .minute())) {
            hrUpdateHandler?(value)
        }
    }
}

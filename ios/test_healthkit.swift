#!/usr/bin/env swift

import Foundation
import HealthKit

// Test HealthKit Manager functionality
class HealthKitTester {
    let healthStore = HKHealthStore()
    
    func testPermissions() {
        print("🏥 Testing HealthKit Permissions...")
        
        guard HKHealthStore.isHealthDataAvailable() else {
            print("❌ HealthKit not available on this device")
            return
        }
        
        let readTypes: Set = [
            HKObjectType.quantityType(forIdentifier: .heartRate)!,
            HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!
        ]
        
        healthStore.requestAuthorization(toShare: [], read: readTypes) { success, error in
            if success {
                print("✅ HealthKit permissions granted")
                self.testHeartRateQuery()
            } else {
                print("❌ HealthKit permissions denied: \(error?.localizedDescription ?? "Unknown error")")
            }
        }
    }
    
    func testHeartRateQuery() {
        print("❤️ Testing Heart Rate Query...")
        
        guard let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate) else {
            print("❌ Heart rate type not available")
            return
        }
        
        let query = HKSampleQuery(
            sampleType: heartRateType,
            predicate: nil,
            limit: 5,
            sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]
        ) { query, samples, error in
            
            if let error = error {
                print("❌ Heart rate query failed: \(error.localizedDescription)")
                return
            }
            
            guard let heartRateSamples = samples as? [HKQuantitySample] else {
                print("⚠️ No heart rate samples found")
                return
            }
            
            print("✅ Found \(heartRateSamples.count) heart rate samples:")
            for sample in heartRateSamples.prefix(3) {
                let bpm = sample.quantity.doubleValue(for: HKUnit.count().unitDivided(by: .minute()))
                print("   📊 HR: \(Int(bpm)) BPM at \(sample.startDate)")
            }
        }
        
        healthStore.execute(query)
    }
    
    func simulateLiveWorkout() {
        print("🏃 Simulating Live Workout with Mock HR Data...")
        
        // Simulate realistic heart rate progression during workout
        let workoutHRProgression = [110, 115, 125, 135, 145, 150, 155, 160, 158, 150, 140, 130]
        
        for (index, hr) in workoutHRProgression.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.5) {
                print("   ❤️ Live HR Update: \(hr) BPM (rep \(index + 1))")
                
                // Simulate coaching based on HR
                if hr > 160 {
                    print("   🗣️ Coaching Cue: 'Heart rate high - take a break!'")
                } else if hr < 120 {
                    print("   🗣️ Coaching Cue: 'Pick up the pace!'")
                }
            }
        }
        
        print("✅ Live HR simulation started - watch for updates above")
    }
}

// Run tests
let tester = HealthKitTester()

print("🧪 HealthKit Integration Test")
print(String(repeating: "=", count: 40))

// Test 1: Permissions
tester.testPermissions()

// Test 2: Live workout simulation
DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
    tester.simulateLiveWorkout()
}

// Keep script running to see async results
RunLoop.main.run(until: Date().addingTimeInterval(10))

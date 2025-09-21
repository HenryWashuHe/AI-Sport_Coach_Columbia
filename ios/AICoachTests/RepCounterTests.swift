import XCTest
@testable import AICoach

final class RepCounterTests: XCTestCase {
    var repCounter: RepCounter!
    var completedReps: [Int] = []
    
    override func setUp() {
        super.setUp()
        repCounter = RepCounter()
        completedReps = []
        
        repCounter.onRepCompleted = { [weak self] count in
            self?.completedReps.append(count)
        }
    }
    
    override func tearDown() {
        repCounter = nil
        completedReps = []
        super.tearDown()
    }
    
    func testRepCountingCycle() {
        // Simulate a complete squat rep cycle
        
        // Standing position (shallow depth, low velocity)
        let standingFeatures = SquatFeatures(
            hipKneeAngle: 170,
            kneeAnkleAngle: 180,
            depthPercentage: 0.1,
            kneeValgusAngle: 5,
            tempo: 0.005,
            timestamp: 0.0
        )
        repCounter.processFrame(features: standingFeatures)
        XCTAssertEqual(repCounter.getCurrentRep(), 0)
        
        // Descending (increasing depth, positive velocity)
        let descendingFeatures = SquatFeatures(
            hipKneeAngle: 140,
            kneeAnkleAngle: 160,
            depthPercentage: 0.4,
            kneeValgusAngle: 8,
            tempo: 0.5,
            timestamp: 1.0
        )
        for _ in 0..<5 {
            repCounter.processFrame(features: descendingFeatures)
        }
        
        // Bottom position (high depth, near-zero velocity)
        let bottomFeatures = SquatFeatures(
            hipKneeAngle: 90,
            kneeAnkleAngle: 120,
            depthPercentage: 0.8,
            kneeValgusAngle: 10,
            tempo: 0.005,
            timestamp: 2.0
        )
        for _ in 0..<5 {
            repCounter.processFrame(features: bottomFeatures)
        }
        
        // Ascending (decreasing depth, positive velocity)
        let ascendingFeatures = SquatFeatures(
            hipKneeAngle: 140,
            kneeAnkleAngle: 160,
            depthPercentage: 0.4,
            kneeValgusAngle: 8,
            tempo: 0.5,
            timestamp: 3.0
        )
        for _ in 0..<5 {
            repCounter.processFrame(features: ascendingFeatures)
        }
        
        // Return to standing (low depth, low velocity)
        for _ in 0..<5 {
            repCounter.processFrame(features: standingFeatures)
        }
        
        // Should have completed 1 rep
        XCTAssertEqual(completedReps.count, 1)
        XCTAssertEqual(completedReps.first, 1)
        XCTAssertEqual(repCounter.getCurrentRep(), 1)
    }
    
    func testInvalidRepNotCounted() {
        // Simulate shallow squat that shouldn't count
        
        let shallowFeatures = SquatFeatures(
            hipKneeAngle: 160,
            kneeAnkleAngle: 170,
            depthPercentage: 0.2, // Below threshold
            kneeValgusAngle: 5,
            tempo: 0.3,
            timestamp: 0.0
        )
        
        // Process several frames of shallow movement
        for i in 0..<20 {
            repCounter.processFrame(features: shallowFeatures)
        }
        
        // Should not count as a rep
        XCTAssertEqual(completedReps.count, 0)
        XCTAssertEqual(repCounter.getCurrentRep(), 0)
    }
    
    func testReset() {
        // First, complete a rep
        testRepCountingCycle()
        
        // Reset counter
        repCounter.reset()
        
        XCTAssertEqual(repCounter.getCurrentRep(), 0)
    }
}

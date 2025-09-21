import XCTest
@testable import AICoach

final class CoachingEngineTests: XCTestCase {
    var coachingEngine: CoachingEngine!
    var triggeredCues: [CoachingCue] = []
    
    override func setUp() {
        super.setUp()
        coachingEngine = CoachingEngine()
        triggeredCues = []
        
        coachingEngine.onCueTriggered = { [weak self] cue in
            self?.triggeredCues.append(cue)
        }
    }
    
    override func tearDown() {
        coachingEngine = nil
        triggeredCues = []
        super.tearDown()
    }
    
    func testDepthCue() {
        let shallowFeatures = SquatFeatures(
            hipKneeAngle: 160,
            kneeAnkleAngle: 170,
            depthPercentage: 0.2, // Below 40% threshold
            kneeValgusAngle: 5,
            tempo: 1.0,
            timestamp: 0.0
        )
        
        coachingEngine.analyzeForm(features: shallowFeatures, heartRate: 120)
        
        XCTAssertTrue(triggeredCues.contains(.depthTooShallow))
    }
    
    func testKneeValgusCue() {
        let valgusFeatures = SquatFeatures(
            hipKneeAngle: 120,
            kneeAnkleAngle: 140,
            depthPercentage: 0.6,
            kneeValgusAngle: 20, // Above 15 degree threshold
            tempo: 1.0,
            timestamp: 0.0
        )
        
        coachingEngine.analyzeForm(features: valgusFeatures, heartRate: 120)
        
        XCTAssertTrue(triggeredCues.contains(.kneeValgus))
    }
    
    func testTempoFastCue() {
        let fastFeatures = SquatFeatures(
            hipKneeAngle: 120,
            kneeAnkleAngle: 140,
            depthPercentage: 0.6,
            kneeValgusAngle: 5,
            tempo: 4.0, // Above 3.0 threshold
            timestamp: 0.0
        )
        
        coachingEngine.analyzeForm(features: fastFeatures, heartRate: 120)
        
        XCTAssertTrue(triggeredCues.contains(.tempoTooFast))
    }
    
    func testTempoSlowCue() {
        let slowFeatures = SquatFeatures(
            hipKneeAngle: 120,
            kneeAnkleAngle: 140,
            depthPercentage: 0.6,
            kneeValgusAngle: 5,
            tempo: 0.3, // Below 0.5 threshold
            timestamp: 0.0
        )
        
        coachingEngine.analyzeForm(features: slowFeatures, heartRate: 120)
        
        XCTAssertTrue(triggeredCues.contains(.tempoTooSlow))
    }
    
    func testHeartRateCue() {
        let normalFeatures = SquatFeatures(
            hipKneeAngle: 120,
            kneeAnkleAngle: 140,
            depthPercentage: 0.6,
            kneeValgusAngle: 5,
            tempo: 1.0,
            timestamp: 0.0
        )
        
        coachingEngine.analyzeForm(features: normalFeatures, heartRate: 190) // Above 180 threshold
        
        XCTAssertTrue(triggeredCues.contains(.heartRateTooHigh))
    }
    
    func testGoodFormCue() {
        let perfectFeatures = SquatFeatures(
            hipKneeAngle: 120,
            kneeAnkleAngle: 140,
            depthPercentage: 0.7, // Good depth
            kneeValgusAngle: 5, // Good alignment
            tempo: 1.5, // Good tempo
            timestamp: 0.0
        )
        
        coachingEngine.analyzeForm(features: perfectFeatures, heartRate: 140) // Normal HR
        
        XCTAssertTrue(triggeredCues.contains(.goodForm))
    }
    
    func testCueDebouncing() {
        let shallowFeatures = SquatFeatures(
            hipKneeAngle: 160,
            kneeAnkleAngle: 170,
            depthPercentage: 0.2,
            kneeValgusAngle: 5,
            tempo: 1.0,
            timestamp: 0.0
        )
        
        // First trigger
        coachingEngine.analyzeForm(features: shallowFeatures, heartRate: 120)
        XCTAssertEqual(triggeredCues.filter { $0 == .depthTooShallow }.count, 1)
        
        // Second trigger immediately (should be debounced)
        let immediateFeatures = SquatFeatures(
            hipKneeAngle: 160,
            kneeAnkleAngle: 170,
            depthPercentage: 0.2,
            kneeValgusAngle: 5,
            tempo: 1.0,
            timestamp: 1.0 // Only 1 second later
        )
        coachingEngine.analyzeForm(features: immediateFeatures, heartRate: 120)
        XCTAssertEqual(triggeredCues.filter { $0 == .depthTooShallow }.count, 1) // Still only 1
        
        // Third trigger after debounce period
        let laterFeatures = SquatFeatures(
            hipKneeAngle: 160,
            kneeAnkleAngle: 170,
            depthPercentage: 0.2,
            kneeValgusAngle: 5,
            tempo: 1.0,
            timestamp: 13.0 // 13 seconds later (past 12s debounce)
        )
        coachingEngine.analyzeForm(features: laterFeatures, heartRate: 120)
        XCTAssertEqual(triggeredCues.filter { $0 == .depthTooShallow }.count, 2) // Now 2
    }
}

extension CoachingCue: Equatable {
    public static func == (lhs: CoachingCue, rhs: CoachingCue) -> Bool {
        switch (lhs, rhs) {
        case (.depthTooShallow, .depthTooShallow),
             (.kneeValgus, .kneeValgus),
             (.tempoTooFast, .tempoTooFast),
             (.tempoTooSlow, .tempoTooSlow),
             (.heartRateTooHigh, .heartRateTooHigh),
             (.goodForm, .goodForm):
            return true
        default:
            return false
        }
    }
}

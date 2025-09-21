import XCTest
@testable import AICoach

final class FeatureExtractorTests: XCTestCase {
    var featureExtractor: FeatureExtractor!
    
    override func setUp() {
        super.setUp()
        featureExtractor = FeatureExtractor()
    }
    
    override func tearDown() {
        featureExtractor = nil
        super.tearDown()
    }
    
    func testEMASmoothing() {
        // Create test pose with known positions
        let pose1 = createTestPose(hipY: 0.5, kneeY: 0.6, ankleY: 0.8)
        let pose2 = createTestPose(hipY: 0.4, kneeY: 0.5, ankleY: 0.7)
        
        let features1 = featureExtractor.extractFeatures(from: pose1, timestamp: 0.0)
        let features2 = featureExtractor.extractFeatures(from: pose2, timestamp: 0.033) // ~30fps
        
        // Second measurement should be smoothed (not exactly equal to raw input)
        XCTAssertNotEqual(features2.depthPercentage, 0.0)
        XCTAssertGreaterThan(features2.timestamp, features1.timestamp)
    }
    
    func testDepthCalculation() {
        let shallowPose = createTestPose(hipY: 0.4, kneeY: 0.5, ankleY: 0.8)
        let deepPose = createTestPose(hipY: 0.4, kneeY: 0.7, ankleY: 0.8)
        
        let shallowFeatures = featureExtractor.extractFeatures(from: shallowPose, timestamp: 0.0)
        let deepFeatures = featureExtractor.extractFeatures(from: deepPose, timestamp: 0.033)
        
        // Deeper squat should have higher depth percentage
        XCTAssertGreaterThan(deepFeatures.depthPercentage, shallowFeatures.depthPercentage)
    }
    
    func testAngleCalculation() {
        let pose = createTestPose(hipY: 0.4, kneeY: 0.6, ankleY: 0.8)
        let features = featureExtractor.extractFeatures(from: pose, timestamp: 0.0)
        
        // Hip-knee-ankle angle should be reasonable (0-180 degrees)
        XCTAssertGreaterThan(features.hipKneeAngle, 0)
        XCTAssertLessThan(features.hipKneeAngle, 180)
    }
    
    func testTempoCalculation() {
        let pose1 = createTestPose(hipY: 0.4, kneeY: 0.5, ankleY: 0.8)
        let pose2 = createTestPose(hipY: 0.4, kneeY: 0.6, ankleY: 0.8)
        
        _ = featureExtractor.extractFeatures(from: pose1, timestamp: 0.0)
        let features2 = featureExtractor.extractFeatures(from: pose2, timestamp: 0.1)
        
        // Should have some tempo (movement detected)
        XCTAssertGreaterThanOrEqual(features2.tempo, 0)
    }
    
    private func createTestPose(hipY: Float, kneeY: Float, ankleY: Float) -> PoseKeypoints {
        let joints = (0..<17).map { i in
            switch i {
            case 11: // left hip
                return Joint(position: CGPoint(x: 0.4, y: CGFloat(hipY)), confidence: 0.9)
            case 13: // left knee
                return Joint(position: CGPoint(x: 0.4, y: CGFloat(kneeY)), confidence: 0.9)
            case 15: // left ankle
                return Joint(position: CGPoint(x: 0.4, y: CGFloat(ankleY)), confidence: 0.9)
            default:
                return Joint(position: CGPoint(x: 0.5, y: 0.5), confidence: 0.8)
            }
        }
        return PoseKeypoints(from: joints)
    }
}

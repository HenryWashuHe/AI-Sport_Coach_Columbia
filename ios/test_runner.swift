#!/usr/bin/env swift

import Foundation

// Simple test framework for Swift
class TestRunner {
    var passedTests = 0
    var failedTests = 0
    
    func assert(_ condition: Bool, _ message: String = "") {
        if condition {
            passedTests += 1
            print("✅ PASS: \(message)")
        } else {
            failedTests += 1
            print("❌ FAIL: \(message)")
        }
    }
    
    func assertEqual<T: Equatable>(_ a: T, _ b: T, _ message: String = "") {
        assert(a == b, message.isEmpty ? "\(a) == \(b)" : message)
    }
    
    func assertNotEqual<T: Equatable>(_ a: T, _ b: T, _ message: String = "") {
        assert(a != b, message.isEmpty ? "\(a) != \(b)" : message)
    }
    
    func assertGreaterThan<T: Comparable>(_ a: T, _ b: T, _ message: String = "") {
        assert(a > b, message.isEmpty ? "\(a) > \(b)" : message)
    }
    
    func printResults() {
        print("\n=== Test Results ===")
        print("Passed: \(passedTests)")
        print("Failed: \(failedTests)")
        print("Total: \(passedTests + failedTests)")
        
        if failedTests == 0 {
            print("🎉 All tests passed!")
        } else {
            print("💥 \(failedTests) test(s) failed")
        }
    }
}

// Mock implementations for testing
struct Joint {
    let position: CGPoint
    let confidence: Float
}

struct PoseKeypoints {
    let nose: Joint
    let leftEye: Joint
    let rightEye: Joint
    let leftEar: Joint
    let rightEar: Joint
    let leftShoulder: Joint
    let rightShoulder: Joint
    let leftElbow: Joint
    let rightElbow: Joint
    let leftWrist: Joint
    let rightWrist: Joint
    let leftHip: Joint
    let rightHip: Joint
    let leftKnee: Joint
    let rightKnee: Joint
    let leftAnkle: Joint
    let rightAnkle: Joint
    
    init(from array: [Joint]) {
        guard array.count >= 17 else {
            fatalError("Invalid keypoints array")
        }
        nose = array[0]
        leftEye = array[1]
        rightEye = array[2]
        leftEar = array[3]
        rightEar = array[4]
        leftShoulder = array[5]
        rightShoulder = array[6]
        leftElbow = array[7]
        rightElbow = array[8]
        leftWrist = array[9]
        rightWrist = array[10]
        leftHip = array[11]
        rightHip = array[12]
        leftKnee = array[13]
        rightKnee = array[14]
        leftAnkle = array[15]
        rightAnkle = array[16]
    }
}

struct SquatFeatures {
    let hipKneeAngle: Float
    let kneeAnkleAngle: Float
    let depthPercentage: Float
    let kneeValgusAngle: Float
    let tempo: Float
    let timestamp: TimeInterval
}

enum CoachingCue: Equatable {
    case depthTooShallow
    case kneeValgus
    case tempoTooFast
    case tempoTooSlow
    case heartRateTooHigh
    case goodForm
}

// Test functions
func testJointCreation(_ runner: TestRunner) {
    print("\n--- Testing Joint Creation ---")
    
    let joint = Joint(position: CGPoint(x: 0.5, y: 0.6), confidence: 0.9)
    runner.assertEqual(joint.position.x, 0.5, "Joint X position")
    runner.assertEqual(joint.position.y, 0.6, "Joint Y position")
    runner.assertEqual(joint.confidence, 0.9, "Joint confidence")
}

func testPoseKeypointsCreation(_ runner: TestRunner) {
    print("\n--- Testing PoseKeypoints Creation ---")
    
    let joints = (0..<17).map { i in
        Joint(position: CGPoint(x: Double(i) * 0.1, y: 0.5), confidence: 0.8)
    }
    
    let pose = PoseKeypoints(from: joints)
    runner.assertEqual(pose.nose.position.x, 0.0, "Nose position")
    runner.assertEqual(pose.leftHip.position.x, 1.1, "Left hip position")
    runner.assertEqual(pose.rightAnkle.confidence, 0.8, "Right ankle confidence")
}

func testSquatFeaturesCreation(_ runner: TestRunner) {
    print("\n--- Testing SquatFeatures Creation ---")
    
    let features = SquatFeatures(
        hipKneeAngle: 120.5,
        kneeAnkleAngle: 140.0,
        depthPercentage: 0.75,
        kneeValgusAngle: 8.5,
        tempo: 1.2,
        timestamp: 123.456
    )
    
    runner.assertEqual(features.hipKneeAngle, 120.5, "Hip-knee angle")
    runner.assertEqual(features.depthPercentage, 0.75, "Depth percentage")
    runner.assertEqual(features.tempo, 1.2, "Tempo")
}

func testCoachingCueEquality(_ runner: TestRunner) {
    print("\n--- Testing CoachingCue Equality ---")
    
    runner.assertEqual(CoachingCue.depthTooShallow, CoachingCue.depthTooShallow, "Same cue equality")
    runner.assertNotEqual(CoachingCue.depthTooShallow, CoachingCue.kneeValgus, "Different cue inequality")
    runner.assertEqual(CoachingCue.goodForm, CoachingCue.goodForm, "Good form cue equality")
}

func testAngleCalculation(_ runner: TestRunner) {
    print("\n--- Testing Angle Calculation ---")
    
    // Test 90-degree angle
    let p1 = CGPoint(x: 0, y: 1)  // Above
    let p2 = CGPoint(x: 0, y: 0)  // Center
    let p3 = CGPoint(x: 1, y: 0)  // Right
    
    let v1x = Float(p1.x - p2.x)
    let v1y = Float(p1.y - p2.y)
    let v2x = Float(p3.x - p2.x)
    let v2y = Float(p3.y - p2.y)
    
    let dot = v1x * v2x + v1y * v2y
    let mag1 = sqrt(v1x * v1x + v1y * v1y)
    let mag2 = sqrt(v2x * v2x + v2y * v2y)
    
    let cosAngle = dot / (mag1 * mag2)
    let angle = acos(cosAngle) * 180.0 / Float.pi
    
    // Should be approximately 90 degrees
    runner.assert(abs(angle - 90.0) < 0.1, "90-degree angle calculation")
}

func testDepthCalculation(_ runner: TestRunner) {
    print("\n--- Testing Depth Calculation ---")
    
    // Simulate shallow vs deep squat
    let shallowHipY: Float = 0.4
    let shallowKneeY: Float = 0.5
    let deepHipY: Float = 0.4
    let deepKneeY: Float = 0.7
    
    let shallowDistance = abs(shallowHipY - shallowKneeY)
    let deepDistance = abs(deepHipY - deepKneeY)
    
    runner.assertGreaterThan(deepDistance, shallowDistance, "Deep squat has greater hip-knee distance")
}

// Main test execution
func runAllTests() {
    let runner = TestRunner()
    
    print("🏃‍♂️ Running iOS AI Coach Tests...")
    
    testJointCreation(runner)
    testPoseKeypointsCreation(runner)
    testSquatFeaturesCreation(runner)
    testCoachingCueEquality(runner)
    testAngleCalculation(runner)
    testDepthCalculation(runner)
    
    runner.printResults()
    
    exit(runner.failedTests == 0 ? 0 : 1)
}

// Run tests
runAllTests()

#!/usr/bin/env swift

import Foundation
import Vision
import CoreImage
import AVFoundation

// Test Pose Detection functionality
class PoseDetectionTester {
    
    func testAppleVisionPose() {
        print("🤖 Testing Apple Vision Pose Detection...")
        
        // Create a mock image for testing (you'd normally use camera frame)
        let mockImage = createMockImage()
        
        let request = VNDetectHumanBodyPoseRequest { request, error in
            if let error = error {
                print("❌ Pose detection failed: \(error.localizedDescription)")
                return
            }
            
            guard let observations = request.results as? [VNHumanBodyPoseObservation],
                  let bodyPose = observations.first else {
                print("⚠️ No pose detected in mock image")
                return
            }
            
            self.processPoseResults(bodyPose)
        }
        
        let handler = VNImageRequestHandler(cgImage: mockImage, options: [:])
        
        do {
            try handler.perform([request])
        } catch {
            print("❌ Failed to perform pose detection: \(error)")
        }
    }
    
    func processPoseResults(_ bodyPose: VNHumanBodyPoseObservation) {
        print("✅ Pose detected! Processing joint coordinates...")
        
        do {
            let recognizedPoints = try bodyPose.recognizedPoints(.all)
            
            // Key joints for squat analysis
            let keyJoints: [VNHumanBodyPoseObservation.JointName] = [
                .leftHip, .rightHip, .leftKnee, .rightKnee, .leftAnkle, .rightAnkle
            ]
            
            print("   📍 Key Joint Coordinates:")
            for joint in keyJoints {
                if let point = recognizedPoints[joint], point.confidence > 0.3 {
                    let x = point.location.x
                    let y = 1.0 - point.location.y  // Flip Y coordinate
                    print("     \(joint.rawValue): (\(String(format: "%.3f", x)), \(String(format: "%.3f", y))) confidence: \(String(format: "%.2f", point.confidence))")
                }
            }
            
            // Simulate squat analysis
            if let leftHip = recognizedPoints[.leftHip],
               let leftKnee = recognizedPoints[.leftKnee],
               let leftAnkle = recognizedPoints[.leftAnkle] {
                
                let depth = calculateSquatDepth(hip: leftHip, knee: leftKnee, ankle: leftAnkle)
                print("   🏋️ Squat Analysis:")
                print("     Depth: \(String(format: "%.1f", depth * 100))%")
                
                // Coaching feedback based on depth
                if depth < 0.4 {
                    print("     🗣️ Coaching Cue: 'Go deeper!'")
                } else if depth > 0.8 {
                    print("     🗣️ Coaching Cue: 'Great depth!'")
                } else {
                    print("     🗣️ Coaching Cue: 'Good form!'")
                }
            }
            
        } catch {
            print("❌ Failed to extract joint points: \(error)")
        }
    }
    
    func calculateSquatDepth(hip: VNRecognizedPoint, knee: VNRecognizedPoint, ankle: VNRecognizedPoint) -> Float {
        // Simplified depth calculation based on hip-knee distance
        let hipY = Float(hip.location.y)
        let kneeY = Float(knee.location.y)
        let ankleY = Float(ankle.location.y)
        
        // Calculate relative depth (0 = standing, 1 = deep squat)
        let hipKneeDistance = abs(hipY - kneeY)
        let kneeAnkleDistance = abs(kneeY - ankleY)
        
        // Simple ratio-based depth calculation
        let depth = min(1.0, hipKneeDistance / (kneeAnkleDistance + 0.1))
        return depth
    }
    
    func createMockImage() -> CGImage {
        // Create a simple test image (in real app, this would be camera frame)
        let size = CGSize(width: 300, height: 400)
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let context = CGContext(data: nil, width: Int(size.width), height: Int(size.height), 
                               bitsPerComponent: 8, bytesPerRow: 0, space: colorSpace, 
                               bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        
        // Fill with blue background
        context.setFillColor(CGColor(red: 0.2, green: 0.4, blue: 0.8, alpha: 1.0))
        context.fill(CGRect(origin: .zero, size: size))
        
        // Add some basic shapes to simulate a person
        context.setFillColor(CGColor(red: 0.9, green: 0.7, blue: 0.5, alpha: 1.0))
        
        // Head
        context.fillEllipse(in: CGRect(x: 140, y: 50, width: 20, height: 30))
        
        // Body
        context.fill(CGRect(x: 145, y: 80, width: 10, height: 60))
        
        // Arms
        context.fill(CGRect(x: 120, y: 90, width: 40, height: 8))
        
        // Legs
        context.fill(CGRect(x: 140, y: 140, width: 8, height: 40))
        context.fill(CGRect(x: 152, y: 140, width: 8, height: 40))
        
        return context.makeImage()!
    }
    
    func testRepCounting() {
        print("🔢 Testing Rep Counting Logic...")
        
        // Simulate squat movement with depth values
        let squatMovement: [(depth: Float, phase: String)] = [
            (0.1, "standing"),
            (0.2, "starting descent"),
            (0.4, "quarter squat"),
            (0.6, "half squat"),
            (0.8, "deep squat"),
            (0.9, "bottom position"),
            (0.8, "starting ascent"),
            (0.6, "half way up"),
            (0.4, "quarter up"),
            (0.2, "almost standing"),
            (0.1, "standing - REP COMPLETE")
        ]
        
        var repCount = 0
        var previousDepth: Float = 0.1
        var inSquat = false
        
        for (index, movement) in squatMovement.enumerated() {
            let depth = movement.depth
            let phase = movement.phase
            
            // Simple rep counting logic
            if !inSquat && depth > 0.3 {
                inSquat = true
                print("   📉 Descent detected at depth \(String(format: "%.1f", depth * 100))%")
            }
            
            if inSquat && depth < 0.3 && previousDepth > 0.3 {
                repCount += 1
                inSquat = false
                print("   📈 Rep \(repCount) completed! (ascent from \(String(format: "%.1f", previousDepth * 100))% to \(String(format: "%.1f", depth * 100))%)")
                
                // Coaching feedback
                if previousDepth > 0.7 {
                    print("     🗣️ Coaching Cue: 'Great depth!'")
                } else {
                    print("     🗣️ Coaching Cue: 'Go deeper next time!'")
                }
            }
            
            print("   Step \(index + 1): \(phase) - Depth: \(String(format: "%.1f", depth * 100))%")
            previousDepth = depth
            
            // Simulate timing
            usleep(200000) // 0.2 second delay
        }
        
        print("✅ Rep counting test complete. Total reps: \(repCount)")
    }
    
    func testCoachingCues() {
        print("🗣️ Testing Coaching Cue System...")
        
        let scenarios = [
            (depth: 0.25, tempo: 1.5, valgus: 5.0, hr: 140, expected: "Go deeper!"),
            (depth: 0.8, tempo: 3.5, valgus: 8.0, hr: 145, expected: "Slow down!"),
            (depth: 0.7, tempo: 1.2, valgus: 20.0, hr: 150, expected: "Keep knees aligned!"),
            (depth: 0.6, tempo: 1.8, valgus: 10.0, hr: 180, expected: "Heart rate high - take a break!"),
            (depth: 0.75, tempo: 1.5, valgus: 8.0, hr: 140, expected: "Great form!")
        ]
        
        for (index, scenario) in scenarios.enumerated() {
            print("   Scenario \(index + 1):")
            print("     Depth: \(String(format: "%.1f", scenario.depth * 100))%, Tempo: \(scenario.tempo)s, Valgus: \(scenario.valgus)°, HR: \(scenario.hr)")
            
            var cues: [String] = []
            
            // Coaching logic
            if scenario.depth < 0.4 {
                cues.append("Go deeper!")
            }
            if scenario.tempo > 3.0 {
                cues.append("Slow down!")
            }
            if scenario.valgus > 15.0 {
                cues.append("Keep knees aligned!")
            }
            if scenario.hr > 175 {
                cues.append("Heart rate high - take a break!")
            }
            if cues.isEmpty {
                cues.append("Great form!")
            }
            
            let actualCue = cues.first!
            print("     🗣️ Cue: '\(actualCue)'")
            
            if actualCue == scenario.expected {
                print("     ✅ Expected cue triggered correctly")
            } else {
                print("     ⚠️ Expected '\(scenario.expected)' but got '\(actualCue)'")
            }
        }
        
        print("✅ Coaching cue system test complete")
    }
}

// Run tests
let tester = PoseDetectionTester()

print("🧪 Pose Detection & Analysis Test")
print(String(repeating: "=", count: 50))

print("\n1. Apple Vision Pose Detection:")
tester.testAppleVisionPose()

print("\n2. Rep Counting Logic:")
tester.testRepCounting()

print("\n3. Coaching Cue System:")
tester.testCoachingCues()

print("\n🎉 All pose detection tests completed!")

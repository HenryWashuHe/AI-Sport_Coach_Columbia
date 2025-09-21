import Foundation
import Vision
import CoreVideo

final class ApplePoseEstimator: ObservableObject {
    private let confidenceThreshold: Float = 0.3
    var poseHandler: ((PoseKeypoints) -> Void)?
    
    func estimatePose(from pixelBuffer: CVPixelBuffer) {
        let request = VNDetectHumanBodyPoseRequest { [weak self] request, error in
            guard let self = self else { return }
            self.processVisionResults(request.results)
        }
        
        request.revision = VNDetectHumanBodyPoseRequestRevision1
        
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
        try? handler.perform([request])
    }
    
    private func processVisionResults(_ results: [VNObservation]?) {
        guard let bodyPoseResults = results as? [VNHumanBodyPoseObservation],
              let bodyPose = bodyPoseResults.first else { return }
        
        do {
            // Extract all joint points using Apple's Vision framework
            let recognizedPoints = try bodyPose.recognizedPoints(.all)
            
            var joints: [Joint] = []
            
            // Map Vision joint names to our 17-point COCO format
            let jointMapping: [(VNHumanBodyPoseObservation.JointName, Int)] = [
                (.nose, 0), (.leftEye, 1), (.rightEye, 2), (.leftEar, 3), (.rightEar, 4),
                (.leftShoulder, 5), (.rightShoulder, 6), (.leftElbow, 7), (.rightElbow, 8),
                (.leftWrist, 9), (.rightWrist, 10), (.leftHip, 11), (.rightHip, 12),
                (.leftKnee, 13), (.rightKnee, 14), (.leftAnkle, 15), (.rightAnkle, 16)
            ]
            
            // Initialize with 17 default joints
            joints = Array(repeating: Joint(position: CGPoint.zero, confidence: 0.0), count: 17)
            
            // Fill in detected joints
            for (visionJoint, index) in jointMapping {
                if let point = recognizedPoints[visionJoint] {
                    joints[index] = Joint(
                        position: CGPoint(x: point.location.x, y: 1.0 - point.location.y), // Flip Y
                        confidence: point.confidence
                    )
                }
            }
            
            let pose = PoseKeypoints(from: joints)
            
            DispatchQueue.main.async { [weak self] in
                self?.poseHandler?(pose)
            }
            
        } catch {
            print("Failed to extract pose: \(error)")
        }
    }
}

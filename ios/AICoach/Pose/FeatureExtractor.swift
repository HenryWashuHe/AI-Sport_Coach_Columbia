import Foundation
import simd

struct SquatFeatures {
    let hipKneeAngle: Float
    let kneeAnkleAngle: Float
    let depthPercentage: Float
    let kneeValgusAngle: Float
    let tempo: Float
    let timestamp: TimeInterval
}

final class FeatureExtractor {
    private let alpha: Float = 0.2 // EMA smoothing factor
    private var smoothedKeypoints: PoseKeypoints?
    private var previousDepth: Float = 0
    private var depthHistory: [Float] = []
    private var timeHistory: [TimeInterval] = []
    private let maxHistorySize = 30 // ~1 second at 30fps
    
    func extractFeatures(from pose: PoseKeypoints, timestamp: TimeInterval) -> SquatFeatures {
        let smoothed = applySmoothingEMA(to: pose)
        
        let hipKneeAngle = calculateAngle(
            p1: smoothed.leftHip.position,
            p2: smoothed.leftKnee.position,
            p3: smoothed.leftAnkle.position
        )
        
        let kneeAnkleAngle = calculateAngle(
            p1: smoothed.leftKnee.position,
            p2: smoothed.leftAnkle.position,
            p3: CGPoint(x: smoothed.leftAnkle.position.x, y: smoothed.leftAnkle.position.y + 0.1)
        )
        
        let depth = calculateDepthPercentage(from: smoothed)
        let valgus = calculateKneeValgus(from: smoothed)
        let tempo = calculateTempo(depth: depth, timestamp: timestamp)
        
        return SquatFeatures(
            hipKneeAngle: hipKneeAngle,
            kneeAnkleAngle: kneeAnkleAngle,
            depthPercentage: depth,
            kneeValgusAngle: valgus,
            tempo: tempo,
            timestamp: timestamp
        )
    }
    
    private func applySmoothingEMA(to pose: PoseKeypoints) -> PoseKeypoints {
        guard let previous = smoothedKeypoints else {
            smoothedKeypoints = pose
            return pose
        }
        
        let smoothed = PoseKeypoints(from: [
            smoothJoint(current: pose.nose, previous: previous.nose),
            smoothJoint(current: pose.leftEye, previous: previous.leftEye),
            smoothJoint(current: pose.rightEye, previous: previous.rightEye),
            smoothJoint(current: pose.leftEar, previous: previous.leftEar),
            smoothJoint(current: pose.rightEar, previous: previous.rightEar),
            smoothJoint(current: pose.leftShoulder, previous: previous.leftShoulder),
            smoothJoint(current: pose.rightShoulder, previous: previous.rightShoulder),
            smoothJoint(current: pose.leftElbow, previous: previous.leftElbow),
            smoothJoint(current: pose.rightElbow, previous: previous.rightElbow),
            smoothJoint(current: pose.leftWrist, previous: previous.leftWrist),
            smoothJoint(current: pose.rightWrist, previous: previous.rightWrist),
            smoothJoint(current: pose.leftHip, previous: previous.leftHip),
            smoothJoint(current: pose.rightHip, previous: previous.rightHip),
            smoothJoint(current: pose.leftKnee, previous: previous.leftKnee),
            smoothJoint(current: pose.rightKnee, previous: previous.rightKnee),
            smoothJoint(current: pose.leftAnkle, previous: previous.leftAnkle),
            smoothJoint(current: pose.rightAnkle, previous: previous.rightAnkle)
        ])
        
        smoothedKeypoints = smoothed
        return smoothed
    }
    
    private func smoothJoint(current: Joint, previous: Joint) -> Joint {
        let smoothedX = alpha * Float(current.position.x) + (1 - alpha) * Float(previous.position.x)
        let smoothedY = alpha * Float(current.position.y) + (1 - alpha) * Float(previous.position.y)
        let smoothedConf = alpha * current.confidence + (1 - alpha) * previous.confidence
        
        return Joint(
            position: CGPoint(x: CGFloat(smoothedX), y: CGFloat(smoothedY)),
            confidence: smoothedConf
        )
    }
    
    private func calculateAngle(p1: CGPoint, p2: CGPoint, p3: CGPoint) -> Float {
        let v1 = simd_float2(Float(p1.x - p2.x), Float(p1.y - p2.y))
        let v2 = simd_float2(Float(p3.x - p2.x), Float(p3.y - p2.y))
        
        let dot = simd_dot(v1, v2)
        let mag1 = simd_length(v1)
        let mag2 = simd_length(v2)
        
        guard mag1 > 0 && mag2 > 0 else { return 0 }
        
        let cosAngle = dot / (mag1 * mag2)
        let clampedCos = max(-1.0, min(1.0, cosAngle))
        return acos(clampedCos) * 180.0 / Float.pi
    }
    
    private func calculateDepthPercentage(from pose: PoseKeypoints) -> Float {
        let hipY = Float(pose.leftHip.position.y)
        let kneeY = Float(pose.leftKnee.position.y)
        let ankleY = Float(pose.leftAnkle.position.y)
        
        let standingHipKneeDistance = abs(hipY - kneeY)
        let currentHipKneeDistance = abs(hipY - kneeY)
        
        // Simplified depth calculation - in practice, you'd calibrate this
        let depth = max(0, min(1, (standingHipKneeDistance - currentHipKneeDistance) / standingHipKneeDistance))
        return depth
    }
    
    private func calculateKneeValgus(from pose: PoseKeypoints) -> Float {
        let leftHip = pose.leftHip.position
        let leftKnee = pose.leftKnee.position
        let leftAnkle = pose.leftAnkle.position
        
        // Calculate knee valgus as deviation from vertical line
        let hipAnkleX = Float(leftAnkle.x - leftHip.x)
        let kneeDeviationX = Float(leftKnee.x - leftHip.x)
        
        return abs(kneeDeviationX - hipAnkleX) * 100 // Convert to percentage
    }
    
    private func calculateTempo(depth: Float, timestamp: TimeInterval) -> Float {
        depthHistory.append(depth)
        timeHistory.append(timestamp)
        
        if depthHistory.count > maxHistorySize {
            depthHistory.removeFirst()
            timeHistory.removeFirst()
        }
        
        guard depthHistory.count >= 2 else { return 0 }
        
        let depthVelocity = (depth - previousDepth) / Float(timestamp - (timeHistory.last ?? timestamp))
        previousDepth = depth
        
        return abs(depthVelocity)
    }
}

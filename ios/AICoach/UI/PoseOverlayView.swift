import SwiftUI

struct PoseOverlayView: View {
    let pose: PoseKeypoints?
    let viewSize: CGSize
    
    private let jointRadius: CGFloat = 6
    private let lineWidth: CGFloat = 3
    
    var body: some View {
        Canvas { context, size in
            guard let pose = pose else { return }
            
            // Draw skeleton connections
            drawConnections(context: context, pose: pose, size: size)
            
            // Draw joints
            drawJoints(context: context, pose: pose, size: size)
        }
        .allowsHitTesting(false)
    }
    
    private func drawConnections(context: GraphicsContext, pose: PoseKeypoints, size: CGSize) {
        let connections: [(Joint, Joint)] = [
            // Torso
            (pose.leftShoulder, pose.rightShoulder),
            (pose.leftShoulder, pose.leftHip),
            (pose.rightShoulder, pose.rightHip),
            (pose.leftHip, pose.rightHip),
            
            // Left arm
            (pose.leftShoulder, pose.leftElbow),
            (pose.leftElbow, pose.leftWrist),
            
            // Right arm
            (pose.rightShoulder, pose.rightElbow),
            (pose.rightElbow, pose.rightWrist),
            
            // Left leg
            (pose.leftHip, pose.leftKnee),
            (pose.leftKnee, pose.leftAnkle),
            
            // Right leg
            (pose.rightHip, pose.rightKnee),
            (pose.rightKnee, pose.rightAnkle)
        ]
        
        for (joint1, joint2) in connections {
            if joint1.confidence > 0.3 && joint2.confidence > 0.3 {
                let start = CGPoint(
                    x: joint1.position.x * size.width,
                    y: joint1.position.y * size.height
                )
                let end = CGPoint(
                    x: joint2.position.x * size.width,
                    y: joint2.position.y * size.height
                )
                
                context.stroke(
                    Path { path in
                        path.move(to: start)
                        path.addLine(to: end)
                    },
                    with: .color(.green),
                    lineWidth: lineWidth
                )
            }
        }
    }
    
    private func drawJoints(context: GraphicsContext, pose: PoseKeypoints, size: CGSize) {
        let joints = [
            pose.nose, pose.leftEye, pose.rightEye, pose.leftEar, pose.rightEar,
            pose.leftShoulder, pose.rightShoulder, pose.leftElbow, pose.rightElbow,
            pose.leftWrist, pose.rightWrist, pose.leftHip, pose.rightHip,
            pose.leftKnee, pose.rightKnee, pose.leftAnkle, pose.rightAnkle
        ]
        
        for joint in joints {
            if joint.confidence > 0.3 {
                let center = CGPoint(
                    x: joint.position.x * size.width,
                    y: joint.position.y * size.height
                )
                
                let color: Color = joint.confidence > 0.7 ? .green : .yellow
                
                context.fill(
                    Path { path in
                        path.addEllipse(in: CGRect(
                            x: center.x - jointRadius,
                            y: center.y - jointRadius,
                            width: jointRadius * 2,
                            height: jointRadius * 2
                        ))
                    },
                    with: .color(color)
                )
            }
        }
    }
}

#Preview {
    PoseOverlayView(pose: nil, viewSize: CGSize(width: 300, height: 400))
}

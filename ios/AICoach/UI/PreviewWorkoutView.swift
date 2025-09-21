import SwiftUI
 
struct PreviewWorkoutView: View {
    @State private var currentHeartRate: Double = 142
    @State private var repCount = 8
    @State private var isWorkoutActive = true
    @State private var currentCue: String? = "Great form!"
    @State private var workoutTime = "05:23"
    @State private var currentDepth = "78%"
    @State private var currentTempo = "1.4s"
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Mock camera background
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [.blue.opacity(0.3), .purple.opacity(0.3)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .ignoresSafeArea()
                
                // Mock pose skeleton overlay
                MockPoseOverlay()
                
                // UI overlay
                VStack {
                    // Top stats bar
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Image(systemName: "heart.fill")
                                    .foregroundColor(.red)
                                Text("\(Int(currentHeartRate))")
                                    .font(.title2.bold())
                                    .foregroundColor(.white)
                                Text("BPM")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.8))
                            }
                            
                            HStack {
                                Image(systemName: "timer")
                                    .foregroundColor(.green)
                                Text(workoutTime)
                                    .font(.title3.bold())
                                    .foregroundColor(.white)
                            }
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 4) {
                            HStack {
                                Text("Reps:")
                                    .foregroundColor(.white.opacity(0.8))
                                Text("\(repCount)")
                                    .font(.title.bold())
                                    .foregroundColor(.white)
                            }
                            
                            HStack {
                                Text("Depth:")
                                    .foregroundColor(.white.opacity(0.8))
                                Text(currentDepth)
                                    .font(.title3.bold())
                                    .foregroundColor(.green)
                            }
                        }
                    }
                    .padding()
                    .background(Color.black.opacity(0.3))
                    .cornerRadius(15)
                    .padding()
                    
                    Spacer()
                    
                    // Center coaching cue
                    if let cue = currentCue {
                        Text(cue)
                            .font(.title.bold())
                            .foregroundColor(.white)
                            .padding(.horizontal, 30)
                            .padding(.vertical, 15)
                            .background(
                                RoundedRectangle(cornerRadius: 25)
                                    .fill(Color.black.opacity(0.7))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 25)
                                            .stroke(Color.green, lineWidth: 2)
                                    )
                            )
                            .scaleEffect(1.1)
                            .animation(.easeInOut(duration: 0.3), value: currentCue)
                    }
                    
                    Spacer()
                    
                    // Bottom controls
                    HStack(spacing: 30) {
                        // Form metrics
                        VStack {
                            Text("TEMPO")
                                .font(.caption.bold())
                                .foregroundColor(.white.opacity(0.7))
                            Text(currentTempo)
                                .font(.title2.bold())
                                .foregroundColor(.orange)
                        }
                        
                        // Main action button
                        Button(action: {
                            isWorkoutActive.toggle()
                            print("🏋️ Workout button tapped: \(isWorkoutActive ? "Active" : "Stopped")")
                        }) {
                            Text(isWorkoutActive ? "End Workout" : "Start Workout")
                                .font(.title2.bold())
                                .foregroundColor(.white)
                                .frame(width: 140, height: 50)
                                .background(
                                    RoundedRectangle(cornerRadius: 25)
                                        .fill(isWorkoutActive ? Color.red : Color.green)
                                )
                        }
                        
                        // Settings
                        VStack {
                            Button(action: {}) {
                                Image(systemName: "gearshape.fill")
                                    .font(.title2)
                                    .foregroundColor(.white)
                            }
                            Text("Settings")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }
                    .padding()
                    .background(Color.black.opacity(0.3))
                    .cornerRadius(20)
                    .padding()
                }
            }
        }
        .onAppear {
            startMockWorkout()
        }
    }
    
    func startMockWorkout() {
        // Simulate live workout data updates
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            // Update heart rate
            currentHeartRate += Double.random(in: -3...5)
            currentHeartRate = max(100, min(180, currentHeartRate))
            
            // Randomly update other metrics
            if Int.random(in: 1...5) == 1 {
                repCount += 1
                currentDepth = "\(Int.random(in: 60...95))%"
                currentTempo = String(format: "%.1fs", Double.random(in: 1.0...2.5))
                
                // Random coaching cues
                let cues = ["Great form!", "Go deeper!", "Slow down!", "Keep it up!", "Perfect depth!"]
                currentCue = cues.randomElement()
                
                // Clear cue after 2 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    currentCue = nil
                }
            }
        }
    }
}

struct MockPoseOverlay: View {
    @State private var animationOffset: CGFloat = 0
    
    var body: some View {
        ZStack {
            // Mock skeleton joints
            ForEach(mockJoints, id: \.id) { joint in
                Circle()
                    .fill(joint.confidence > 0.7 ? Color.green : Color.yellow)
                    .frame(width: 12, height: 12)
                    .position(x: joint.position.x, y: joint.position.y + animationOffset)
            }
            
            // Mock skeleton connections
            Path { path in
                // Torso
                path.move(to: CGPoint(x: 200, y: 150 + animationOffset))
                path.addLine(to: CGPoint(x: 200, y: 250 + animationOffset))
                
                // Arms
                path.move(to: CGPoint(x: 200, y: 180 + animationOffset))
                path.addLine(to: CGPoint(x: 150, y: 200 + animationOffset))
                path.addLine(to: CGPoint(x: 120, y: 230 + animationOffset))
                
                path.move(to: CGPoint(x: 200, y: 180 + animationOffset))
                path.addLine(to: CGPoint(x: 250, y: 200 + animationOffset))
                path.addLine(to: CGPoint(x: 280, y: 230 + animationOffset))
                
                // Legs
                path.move(to: CGPoint(x: 200, y: 250 + animationOffset))
                path.addLine(to: CGPoint(x: 180, y: 320 + animationOffset))
                path.addLine(to: CGPoint(x: 170, y: 400 + animationOffset))
                
                path.move(to: CGPoint(x: 200, y: 250 + animationOffset))
                path.addLine(to: CGPoint(x: 220, y: 320 + animationOffset))
                path.addLine(to: CGPoint(x: 230, y: 400 + animationOffset))
            }
            .stroke(Color.green, lineWidth: 3)
        }
        .onAppear {
            // Animate slight movement to simulate live pose
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                animationOffset = 10
            }
        }
    }
}

struct MockJoint {
    let id = UUID()
    let position: CGPoint
    let confidence: Float
}

let mockJoints: [MockJoint] = [
    // Head
    MockJoint(position: CGPoint(x: 200, y: 120), confidence: 0.9),
    
    // Shoulders
    MockJoint(position: CGPoint(x: 180, y: 160), confidence: 0.95),
    MockJoint(position: CGPoint(x: 220, y: 160), confidence: 0.93),
    
    // Elbows
    MockJoint(position: CGPoint(x: 150, y: 200), confidence: 0.88),
    MockJoint(position: CGPoint(x: 250, y: 200), confidence: 0.90),
    
    // Wrists
    MockJoint(position: CGPoint(x: 120, y: 230), confidence: 0.85),
    MockJoint(position: CGPoint(x: 280, y: 230), confidence: 0.87),
    
    // Hips
    MockJoint(position: CGPoint(x: 190, y: 250), confidence: 0.96),
    MockJoint(position: CGPoint(x: 210, y: 250), confidence: 0.94),
    
    // Knees
    MockJoint(position: CGPoint(x: 180, y: 320), confidence: 0.92),
    MockJoint(position: CGPoint(x: 220, y: 320), confidence: 0.91),
    
    // Ankles
    MockJoint(position: CGPoint(x: 170, y: 400), confidence: 0.89),
    MockJoint(position: CGPoint(x: 230, y: 400), confidence: 0.86),
]

#Preview("Main - Dark") {
    PreviewWorkoutView()
        .preferredColorScheme(.dark)
}

#Preview("Light Mode") {
    PreviewWorkoutView()
        .preferredColorScheme(.light)
}

#Preview("iPhone SE") {
    PreviewWorkoutView()
        .previewDevice("iPhone SE (3rd generation)")
        .preferredColorScheme(.dark)
}

#Preview("iPhone 15 Pro") {
    PreviewWorkoutView()
        .previewDevice("iPhone 15 Pro")
        .preferredColorScheme(.dark)
}

#Preview("iPad") {
    PreviewWorkoutView()
        .previewDevice("iPad Pro (12.9-inch) (6th generation)")
        .preferredColorScheme(.dark)
}

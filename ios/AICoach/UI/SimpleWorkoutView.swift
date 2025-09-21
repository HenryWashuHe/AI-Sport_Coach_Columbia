import SwiftUI
import AVFoundation

struct SimpleWorkoutView: View {
    @State private var isWorkoutActive = false
    @State private var heartRate = 142
    @State private var repCount = 0
    @State private var currentCue = "Ready to start!"
    
    var body: some View {
        ZStack {
            // Mock camera background
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [.black, .gray.opacity(0.8)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .ignoresSafeArea()
            
            VStack {
                // Top stats
                HStack {
                    VStack(alignment: .leading) {
                        Text("❤️ \(heartRate) BPM")
                            .font(.title2.bold())
                            .foregroundColor(.red)
                        
                        Text("🏋️ \(repCount) Reps")
                            .font(.title2.bold())
                            .foregroundColor(.green)
                    }
                    
                    Spacer()
                    
                    Text(isWorkoutActive ? "🔴 LIVE" : "⏸️ PAUSED")
                        .font(.title3.bold())
                        .foregroundColor(isWorkoutActive ? .red : .orange)
                }
                .padding()
                .background(Color.black.opacity(0.3))
                .cornerRadius(15)
                .padding()
                
                Spacer()
                
                // Center coaching cue
                Text(currentCue)
                    .font(.title.bold())
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 30)
                    .padding(.vertical, 20)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.black.opacity(0.7))
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(Color.blue, lineWidth: 2)
                            )
                    )
                
                Spacer()
                
                // Bottom controls
                HStack(spacing: 30) {
                    Button("Reset") {
                        repCount = 0
                        heartRate = 142
                        currentCue = "Ready to start!"
                    }
                    .font(.title2)
                    .foregroundColor(.white)
                    .frame(width: 100, height: 50)
                    .background(Color.gray)
                    .cornerRadius(25)
                    
                    Button(isWorkoutActive ? "Stop" : "Start") {
                        toggleWorkout()
                    }
                    .font(.title2.bold())
                    .foregroundColor(.white)
                    .frame(width: 120, height: 50)
                    .background(isWorkoutActive ? Color.red : Color.green)
                    .cornerRadius(25)
                }
                .padding()
                .background(Color.black.opacity(0.3))
                .cornerRadius(20)
                .padding()
            }
        }
        .navigationTitle("AI Coach Workout")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func toggleWorkout() {
        isWorkoutActive.toggle()
        
        if isWorkoutActive {
            startMockWorkout()
            currentCue = "Let's go! Start squatting!"
        } else {
            currentCue = "Workout paused"
        }
    }
    
    private func startMockWorkout() {
        // Simulate live workout data
        Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { timer in
            guard isWorkoutActive else {
                timer.invalidate()
                return
            }
            
            // Update heart rate
            heartRate += Int.random(in: -5...8)
            heartRate = max(100, min(180, heartRate))
            
            // Occasionally increment reps
            if Int.random(in: 1...3) == 1 {
                repCount += 1
                
                // Random coaching cues
                let cues = [
                    "Great form!",
                    "Go deeper!",
                    "Perfect depth!",
                    "Keep it up!",
                    "Slow and controlled!",
                    "Excellent work!"
                ]
                currentCue = cues.randomElement() ?? "Keep going!"
            }
        }
    }
}

struct SimpleWorkoutView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            SimpleWorkoutView()
        }
    }
}

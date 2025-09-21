import SwiftUI
import AVFoundation

struct WorkoutView: View {
    @StateObject private var cameraManager = CameraPipeline()
    @StateObject private var healthManager = HealthKitManager.shared
    @StateObject private var poseEstimator = ApplePoseEstimator()
    @StateObject private var featureExtractor = FeatureExtractor()
    @StateObject private var repCounter = RepCounter()
    @StateObject private var coachingEngine = CoachingEngine()
    @StateObject private var metricsSync = MetricsSync()
    
    @State private var currentPose: PoseKeypoints?
    @State private var currentHeartRate: Double = 0
    @State private var repCount = 0
    @State private var isWorkoutActive = false
    @State private var currentCue: CoachingCue?
    @State private var sessionId: String?
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Camera preview
                CameraPreviewView(cameraPipeline: cameraManager)
                
                // Pose overlay
                PoseOverlayView(pose: currentPose, viewSize: geometry.size)
                
                // UI overlay
                VStack {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("HR: \(Int(currentHeartRate))")
                                .font(.title2)
                                .foregroundColor(.white)
                            Text("Reps: \(repCount)")
                                .font(.title2)
                                .foregroundColor(.white)
                        }
                        Spacer()
                    }
                    .padding()
                    
                    Spacer()
                    
                    if let cue = currentCue {
                        Text(cue.message)
                            .font(.title)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.black.opacity(0.7))
                            .cornerRadius(10)
                            .transition(.opacity)
                    }
                    
                    Spacer()
                    
                    HStack {
                        Button(isWorkoutActive ? "End Workout" : "Start Workout") {
                            toggleWorkout()
                        }
                        .font(.title2)
                        .padding()
                        .background(isWorkoutActive ? Color.red : Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .padding()
                }
            }
        }
        .onAppear {
            setupWorkout()
        }
        .onDisappear {
            cleanup()
        }
    }
    
    private func setupWorkout() {
        // Setup camera
        try? cameraManager.configure()
        cameraManager.pixelBufferHandler = { [weak poseEstimator] pixelBuffer, timestamp in
            poseEstimator?.estimatePose(from: pixelBuffer)
        }
        
        // Setup pose estimation
        poseEstimator.poseHandler = { [weak self] pose in
            DispatchQueue.main.async {
                self?.processPose(pose)
            }
        }
        
        // Setup rep counter
        repCounter.onRepCompleted = { [weak self] count in
            DispatchQueue.main.async {
                self?.repCount = count
                self?.metricsSync.addMetric(rep: count)
            }
        }
        
        // Setup coaching engine
        coachingEngine.onCueTriggered = { [weak self] cue in
            DispatchQueue.main.async {
                self?.currentCue = cue
                // Hide cue after 3 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    if self?.currentCue == cue {
                        self?.currentCue = nil
                    }
                }
            }
        }
        
        // Request HealthKit authorization
        healthManager.requestAuthorization { success, error in
            if let error = error {
                print("HealthKit authorization error: \(error)")
            }
        }
    }
    
    private func processPose(_ pose: PoseKeypoints) {
        currentPose = pose
        
        guard isWorkoutActive else { return }
        
        let timestamp = Date().timeIntervalSince1970
        let features = featureExtractor.extractFeatures(from: pose, timestamp: timestamp)
        
        // Process rep counting
        repCounter.processFrame(features: features)
        
        // Analyze form and provide coaching
        coachingEngine.analyzeForm(features: features, heartRate: currentHeartRate)
        
        // Sync metrics
        let errorFlags = determineErrorFlags(from: features)
        metricsSync.addMetric(
            heartRate: currentHeartRate,
            rom: features.depthPercentage,
            tempo: features.tempo,
            errorFlags: errorFlags.isEmpty ? nil : errorFlags
        )
    }
    
    private func determineErrorFlags(from features: SquatFeatures) -> [String] {
        var flags: [String] = []
        
        if features.depthPercentage < 0.4 {
            flags.append("depth")
        }
        if features.kneeValgusAngle > 15.0 {
            flags.append("valgus")
        }
        if features.tempo > 3.0 {
            flags.append("tempo_fast")
        } else if features.tempo < 0.5 {
            flags.append("tempo_slow")
        }
        
        return flags
    }
    
    private func toggleWorkout() {
        if isWorkoutActive {
            endWorkout()
        } else {
            startWorkout()
        }
    }
    
    private func startWorkout() {
        sessionId = UUID().uuidString
        
        healthManager.startWorkout { [weak self] hr in
            DispatchQueue.main.async {
                self?.currentHeartRate = hr
            }
        } completion: { error in
            if let error = error {
                print("Failed to start workout: \(error)")
            }
        }
        
        cameraManager.start()
        metricsSync.startSession(sessionId!)
        repCounter.reset()
        isWorkoutActive = true
    }
    
    private func endWorkout() {
        healthManager.endWorkout { error in
            if let error = error {
                print("Failed to end workout: \(error)")
            }
        }
        
        cameraManager.stop()
        metricsSync.endSession()
        coachingEngine.stopSpeaking()
        isWorkoutActive = false
    }
    
    private func cleanup() {
        cameraManager.stop()
        coachingEngine.stopSpeaking()
        if isWorkoutActive {
            endWorkout()
        }
    }
}

struct CameraPreviewView: UIViewRepresentable {
    let cameraPipeline: CameraPipeline
    
    func makeUIView(context: Context) -> UIView {
        let view = CameraPreviewUIView()
        view.setupPreview(with: cameraPipeline)
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        // No updates needed for camera preview
    }
}

class CameraPreviewUIView: UIView {
    private var previewLayer: AVCaptureVideoPreviewLayer?
    
    func setupPreview(with cameraPipeline: CameraPipeline) {
        // Access the capture session from camera pipeline
        let session = cameraPipeline.captureSession
        
        // Create preview layer
        previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer?.videoGravity = .resizeAspectFill
        previewLayer?.connection?.videoOrientation = .portrait
        
        // Add to view
        if let previewLayer = previewLayer {
            layer.addSublayer(previewLayer)
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        previewLayer?.frame = bounds
    }
}

#Preview {
    WorkoutView()
}

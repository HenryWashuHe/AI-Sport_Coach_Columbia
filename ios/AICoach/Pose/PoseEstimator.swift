import Foundation
import CoreML
import Vision
import CoreVideo
import simd

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

final class PoseEstimator {
    private var model: VNCoreMLModel?
    private let confidenceThreshold: Float = 0.3
    
    var poseHandler: ((PoseKeypoints) -> Void)?
    
    init() {
        loadModel()
    }
    
    private func loadModel() {
        guard let modelURL = Bundle.main.url(forResource: "PoseNet", withExtension: "mlmodelc") else {
            print("PoseNet model not found")
            return
        }
        
        do {
            let mlModel = try MLModel(contentsOf: modelURL)
            model = try VNCoreMLModel(for: mlModel)
        } catch {
            print("Failed to load pose model: \(error)")
        }
    }
    
    func estimatePose(from pixelBuffer: CVPixelBuffer) {
        guard let model = model else { return }
        
        let request = VNCoreMLRequest(model: model) { [weak self] request, error in
            guard let self = self else { return }
            self.processPoseResults(request.results)
        }
        
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
        try? handler.perform([request])
    }
    
    private func processPoseResults(_ results: [VNObservation]?) {
        guard let results = results as? [VNCoreMLFeatureValueObservation],
              let heatmaps = results.first?.featureValue.multiArrayValue else { return }
        
        let keypoints = extractKeypoints(from: heatmaps)
        let pose = PoseKeypoints(from: keypoints)
        
        DispatchQueue.main.async { [weak self] in
            self?.poseHandler?(pose)
        }
    }
    
    private func extractKeypoints(from heatmaps: MLMultiArray) -> [Joint] {
        let height = heatmaps.shape[1].intValue
        let width = heatmaps.shape[2].intValue
        let numKeypoints = heatmaps.shape[3].intValue
        
        var keypoints: [Joint] = []
        
        for k in 0..<numKeypoints {
            var maxVal: Float = 0
            var maxY = 0
            var maxX = 0
            
            for y in 0..<height {
                for x in 0..<width {
                    let index = y * width * numKeypoints + x * numKeypoints + k
                    let value = heatmaps[index].floatValue
                    
                    if value > maxVal {
                        maxVal = value
                        maxY = y
                        maxX = x
                    }
                }
            }
            
            let normalizedX = Float(maxX) / Float(width)
            let normalizedY = Float(maxY) / Float(height)
            
            keypoints.append(Joint(
                position: CGPoint(x: CGFloat(normalizedX), y: CGFloat(normalizedY)),
                confidence: maxVal
            ))
        }
        
        return keypoints
    }
}

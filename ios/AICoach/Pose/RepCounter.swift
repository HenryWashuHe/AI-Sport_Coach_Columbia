import Foundation

enum RepPhase {
    case standing
    case descending
    case bottom
    case ascending
}

final class RepCounter {
    private var currentPhase: RepPhase = .standing
    private var repCount = 0
    private var depthHistory: [Float] = []
    private var velocityHistory: [Float] = []
    private let maxHistorySize = 10
    private let depthThreshold: Float = 0.3 // 30% depth to count as squat
    private let velocityThreshold: Float = 0.01 // Near-zero velocity threshold
    
    var onRepCompleted: ((Int) -> Void)?
    
    func processFrame(features: SquatFeatures) {
        updateHistory(depth: features.depthPercentage, velocity: features.tempo)
        
        let avgDepth = depthHistory.reduce(0, +) / Float(depthHistory.count)
        let avgVelocity = velocityHistory.reduce(0, +) / Float(velocityHistory.count)
        
        switch currentPhase {
        case .standing:
            if avgDepth > depthThreshold && features.tempo > velocityThreshold {
                currentPhase = .descending
            }
            
        case .descending:
            if avgVelocity < velocityThreshold && avgDepth > depthThreshold {
                currentPhase = .bottom
            } else if avgDepth < depthThreshold {
                currentPhase = .standing // Reset if depth decreases without reaching bottom
            }
            
        case .bottom:
            if avgVelocity > velocityThreshold && avgDepth > depthThreshold {
                currentPhase = .ascending
            }
            
        case .ascending:
            if avgDepth < depthThreshold && avgVelocity < velocityThreshold {
                // Rep completed
                repCount += 1
                currentPhase = .standing
                onRepCompleted?(repCount)
            }
        }
    }
    
    private func updateHistory(depth: Float, velocity: Float) {
        depthHistory.append(depth)
        velocityHistory.append(velocity)
        
        if depthHistory.count > maxHistorySize {
            depthHistory.removeFirst()
        }
        if velocityHistory.count > maxHistorySize {
            velocityHistory.removeFirst()
        }
    }
    
    func reset() {
        repCount = 0
        currentPhase = .standing
        depthHistory.removeAll()
        velocityHistory.removeAll()
    }
    
    func getCurrentRep() -> Int {
        return repCount
    }
}

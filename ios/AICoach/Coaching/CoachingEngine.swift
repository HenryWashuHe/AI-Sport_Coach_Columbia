import Foundation
import AVFoundation

enum CoachingCue {
    case depthTooShallow
    case kneeValgus
    case tempoTooFast
    case tempoTooSlow
    case heartRateTooHigh
    case goodForm
    
    var message: String {
        switch self {
        case .depthTooShallow:
            return "Go deeper"
        case .kneeValgus:
            return "Keep knees aligned"
        case .tempoTooFast:
            return "Slow down"
        case .tempoTooSlow:
            return "Pick up the pace"
        case .heartRateTooHigh:
            return "Take a break, heart rate high"
        case .goodForm:
            return "Great form"
        }
    }
}

final class CoachingEngine {
    private let speechSynthesizer = AVSpeechSynthesizer()
    private var lastCueTime: [CoachingCue: TimeInterval] = [:]
    private let cueDebounceInterval: TimeInterval = 12.0 // 12 seconds
    
    // Thresholds
    private let minDepthThreshold: Float = 0.4 // 40%
    private let maxValgusThreshold: Float = 15.0 // degrees
    private let minTempoThreshold: Float = 0.5
    private let maxTempoThreshold: Float = 3.0
    private let maxHeartRateThreshold: Double = 180.0
    
    var onCueTriggered: ((CoachingCue) -> Void)?
    
    func analyzeForm(features: SquatFeatures, heartRate: Double?) {
        let currentTime = features.timestamp
        var triggeredCues: [CoachingCue] = []
        
        // Check depth
        if features.depthPercentage < minDepthThreshold {
            triggeredCues.append(.depthTooShallow)
        }
        
        // Check knee valgus
        if features.kneeValgusAngle > maxValgusThreshold {
            triggeredCues.append(.kneeValgus)
        }
        
        // Check tempo
        if features.tempo > maxTempoThreshold {
            triggeredCues.append(.tempoTooFast)
        } else if features.tempo < minTempoThreshold && features.depthPercentage > 0.1 {
            triggeredCues.append(.tempoTooSlow)
        }
        
        // Check heart rate
        if let hr = heartRate, hr > maxHeartRateThreshold {
            triggeredCues.append(.heartRateTooHigh)
        }
        
        // If no issues, give positive feedback occasionally
        if triggeredCues.isEmpty && shouldGivePositiveFeedback(currentTime) {
            triggeredCues.append(.goodForm)
        }
        
        // Process cues with debouncing
        for cue in triggeredCues {
            if shouldTriggerCue(cue, at: currentTime) {
                triggerCue(cue, at: currentTime)
            }
        }
    }
    
    private func shouldTriggerCue(_ cue: CoachingCue, at currentTime: TimeInterval) -> Bool {
        guard let lastTime = lastCueTime[cue] else { return true }
        return currentTime - lastTime >= cueDebounceInterval
    }
    
    private func shouldGivePositiveFeedback(_ currentTime: TimeInterval) -> Bool {
        guard let lastTime = lastCueTime[.goodForm] else { return true }
        return currentTime - lastTime >= 30.0 // Positive feedback every 30 seconds
    }
    
    private func triggerCue(_ cue: CoachingCue, at currentTime: TimeInterval) {
        lastCueTime[cue] = currentTime
        
        // Trigger audio cue
        speakCue(cue)
        
        // Notify UI
        onCueTriggered?(cue)
    }
    
    private func speakCue(_ cue: CoachingCue) {
        guard !speechSynthesizer.isSpeaking else { return }
        
        let utterance = AVSpeechUtterance(string: cue.message)
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate
        utterance.volume = 0.8
        utterance.pitchMultiplier = 1.0
        
        speechSynthesizer.speak(utterance)
    }
    
    func stopSpeaking() {
        speechSynthesizer.stopSpeaking(at: .immediate)
    }
}

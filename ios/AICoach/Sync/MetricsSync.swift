import Foundation

struct MetricData: Codable {
    let t: Date
    let hr: Double?
    let hrv: Double?
    let rep: Int?
    let rom: Float?
    let tempo: Float?
    let errorFlags: [String]?
    
    enum CodingKeys: String, CodingKey {
        case t, hr, hrv, rep, rom, tempo
        case errorFlags = "error_flags"
    }
}

struct MetricsBatch: Codable {
    let sessionId: String
    let metrics: [MetricData]
    
    enum CodingKeys: String, CodingKey {
        case sessionId = "session_id"
        case metrics
    }
}

final class MetricsSync {
    private let baseURL = "http://localhost:8002" // Your demo server
    private var pendingMetrics: [MetricData] = []
    private var currentSessionId: String?
    private let batchSize = 10
    private let syncInterval: TimeInterval = 3.0 // 3 seconds
    private var syncTimer: Timer?
    
    private let session = URLSession.shared
    private let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()
    
    func startSession(_ sessionId: String) {
        currentSessionId = sessionId
        startSyncTimer()
    }
    
    func endSession() {
        syncTimer?.invalidate()
        syncTimer = nil
        
        // Final sync of remaining metrics
        if !pendingMetrics.isEmpty {
            syncPendingMetrics()
        }
        
        currentSessionId = nil
    }
    
    func addMetric(
        heartRate: Double? = nil,
        hrv: Double? = nil,
        rep: Int? = nil,
        rom: Float? = nil,
        tempo: Float? = nil,
        errorFlags: [String]? = nil
    ) {
        let metric = MetricData(
            t: Date(),
            hr: heartRate,
            hrv: hrv,
            rep: rep,
            rom: rom,
            tempo: tempo,
            errorFlags: errorFlags
        )
        
        pendingMetrics.append(metric)
        
        // Sync immediately if batch is full
        if pendingMetrics.count >= batchSize {
            syncPendingMetrics()
        }
    }
    
    private func startSyncTimer() {
        syncTimer = Timer.scheduledTimer(withTimeInterval: syncInterval, repeats: true) { [weak self] _ in
            self?.syncPendingMetrics()
        }
    }
    
    private func syncPendingMetrics() {
        guard !pendingMetrics.isEmpty,
              let sessionId = currentSessionId else { return }
        
        let batch = MetricsBatch(sessionId: sessionId, metrics: pendingMetrics)
        
        do {
            let data = try encoder.encode(batch)
            sendBatch(data: data) { [weak self] success in
                if success {
                    DispatchQueue.main.async {
                        self?.pendingMetrics.removeAll()
                    }
                }
                // If failed, metrics remain in pendingMetrics for retry
            }
        } catch {
            print("Failed to encode metrics batch: \(error)")
        }
    }
    
    private func sendBatch(data: Data, completion: @escaping (Bool) -> Void) {
        guard let url = URL(string: "\(baseURL)/v1/metrics/batch") else {
            completion(false)
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = data
        
        session.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Metrics sync error: \(error)")
                completion(false)
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse,
               httpResponse.statusCode == 200 {
                completion(true)
            } else {
                completion(false)
            }
        }.resume()
    }
}

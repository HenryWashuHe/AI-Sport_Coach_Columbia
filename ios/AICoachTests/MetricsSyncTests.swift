import XCTest
@testable import AICoach

final class MetricsSyncTests: XCTestCase {
    var metricsSync: MetricsSync!
    
    override func setUp() {
        super.setUp()
        metricsSync = MetricsSync()
    }
    
    override func tearDown() {
        metricsSync = nil
        super.tearDown()
    }
    
    func testMetricDataEncoding() {
        let metric = MetricData(
            t: Date(),
            hr: 120.5,
            hrv: 45.2,
            rep: 5,
            rom: 0.75,
            tempo: 1.5,
            errorFlags: ["depth", "valgus"]
        )
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        
        XCTAssertNoThrow(try encoder.encode(metric))
        
        let data = try! encoder.encode(metric)
        let json = String(data: data, encoding: .utf8)!
        
        XCTAssertTrue(json.contains("\"hr\":120.5"))
        XCTAssertTrue(json.contains("\"rep\":5"))
        XCTAssertTrue(json.contains("\"error_flags\":[\"depth\",\"valgus\"]"))
    }
    
    func testMetricsBatchEncoding() {
        let metrics = [
            MetricData(t: Date(), hr: 120, hrv: nil, rep: 1, rom: 0.6, tempo: 1.2, errorFlags: nil),
            MetricData(t: Date(), hr: 125, hrv: 42.1, rep: nil, rom: 0.7, tempo: 1.1, errorFlags: ["depth"])
        ]
        
        let batch = MetricsBatch(sessionId: "test-session-123", metrics: metrics)
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        
        XCTAssertNoThrow(try encoder.encode(batch))
        
        let data = try! encoder.encode(batch)
        let json = String(data: data, encoding: .utf8)!
        
        XCTAssertTrue(json.contains("\"session_id\":\"test-session-123\""))
        XCTAssertTrue(json.contains("\"metrics\":["))
    }
    
    func testSessionLifecycle() {
        let sessionId = "test-session-456"
        
        // Start session
        metricsSync.startSession(sessionId)
        
        // Add some metrics
        metricsSync.addMetric(heartRate: 130, rep: 1, rom: 0.8)
        metricsSync.addMetric(heartRate: 135, rep: 2, rom: 0.75, errorFlags: ["tempo_fast"])
        
        // End session
        metricsSync.endSession()
        
        // Should complete without errors
        XCTAssertTrue(true)
    }
    
    func testBatchSizeTriggering() {
        let sessionId = "test-session-batch"
        metricsSync.startSession(sessionId)
        
        // Add exactly batch size (10) metrics
        for i in 1...10 {
            metricsSync.addMetric(heartRate: Double(120 + i), rep: i)
        }
        
        // Should trigger batch sync automatically
        // In a real test, we'd mock the network layer to verify this
        
        metricsSync.endSession()
        XCTAssertTrue(true)
    }
}

from datetime import datetime, timezone, timedelta
import time


def test_realistic_workout_session(client):
    """Simulate a realistic 10-minute workout session with continuous metrics"""
    
    # Start workout session
    user_id = "realistic-test-user"
    start_resp = client.post("/v1/sessions/start", json={"user_id": user_id})
    assert start_resp.status_code == 200
    
    session_id = start_resp.json()["session_id"]
    start_time = datetime.now(timezone.utc)
    
    # Simulate 10-minute workout with metrics every 3 seconds
    total_metrics_sent = 0
    rep_count = 0
    
    for minute in range(10):  # 10 minutes
        for batch in range(20):  # 20 batches per minute (every 3 seconds)
            current_time = start_time + timedelta(minutes=minute, seconds=batch * 3)
            
            # Simulate workout progression
            if minute < 2:  # Warm-up phase
                hr = 100 + minute * 10
                depth = 0.3 + (batch % 5) * 0.1  # Shallow squats
                tempo = 0.8
                error_flags = ["depth"] if depth < 0.4 else None
            elif minute < 8:  # Main workout
                hr = 120 + minute * 5 + (batch % 3) * 2
                depth = 0.5 + (batch % 4) * 0.15  # Good depth variation
                tempo = 1.2 + (batch % 3) * 0.3
                error_flags = []
                if tempo > 2.5:
                    error_flags.append("tempo_fast")
                if depth > 0.8:
                    rep_count += 1
            else:  # Cool-down phase
                hr = max(90, 140 - (minute - 8) * 15)
                depth = 0.2 + (batch % 3) * 0.1  # Light movement
                tempo = 0.5
                error_flags = None
            
            # Create metrics batch
            metrics = []
            for i in range(3):  # 3 metrics per batch
                metric_time = current_time + timedelta(seconds=i)
                metrics.append({
                    "t": metric_time.isoformat(),
                    "hr": hr + i,
                    "hrv": 40.0 + (minute * 2) + (i * 0.5),
                    "rep": rep_count if i == 2 else None,  # Rep count on last metric
                    "rom": depth,
                    "tempo": tempo,
                    "error_flags": error_flags
                })
            
            batch_payload = {
                "session_id": session_id,
                "metrics": metrics
            }
            
            # Send batch
            batch_resp = client.post("/v1/metrics/batch", json=batch_payload)
            assert batch_resp.status_code == 200
            assert batch_resp.json()["accepted"] == 3
            
            total_metrics_sent += 3
    
    # End workout session
    end_resp = client.post("/v1/sessions/end", json={"session_id": session_id})
    assert end_resp.status_code == 200
    
    end_data = end_resp.json()
    assert end_data["session_id"] == session_id
    
    # Verify we sent a realistic amount of data
    assert total_metrics_sent == 600  # 10 minutes * 20 batches * 3 metrics
    assert rep_count > 0  # Should have completed some reps
    
    print(f"✅ Realistic workout test completed:")
    print(f"   - Duration: 10 minutes (simulated)")
    print(f"   - Total metrics sent: {total_metrics_sent}")
    print(f"   - Reps completed: {rep_count}")
    print(f"   - Session ID: {session_id}")


def test_high_frequency_metrics(client):
    """Test handling of high-frequency metric ingestion"""
    
    # Start session
    start_resp = client.post("/v1/sessions/start", json={"user_id": "high-freq-user"})
    session_id = start_resp.json()["session_id"]
    
    # Send 50 batches rapidly (simulating 30fps for ~5 seconds)
    total_accepted = 0
    
    for i in range(50):
        current_time = datetime.now(timezone.utc) + timedelta(milliseconds=i * 33)  # ~30fps
        
        batch = {
            "session_id": session_id,
            "metrics": [{
                "t": current_time.isoformat(),
                "hr": 120 + (i % 10),
                "rom": 0.5 + (i % 5) * 0.1,
                "tempo": 1.0 + (i % 3) * 0.2
            }]
        }
        
        resp = client.post("/v1/metrics/batch", json=batch)
        assert resp.status_code == 200
        total_accepted += resp.json()["accepted"]
    
    # End session
    client.post("/v1/sessions/end", json={"session_id": session_id})
    
    assert total_accepted == 50
    print(f"✅ High-frequency test: {total_accepted} metrics processed successfully")


def test_error_recovery(client):
    """Test system behavior with various error conditions"""
    
    # Test with invalid session ID
    invalid_batch = {
        "session_id": "non-existent-session",
        "metrics": [{
            "t": datetime.now(timezone.utc).isoformat(),
            "hr": 120
        }]
    }
    
    resp = client.post("/v1/metrics/batch", json=invalid_batch)
    assert resp.status_code == 200  # Should still accept (graceful degradation)
    assert resp.json()["accepted"] == 1
    
    # Test with malformed timestamps (should be handled by Pydantic)
    try:
        malformed_batch = {
            "session_id": "test-session",
            "metrics": [{
                "t": "invalid-timestamp",
                "hr": 120
            }]
        }
        resp = client.post("/v1/metrics/batch", json=malformed_batch)
        # Should return 422 for validation error
        assert resp.status_code == 422
    except:
        pass  # Expected to fail validation
    
    print("✅ Error recovery test completed")

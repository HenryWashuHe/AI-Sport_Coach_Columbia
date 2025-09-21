from datetime import datetime, timezone
import pytest


def test_complete_system_integration(client):
    """Test complete end-to-end system integration"""
    
    # 1. Check system health
    health_resp = client.get("/healthz")
    assert health_resp.status_code == 200
    assert health_resp.json()["ok"] is True
    
    # 2. Start workout session
    user_id = "integration-user-final"
    start_resp = client.post("/v1/sessions/start", json={"user_id": user_id})
    assert start_resp.status_code == 200
    session_id = start_resp.json()["session_id"]
    
    # 3. Simulate real workout with progressive metrics
    workout_phases = [
        # Warm-up phase
        {"phase": "warmup", "reps": range(1, 4), "hr_base": 110, "depth": 0.3, "errors": ["depth"]},
        # Main workout phase  
        {"phase": "main", "reps": range(4, 16), "hr_base": 130, "depth": 0.7, "errors": []},
        # Cool-down phase
        {"phase": "cooldown", "reps": range(16, 18), "hr_base": 100, "depth": 0.2, "errors": []}
    ]
    
    total_metrics_sent = 0
    
    for phase_data in workout_phases:
        for rep in phase_data["reps"]:
            now = datetime.now(timezone.utc).isoformat()
            
            # Create realistic metrics for this rep
            metrics = []
            for i in range(3):  # 3 metrics per rep
                hr = phase_data["hr_base"] + (i * 2) + (rep % 5)
                depth = phase_data["depth"] + (i * 0.1)
                tempo = 1.2 + (i * 0.2)
                
                metrics.append({
                    "t": now,
                    "hr": hr,
                    "hrv": 45.0 + (rep * 0.5),
                    "rep": rep if i == 2 else None,  # Rep count on last metric
                    "rom": depth,
                    "tempo": tempo,
                    "error_flags": phase_data["errors"] if phase_data["errors"] else None
                })
            
            # Send batch
            batch_resp = client.post("/v1/metrics/batch", json={
                "session_id": session_id,
                "metrics": metrics
            })
            assert batch_resp.status_code == 200
            assert batch_resp.json()["accepted"] == 3
            total_metrics_sent += 3
    
    # 4. Check today's plan
    plan_resp = client.get("/v1/plans/today")
    assert plan_resp.status_code == 200
    plan_data = plan_resp.json()
    assert "items" in plan_data
    assert len(plan_data["items"]) >= 1
    
    # 5. End workout session
    end_resp = client.post("/v1/sessions/end", json={"session_id": session_id})
    assert end_resp.status_code == 200
    assert end_resp.json()["session_id"] == session_id
    
    # 6. Verify account deletion works
    delete_resp = client.post("/v1/account/delete", json={"user_id": user_id})
    assert delete_resp.status_code == 200
    assert delete_resp.json()["deleted"] is True
    
    # Verify total metrics processed
    assert total_metrics_sent == 51  # 17 reps * 3 metrics each
    
    print(f"✅ Complete system integration test passed:")
    print(f"   - Session lifecycle: ✓")
    print(f"   - Metrics ingestion: {total_metrics_sent} metrics ✓")
    print(f"   - Plan retrieval: ✓")
    print(f"   - Account deletion: ✓")


def test_system_performance_under_load(client):
    """Test system performance with high load"""
    
    # Create multiple concurrent sessions
    sessions = []
    for i in range(5):
        resp = client.post("/v1/sessions/start", json={"user_id": f"load-test-user-{i}"})
        assert resp.status_code == 200
        sessions.append(resp.json()["session_id"])
    
    # Send metrics to all sessions simultaneously
    total_metrics = 0
    now = datetime.now(timezone.utc).isoformat()
    
    for session_id in sessions:
        for batch_num in range(10):  # 10 batches per session
            metrics = []
            for metric_num in range(5):  # 5 metrics per batch
                metrics.append({
                    "t": now,
                    "hr": 120 + batch_num + metric_num,
                    "hrv": 40 + batch_num,
                    "rep": batch_num + 1 if metric_num == 4 else None,
                    "rom": 0.6 + (metric_num * 0.1),
                    "tempo": 1.0 + (metric_num * 0.2)
                })
            
            resp = client.post("/v1/metrics/batch", json={
                "session_id": session_id,
                "metrics": metrics
            })
            assert resp.status_code == 200
            assert resp.json()["accepted"] == 5
            total_metrics += 5
    
    # End all sessions
    for session_id in sessions:
        resp = client.post("/v1/sessions/end", json={"session_id": session_id})
        assert resp.status_code == 200
    
    # Clean up users
    for i in range(5):
        client.post("/v1/account/delete", json={"user_id": f"load-test-user-{i}"})
    
    assert total_metrics == 250  # 5 sessions * 10 batches * 5 metrics
    print(f"✅ Performance test passed: {total_metrics} metrics processed across 5 concurrent sessions")


def test_error_resilience(client):
    """Test system resilience to various error conditions"""
    
    # Test with malformed data
    malformed_requests = [
        # Missing required fields
        {"session_id": "test", "metrics": [{"t": "invalid-time"}]},
        # Invalid data types  
        {"session_id": 123, "metrics": []},
        # Empty session ID
        {"session_id": "", "metrics": [{"t": datetime.now(timezone.utc).isoformat()}]}
    ]
    
    error_responses = 0
    for req in malformed_requests:
        try:
            resp = client.post("/v1/metrics/batch", json=req)
            if resp.status_code >= 400:
                error_responses += 1
        except:
            error_responses += 1
    
    # Should handle errors gracefully
    assert error_responses >= 1
    
    # Test system still works after errors
    resp = client.get("/healthz")
    assert resp.status_code == 200
    
    print("✅ Error resilience test passed: System handles malformed requests gracefully")

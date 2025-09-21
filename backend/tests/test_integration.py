from datetime import datetime, timezone


def test_full_workout_flow(client):
    """Test complete workout flow: start session -> batch metrics -> end session"""
    
    # 1. Start session
    start_payload = {"user_id": "integration-test-user"}
    start_resp = client.post("/v1/sessions/start", json=start_payload)
    assert start_resp.status_code == 200
    
    start_data = start_resp.json()
    session_id = start_data["session_id"]
    assert "started_at" in start_data
    
    # 2. Send multiple metric batches (simulating real workout)
    now = datetime.now(timezone.utc).isoformat()
    
    # First batch - workout beginning
    batch1 = {
        "session_id": session_id,
        "metrics": [
            {"t": now, "hr": 110.0, "rep": 0, "rom": 0.1, "tempo": 0.5},
            {"t": now, "hr": 115.0, "rep": 1, "rom": 0.6, "tempo": 1.2, "error_flags": ["depth"]},
        ]
    }
    batch1_resp = client.post("/v1/metrics/batch", json=batch1)
    assert batch1_resp.status_code == 200
    assert batch1_resp.json()["accepted"] == 2
    
    # Second batch - mid workout
    batch2 = {
        "session_id": session_id,
        "metrics": [
            {"t": now, "hr": 125.0, "rep": 2, "rom": 0.8, "tempo": 1.5},
            {"t": now, "hr": 130.0, "rep": 3, "rom": 0.75, "tempo": 1.8, "error_flags": ["tempo_fast"]},
            {"t": now, "hr": 135.0, "rep": 4, "rom": 0.9, "tempo": 1.2},
        ]
    }
    batch2_resp = client.post("/v1/metrics/batch", json=batch2)
    assert batch2_resp.status_code == 200
    assert batch2_resp.json()["accepted"] == 3
    
    # Third batch - workout end
    batch3 = {
        "session_id": session_id,
        "metrics": [
            {"t": now, "hr": 140.0, "rep": 5, "rom": 0.85, "tempo": 1.0},
            {"t": now, "hr": 120.0, "rep": 5, "rom": 0.2, "tempo": 0.3}, # cooling down
        ]
    }
    batch3_resp = client.post("/v1/metrics/batch", json=batch3)
    assert batch3_resp.status_code == 200
    assert batch3_resp.json()["accepted"] == 2
    
    # 3. End session
    end_payload = {"session_id": session_id}
    end_resp = client.post("/v1/sessions/end", json=end_payload)
    assert end_resp.status_code == 200
    
    end_data = end_resp.json()
    assert end_data["session_id"] == session_id
    assert "ended_at" in end_data
    
    # 4. Check today's plan (should still work)
    plan_resp = client.get("/v1/plans/today")
    assert plan_resp.status_code == 200
    
    plan_data = plan_resp.json()
    assert "items" in plan_data
    assert len(plan_data["items"]) >= 1


def test_error_handling(client):
    """Test error cases and edge conditions"""
    
    # Invalid session end (non-existent session)
    end_resp = client.post("/v1/sessions/end", json={"session_id": "non-existent"})
    assert end_resp.status_code == 200  # Should not error, just return timestamp
    
    # Empty metrics batch
    empty_batch = {
        "session_id": "test-session",
        "metrics": []
    }
    empty_resp = client.post("/v1/metrics/batch", json=empty_batch)
    assert empty_resp.status_code == 200
    assert empty_resp.json()["accepted"] == 0
    
    # Metrics with only timestamp
    minimal_batch = {
        "session_id": "test-session",
        "metrics": [
            {"t": datetime.now(timezone.utc).isoformat()}
        ]
    }
    minimal_resp = client.post("/v1/metrics/batch", json=minimal_batch)
    assert minimal_resp.status_code == 200
    assert minimal_resp.json()["accepted"] == 1


def test_concurrent_sessions(client):
    """Test multiple concurrent user sessions"""
    
    # Start multiple sessions for different users
    user1_resp = client.post("/v1/sessions/start", json={"user_id": "user1"})
    user2_resp = client.post("/v1/sessions/start", json={"user_id": "user2"})
    
    assert user1_resp.status_code == 200
    assert user2_resp.status_code == 200
    
    session1_id = user1_resp.json()["session_id"]
    session2_id = user2_resp.json()["session_id"]
    
    assert session1_id != session2_id
    
    # Send metrics to both sessions
    now = datetime.now(timezone.utc).isoformat()
    
    batch1 = {
        "session_id": session1_id,
        "metrics": [{"t": now, "hr": 120, "rep": 1}]
    }
    batch2 = {
        "session_id": session2_id,
        "metrics": [{"t": now, "hr": 140, "rep": 2}]
    }
    
    resp1 = client.post("/v1/metrics/batch", json=batch1)
    resp2 = client.post("/v1/metrics/batch", json=batch2)
    
    assert resp1.status_code == 200
    assert resp2.status_code == 200
    
    # End both sessions
    client.post("/v1/sessions/end", json={"session_id": session1_id})
    client.post("/v1/sessions/end", json={"session_id": session2_id})

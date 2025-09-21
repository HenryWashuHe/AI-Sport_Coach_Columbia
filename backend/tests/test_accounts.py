from datetime import datetime, timezone


def test_account_deletion(client):
    """Test complete account deletion with all associated data"""
    
    # Create user with session and metrics
    user_id = "delete-test-user"
    
    # Start session
    start_resp = client.post("/v1/sessions/start", json={"user_id": user_id})
    assert start_resp.status_code == 200
    session_id = start_resp.json()["session_id"]
    
    # Add some metrics
    now = datetime.now(timezone.utc).isoformat()
    batch = {
        "session_id": session_id,
        "metrics": [
            {"t": now, "hr": 120, "rep": 1, "rom": 0.6},
            {"t": now, "hr": 125, "rep": 2, "rom": 0.8},
        ]
    }
    metrics_resp = client.post("/v1/metrics/batch", json=batch)
    assert metrics_resp.status_code == 200
    assert metrics_resp.json()["accepted"] == 2
    
    # End session
    client.post("/v1/sessions/end", json={"session_id": session_id})
    
    # Delete account
    delete_resp = client.post("/v1/account/delete", json={"user_id": user_id})
    assert delete_resp.status_code == 200
    
    delete_data = delete_resp.json()
    assert delete_data["user_id"] == user_id
    assert delete_data["deleted"] is True
    assert "successfully" in delete_data["message"]


def test_delete_nonexistent_user(client):
    """Test deletion of non-existent user returns 404"""
    
    delete_resp = client.post("/v1/account/delete", json={"user_id": "non-existent-user"})
    assert delete_resp.status_code == 404
    
    error_data = delete_resp.json()
    assert "not found" in error_data["detail"].lower()


def test_delete_user_with_multiple_sessions(client):
    """Test deletion of user with multiple sessions and metrics"""
    
    user_id = "multi-session-user"
    
    # Create multiple sessions
    session_ids = []
    for i in range(3):
        start_resp = client.post("/v1/sessions/start", json={"user_id": user_id})
        session_id = start_resp.json()["session_id"]
        session_ids.append(session_id)
        
        # Add metrics to each session
        now = datetime.now(timezone.utc).isoformat()
        batch = {
            "session_id": session_id,
            "metrics": [
                {"t": now, "hr": 120 + i * 10, "rep": i + 1},
                {"t": now, "hr": 125 + i * 10, "rep": i + 2},
            ]
        }
        client.post("/v1/metrics/batch", json=batch)
        client.post("/v1/sessions/end", json={"session_id": session_id})
    
    # Delete account (should remove all sessions and metrics)
    delete_resp = client.post("/v1/account/delete", json={"user_id": user_id})
    assert delete_resp.status_code == 200
    assert delete_resp.json()["deleted"] is True

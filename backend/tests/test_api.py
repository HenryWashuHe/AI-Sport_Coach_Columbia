from datetime import datetime, timezone


def test_healthz(client):
    r = client.get("/healthz")
    assert r.status_code == 200
    assert r.json() == {"ok": True}


def test_session_start_end(client):
    # start
    payload = {"user_id": "user-1"}
    r = client.post("/v1/sessions/start", json=payload)
    assert r.status_code == 200
    data = r.json()
    assert "session_id" in data
    assert "started_at" in data
    session_id = data["session_id"]

    # end
    r2 = client.post("/v1/sessions/end", json={"session_id": session_id})
    assert r2.status_code == 200
    data2 = r2.json()
    assert data2["session_id"] == session_id
    assert "ended_at" in data2


def test_metrics_batch_and_plan(client):
    # start session first
    r = client.post("/v1/sessions/start", json={"user_id": "user-2"})
    session_id = r.json()["session_id"]

    now = datetime.now(timezone.utc).isoformat()
    batch = {
        "session_id": session_id,
        "metrics": [
            {"t": now, "hr": 120.5, "hrv": 45.2, "rep": 1, "rom": 0.85, "tempo": 2.1, "error_flags": ["depth"]},
            {"t": now, "hr": 122.0, "hrv": 44.8, "rep": 2, "rom": 0.88, "tempo": 2.0, "error_flags": []},
        ],
    }
    r2 = client.post("/v1/metrics/batch", json=batch)
    assert r2.status_code == 200
    assert r2.json()["accepted"] == 2

    r3 = client.get("/v1/plans/today")
    assert r3.status_code == 200
    plan = r3.json()
    assert "items" in plan
    assert len(plan["items"]) >= 1
    assert plan["items"][0]["workout"] == "squat"

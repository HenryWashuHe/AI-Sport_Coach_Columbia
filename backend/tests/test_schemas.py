import pytest
from datetime import datetime, timezone
from app.api.v1.schemas import (
    SessionStartRequest, SessionStartResponse,
    SessionEndRequest, SessionEndResponse,
    MetricItem, MetricsBatchRequest, MetricsBatchResponse,
    PlanItem, PlanTodayResponse
)


def test_session_start_request():
    req = SessionStartRequest(user_id="test-user")
    assert req.user_id == "test-user"
    assert req.plan_id is None
    
    req_with_plan = SessionStartRequest(user_id="test-user", plan_id="plan-123")
    assert req_with_plan.plan_id == "plan-123"


def test_session_start_response():
    now = datetime.now(timezone.utc)
    resp = SessionStartResponse(session_id="session-123", started_at=now)
    assert resp.session_id == "session-123"
    assert resp.started_at == now


def test_metric_item():
    now = datetime.now(timezone.utc)
    
    # Full metric
    metric = MetricItem(
        t=now,
        hr=120.5,
        hrv=45.2,
        rep=3,
        rom=0.75,
        tempo=1.5,
        error_flags=["depth", "valgus"]
    )
    assert metric.t == now
    assert metric.hr == 120.5
    assert metric.error_flags == ["depth", "valgus"]
    
    # Minimal metric
    minimal = MetricItem(t=now)
    assert minimal.t == now
    assert minimal.hr is None
    assert minimal.error_flags is None


def test_metrics_batch_request():
    now = datetime.now(timezone.utc)
    metrics = [
        MetricItem(t=now, hr=120, rep=1),
        MetricItem(t=now, hr=125, rep=2, error_flags=["tempo_fast"])
    ]
    
    batch = MetricsBatchRequest(session_id="session-123", metrics=metrics)
    assert batch.session_id == "session-123"
    assert len(batch.metrics) == 2
    assert batch.metrics[0].hr == 120
    assert batch.metrics[1].error_flags == ["tempo_fast"]


def test_metrics_batch_response():
    resp = MetricsBatchResponse(accepted=5)
    assert resp.accepted == 5


def test_plan_item():
    now = datetime.now(timezone.utc)
    item = PlanItem(date=now, workout="squat", intensity=1.0)
    assert item.date == now
    assert item.workout == "squat"
    assert item.intensity == 1.0


def test_plan_today_response():
    now = datetime.now(timezone.utc)
    items = [
        PlanItem(date=now, workout="squat", intensity=1.0),
        PlanItem(date=now, workout="deadlift", intensity=0.8)
    ]
    
    resp = PlanTodayResponse(items=items)
    assert len(resp.items) == 2
    assert resp.items[0].workout == "squat"
    assert resp.items[1].intensity == 0.8

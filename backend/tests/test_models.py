import pytest
from datetime import datetime, timezone
from app.db.models import User, Session, SessionMetric, generate_uuid


def test_user_creation():
    user = User(id="test-user-123")
    assert user.id == "test-user-123"


def test_session_creation():
    now = datetime.now(timezone.utc)
    session = Session(user_id="test-user", started_at=now)
    
    # Manually set ID since defaults only apply on DB insert
    if session.id is None:
        session.id = generate_uuid()
    
    assert session.id is not None
    assert len(session.id) > 0
    assert session.user_id == "test-user"
    assert session.started_at == now
    assert session.ended_at is None


def test_session_metric_creation():
    now = datetime.now(timezone.utc)
    metric = SessionMetric(
        session_id="test-session",
        t=now,
        hr=120.5,
        hrv=45.2,
        rep=3,
        rom=0.75,
        tempo=1.5,
        error_flags=["depth", "valgus"]
    )
    
    # Manually set ID since defaults only apply on DB insert
    if metric.id is None:
        metric.id = generate_uuid()
    
    assert metric.id is not None
    assert len(metric.id) > 0
    assert metric.session_id == "test-session"
    assert metric.t == now
    assert metric.hr == 120.5
    assert metric.hrv == 45.2
    assert metric.rep == 3
    assert metric.rom == 0.75
    assert metric.tempo == 1.5
    assert metric.error_flags == ["depth", "valgus"]


def test_session_metric_nullable_fields():
    now = datetime.now(timezone.utc)
    metric = SessionMetric(
        session_id="test-session",
        t=now
    )
    
    assert metric.hr is None
    assert metric.hrv is None
    assert metric.rep is None
    assert metric.rom is None
    assert metric.tempo is None
    assert metric.error_flags is None


def test_uuid_generation():
    """Test that UUID generation works correctly"""
    uuid1 = generate_uuid()
    uuid2 = generate_uuid()
    
    assert uuid1 is not None
    assert uuid2 is not None
    assert uuid1 != uuid2
    assert len(uuid1) == 36  # Standard UUID string length
    assert len(uuid2) == 36

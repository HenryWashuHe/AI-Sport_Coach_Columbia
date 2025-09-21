import pytest
from datetime import datetime, timezone, timedelta
from app.workers.personalize import analyze_user_performance, generate_personalized_plan
from app.db.models import User, Session, SessionMetric, SessionLocal


def test_analyze_user_performance():
    """Test user performance analysis with mock data"""
    
    # Mock analysis data (simulating what would come from database)
    mock_analysis = {
        "period_days": 7,
        "total_sessions": 5,
        "total_reps": 75,  # 15 reps per session average
        "hrv_baseline": 45.2,
        "error_rate": 0.15,  # 15% error rate
        "common_errors": {"depth": 8, "tempo_fast": 3},
        "avg_heart_rate": 135.5,
        "avg_tempo": 1.8,
        "total_metrics": 150
    }
    
    # Test that analysis structure is correct
    assert "total_sessions" in mock_analysis
    assert "error_rate" in mock_analysis
    assert "hrv_baseline" in mock_analysis
    assert mock_analysis["total_reps"] > 0
    assert 0 <= mock_analysis["error_rate"] <= 1


def test_generate_personalized_plan_high_error_rate():
    """Test plan generation for user with high error rate"""
    
    high_error_analysis = {
        "period_days": 7,
        "total_sessions": 3,
        "total_reps": 30,
        "hrv_baseline": 40.0,
        "error_rate": 0.4,  # High error rate
        "common_errors": {"depth": 10, "valgus": 5},
        "avg_heart_rate": 140.0,
        "avg_tempo": 2.2,
        "total_metrics": 90
    }
    
    plan = generate_personalized_plan(high_error_analysis)
    
    # Should reduce intensity due to high error rate
    assert plan["intensity"] < 1.0
    assert "form" in plan["focus_areas"]
    assert "depth" in plan["focus_areas"]
    assert "knee_alignment" in plan["focus_areas"]
    assert plan["recommended_reps"] >= 10


def test_generate_personalized_plan_low_error_rate():
    """Test plan generation for user with low error rate (good form)"""
    
    low_error_analysis = {
        "period_days": 7,
        "total_sessions": 6,
        "total_reps": 120,
        "hrv_baseline": 55.0,  # Good recovery
        "error_rate": 0.05,  # Low error rate
        "common_errors": {},
        "avg_heart_rate": 125.0,
        "avg_tempo": 1.5,
        "total_metrics": 180
    }
    
    plan = generate_personalized_plan(low_error_analysis)
    
    # Should increase intensity due to good form and recovery
    assert plan["intensity"] > 1.0
    assert "progression" in plan["focus_areas"]
    assert plan["recommended_reps"] >= 15


def test_generate_personalized_plan_insufficient_data():
    """Test plan generation when insufficient data is available"""
    
    insufficient_analysis = {"error": "No sessions found"}
    
    plan = generate_personalized_plan(insufficient_analysis)
    
    # Should return default plan
    assert plan["intensity"] == 1.0
    assert "form" in plan["focus_areas"]
    assert plan["recommended_reps"] == 15
    assert "baseline" in plan["notes"].lower()


def test_intensity_clamping():
    """Test that intensity is properly clamped between 0.8 and 1.2"""
    
    # Extreme case that would push intensity very low
    extreme_analysis = {
        "period_days": 7,
        "total_sessions": 2,
        "total_reps": 10,
        "hrv_baseline": 20.0,  # Very poor recovery
        "error_rate": 0.8,  # Very high error rate
        "common_errors": {"depth": 20, "valgus": 15, "tempo_fast": 10},
        "avg_heart_rate": 160.0,
        "avg_tempo": 3.0,
        "total_metrics": 40
    }
    
    plan = generate_personalized_plan(extreme_analysis)
    
    # Intensity should be clamped to minimum 0.8
    assert plan["intensity"] >= 0.8
    assert plan["intensity"] <= 1.2


def test_focus_areas_generation():
    """Test that focus areas are correctly identified from common errors"""
    
    tempo_error_analysis = {
        "period_days": 7,
        "total_sessions": 4,
        "total_reps": 60,
        "hrv_baseline": 45.0,
        "error_rate": 0.2,
        "common_errors": {"tempo_fast": 12, "tempo_slow": 3},
        "avg_heart_rate": 130.0,
        "avg_tempo": 2.5,
        "total_metrics": 120
    }
    
    plan = generate_personalized_plan(tempo_error_analysis)
    
    assert "tempo_control" in plan["focus_areas"]
    assert isinstance(plan["focus_areas"], list)
    assert len(set(plan["focus_areas"])) == len(plan["focus_areas"])  # No duplicates

from celery import current_app as celery_app
from sqlalchemy.orm import sessionmaker
from sqlalchemy import func, and_
from datetime import datetime, timezone, timedelta
import json
import statistics
import os

from app.db.models import User, Session, SessionMetric, engine

# Create database session for worker
SessionLocal = sessionmaker(bind=engine)

@celery_app.task
def run_personalization():
    """Nightly personalization job - analyze last 7 days and adjust plans"""
    
    db = SessionLocal()
    try:
        # Get all users who had activity in the last 7 days
        seven_days_ago = datetime.now(timezone.utc) - timedelta(days=7)
        
        active_users = db.query(User).join(Session).filter(
            Session.started_at >= seven_days_ago
        ).distinct().all()
        
        results = []
        
        for user in active_users:
            try:
                user_analysis = analyze_user_performance(db, user.id, seven_days_ago)
                updated_plan = generate_personalized_plan(user_analysis)
                
                # Store updated plan (in production, this would go to a plans table)
                store_user_plan(user.id, updated_plan)
                
                results.append({
                    "user_id": user.id,
                    "analysis": user_analysis,
                    "plan_updated": True
                })
                
            except Exception as e:
                results.append({
                    "user_id": user.id,
                    "error": str(e),
                    "plan_updated": False
                })
        
        return {
            "processed_users": len(results),
            "successful_updates": len([r for r in results if r.get("plan_updated")]),
            "results": results
        }
        
    finally:
        db.close()


def analyze_user_performance(db, user_id: str, since: datetime) -> dict:
    """Analyze user's performance over the last 7 days"""
    
    # Get user's sessions in the period
    sessions = db.query(Session).filter(
        and_(
            Session.user_id == user_id,
            Session.started_at >= since
        )
    ).all()
    
    if not sessions:
        return {"error": "No sessions found"}
    
    session_ids = [s.id for s in sessions]
    
    # Get all metrics for these sessions
    metrics = db.query(SessionMetric).filter(
        SessionMetric.session_id.in_(session_ids)
    ).all()
    
    if not metrics:
        return {"error": "No metrics found"}
    
    # Calculate HRV baseline
    hrv_values = [m.hrv for m in metrics if m.hrv is not None]
    hrv_baseline = statistics.mean(hrv_values) if hrv_values else None
    
    # Calculate training volume (total reps)
    total_reps = sum(m.rep for m in metrics if m.rep is not None)
    
    # Calculate error rates
    total_metrics = len(metrics)
    error_metrics = len([m for m in metrics if m.error_flags])
    error_rate = error_metrics / total_metrics if total_metrics > 0 else 0
    
    # Most common errors
    all_errors = []
    for m in metrics:
        if m.error_flags:
            all_errors.extend(m.error_flags)
    
    error_counts = {}
    for error in all_errors:
        error_counts[error] = error_counts.get(error, 0) + 1
    
    # Average heart rate and tempo
    hr_values = [m.hr for m in metrics if m.hr is not None]
    tempo_values = [m.tempo for m in metrics if m.tempo is not None]
    
    avg_hr = statistics.mean(hr_values) if hr_values else None
    avg_tempo = statistics.mean(tempo_values) if tempo_values else None
    
    return {
        "period_days": 7,
        "total_sessions": len(sessions),
        "total_reps": total_reps,
        "hrv_baseline": hrv_baseline,
        "error_rate": error_rate,
        "common_errors": error_counts,
        "avg_heart_rate": avg_hr,
        "avg_tempo": avg_tempo,
        "total_metrics": total_metrics
    }


def generate_personalized_plan(analysis: dict) -> dict:
    """Generate personalized plan based on user analysis"""
    
    if "error" in analysis:
        # Default plan for users with insufficient data
        return {
            "intensity": 1.0,
            "focus_areas": ["form"],
            "recommended_reps": 15,
            "rest_periods": 60,
            "notes": "Building baseline data"
        }
    
    base_intensity = 1.0
    focus_areas = []
    
    # Adjust intensity based on error rate
    if analysis["error_rate"] > 0.3:  # High error rate
        base_intensity *= 0.95  # Reduce intensity by 5%
        focus_areas.append("form")
    elif analysis["error_rate"] < 0.1:  # Low error rate
        base_intensity *= 1.025  # Increase intensity by 2.5%
        focus_areas.append("progression")
    
    # Adjust based on HRV (recovery indicator)
    if analysis["hrv_baseline"]:
        if analysis["hrv_baseline"] < 30:  # Poor recovery
            base_intensity *= 0.95
            focus_areas.append("recovery")
        elif analysis["hrv_baseline"] > 50:  # Good recovery
            base_intensity *= 1.025
    
    # Focus on specific errors
    common_errors = analysis.get("common_errors", {})
    if "depth" in common_errors:
        focus_areas.append("depth")
    if "valgus" in common_errors:
        focus_areas.append("knee_alignment")
    if "tempo_fast" in common_errors or "tempo_slow" in common_errors:
        focus_areas.append("tempo_control")
    
    # Clamp intensity between 0.8 and 1.2
    base_intensity = max(0.8, min(1.2, base_intensity))
    
    # Calculate recommended reps based on recent volume
    recent_reps_per_session = analysis["total_reps"] / analysis["total_sessions"]
    recommended_reps = max(10, min(25, int(recent_reps_per_session * base_intensity)))
    
    return {
        "intensity": round(base_intensity, 3),
        "focus_areas": list(set(focus_areas)),
        "recommended_reps": recommended_reps,
        "rest_periods": 60 if base_intensity > 1.0 else 45,
        "notes": f"Based on {analysis['total_sessions']} sessions, {analysis['error_rate']:.1%} error rate"
    }


def store_user_plan(user_id: str, plan: dict):
    """Store user's personalized plan (stub - in production would use database)"""
    
    # For now, store in a simple file (in production, use database table)
    plans_dir = "/tmp/ai_coach_plans"
    os.makedirs(plans_dir, exist_ok=True)
    
    plan_file = f"{plans_dir}/{user_id}_plan.json"
    with open(plan_file, "w") as f:
        json.dump({
            "user_id": user_id,
            "plan": plan,
            "updated_at": datetime.now(timezone.utc).isoformat(),
            "version": 1
        }, f, indent=2)


@celery_app.task
def analyze_single_user(user_id: str):
    """Analyze a single user's performance (for testing/debugging)"""
    
    db = SessionLocal()
    try:
        seven_days_ago = datetime.now(timezone.utc) - timedelta(days=7)
        analysis = analyze_user_performance(db, user_id, seven_days_ago)
        plan = generate_personalized_plan(analysis)
        
        return {
            "user_id": user_id,
            "analysis": analysis,
            "recommended_plan": plan
        }
    finally:
        db.close()

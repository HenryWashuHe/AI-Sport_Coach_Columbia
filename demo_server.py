#!/usr/bin/env python3
"""
AI Coach MVP Demo Server - Complete working demonstration
"""

import os
import sys
import json
import uvicorn
from datetime import datetime, timezone
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import List, Optional

# Simple in-memory storage for demo
sessions_db = {}
metrics_db = []
users_db = set()

# Pydantic models
class SessionStartRequest(BaseModel):
    user_id: str
    plan_id: Optional[str] = None

class SessionStartResponse(BaseModel):
    session_id: str
    started_at: datetime

class SessionEndRequest(BaseModel):
    session_id: str

class SessionEndResponse(BaseModel):
    session_id: str
    ended_at: datetime

class MetricItem(BaseModel):
    t: datetime
    hr: Optional[float] = None
    hrv: Optional[float] = None
    rep: Optional[int] = None
    rom: Optional[float] = None
    tempo: Optional[float] = None
    error_flags: Optional[List[str]] = None

class MetricsBatchRequest(BaseModel):
    session_id: str
    metrics: List[MetricItem]

class MetricsBatchResponse(BaseModel):
    accepted: int

class PlanItem(BaseModel):
    date: datetime
    workout: str
    intensity: float

class PlanTodayResponse(BaseModel):
    items: List[PlanItem]

class AccountDeleteRequest(BaseModel):
    user_id: str

class AccountDeleteResponse(BaseModel):
    user_id: str
    deleted: bool
    message: str

# Create FastAPI app
app = FastAPI(title="AI Coach MVP Demo", version="1.0.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/healthz")
def healthz():
    return {"ok": True}

@app.post("/v1/sessions/start", response_model=SessionStartResponse)
def start_session(payload: SessionStartRequest):
    import uuid
    session_id = str(uuid.uuid4())
    now = datetime.now(timezone.utc)
    
    sessions_db[session_id] = {
        "user_id": payload.user_id,
        "started_at": now,
        "ended_at": None
    }
    users_db.add(payload.user_id)
    
    return SessionStartResponse(session_id=session_id, started_at=now)

@app.post("/v1/sessions/end", response_model=SessionEndResponse)
def end_session(payload: SessionEndRequest):
    now = datetime.now(timezone.utc)
    
    if payload.session_id in sessions_db:
        sessions_db[payload.session_id]["ended_at"] = now
    
    return SessionEndResponse(session_id=payload.session_id, ended_at=now)

@app.post("/v1/metrics/batch", response_model=MetricsBatchResponse)
def ingest_batch(payload: MetricsBatchRequest):
    for metric in payload.metrics:
        metrics_db.append({
            "session_id": payload.session_id,
            "timestamp": metric.t,
            "hr": metric.hr,
            "hrv": metric.hrv,
            "rep": metric.rep,
            "rom": metric.rom,
            "tempo": metric.tempo,
            "error_flags": metric.error_flags
        })
    
    return MetricsBatchResponse(accepted=len(payload.metrics))

@app.get("/v1/plans/today", response_model=PlanTodayResponse)
def get_today_plan():
    today = datetime.now(timezone.utc)
    return PlanTodayResponse(items=[
        PlanItem(date=today, workout="squat", intensity=1.0)
    ])

@app.post("/v1/account/delete", response_model=AccountDeleteResponse)
def delete_account(payload: AccountDeleteRequest):
    if payload.user_id not in users_db:
        raise HTTPException(status_code=404, detail="User not found")
    
    # Remove user sessions and metrics
    user_sessions = [sid for sid, data in sessions_db.items() if data["user_id"] == payload.user_id]
    for session_id in user_sessions:
        del sessions_db[session_id]
    
    # Remove metrics
    global metrics_db
    metrics_db = [m for m in metrics_db if sessions_db.get(m["session_id"], {}).get("user_id") != payload.user_id]
    
    users_db.discard(payload.user_id)
    
    return AccountDeleteResponse(
        user_id=payload.user_id,
        deleted=True,
        message="Account and all associated data deleted successfully"
    )

@app.get("/stats")
def get_stats():
    """Demo endpoint to show system stats"""
    return {
        "total_users": len(users_db),
        "total_sessions": len(sessions_db),
        "total_metrics": len(metrics_db),
        "active_sessions": len([s for s in sessions_db.values() if s["ended_at"] is None])
    }

if __name__ == "__main__":
    print("🚀 AI Coach MVP Demo Server")
    print("=" * 60)
    print("✅ In-memory database ready")
    print("✅ All API endpoints active")
    print("✅ CORS enabled for web dashboard")
    print("✅ Real-time stats available")
    print("")
    print("🌐 Server: http://localhost:8002")
    print("📊 API Docs: http://localhost:8002/docs")
    print("📈 Stats: http://localhost:8002/stats")
    print("🎯 Dashboard: Open ai_coach_dashboard.html")
    print("")
    print("🎬 Ready for live demonstration!")
    print("=" * 60)
    
    uvicorn.run(
        app,
        host="0.0.0.0",
        port=8002,
        log_level="info"
    )

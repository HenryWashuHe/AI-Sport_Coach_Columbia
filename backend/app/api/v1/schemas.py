from typing import List, Optional
from pydantic import BaseModel, Field
from datetime import datetime

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
    error_flags: Optional[List[str]] = Field(default=None)

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

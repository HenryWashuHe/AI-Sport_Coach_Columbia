from fastapi import APIRouter
from datetime import datetime, timezone
from ..schemas import PlanItem, PlanTodayResponse

router = APIRouter(prefix="/v1/plans", tags=["plans"])

@router.get("/today", response_model=PlanTodayResponse)
def get_today_plan():
    today = datetime.now(timezone.utc)
    return PlanTodayResponse(items=[
        PlanItem(date=today, workout="squat", intensity=1.0)
    ])

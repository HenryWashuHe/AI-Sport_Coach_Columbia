from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session as SASession
from app.api.v1.schemas import MetricsBatchRequest, MetricsBatchResponse
from app.db.models import SessionMetric, get_db

router = APIRouter(prefix="/v1/metrics", tags=["metrics"])

@router.post("/batch", response_model=MetricsBatchResponse)
def ingest_batch(payload: MetricsBatchRequest, db: SASession = Depends(get_db)):
    rows = []
    for m in payload.metrics:
        rows.append(
            SessionMetric(
                session_id=payload.session_id,
                t=m.t,
                hr=m.hr,
                hrv=m.hrv,
                rep=m.rep,
                rom=m.rom,
                tempo=m.tempo,
                error_flags=m.error_flags
            )
        )
    if rows:
        db.add_all(rows)
        db.commit()
    return MetricsBatchResponse(accepted=len(rows))

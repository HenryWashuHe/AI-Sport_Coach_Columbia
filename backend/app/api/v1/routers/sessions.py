from fastapi import APIRouter, Depends
from datetime import datetime, timezone
import uuid
from app.db.models import Session, User, get_db
from sqlalchemy.orm import Session as SASession
from ..schemas import SessionStartRequest, SessionStartResponse, SessionEndRequest, SessionEndResponse

router = APIRouter(prefix="/v1/sessions", tags=["sessions"])

@router.post("/start", response_model=SessionStartResponse)
def start_session(payload: SessionStartRequest, db: SASession = Depends(get_db)):
    user = db.query(User).filter(User.id == payload.user_id).first()
    if not user:
        user = User(id=payload.user_id)
        db.add(user)
    now = datetime.now(timezone.utc)
    s = Session(id=str(uuid.uuid4()), user_id=user.id, started_at=now)
    db.add(s)
    db.commit()
    return SessionStartResponse(session_id=s.id, started_at=now)

@router.post("/end", response_model=SessionEndResponse)
def end_session(payload: SessionEndRequest, db: SASession = Depends(get_db)):
    s = db.query(Session).filter(Session.id == payload.session_id).first()
    now = datetime.now(timezone.utc)
    if s and s.ended_at is None:
        s.ended_at = now
        db.commit()
    return SessionEndResponse(session_id=payload.session_id, ended_at=now)

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session as SASession
from app.db.models import User, Session, SessionMetric, get_db
from ..schemas import AccountDeleteRequest, AccountDeleteResponse

router = APIRouter(prefix="/v1/account", tags=["accounts"])

@router.post("/delete", response_model=AccountDeleteResponse)
def delete_account(payload: AccountDeleteRequest, db: SASession = Depends(get_db)):
    # Find user
    user = db.query(User).filter(User.id == payload.user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    
    # Delete all user's session metrics
    user_sessions = db.query(Session).filter(Session.user_id == user.id).all()
    session_ids = [s.id for s in user_sessions]
    
    if session_ids:
        db.query(SessionMetric).filter(SessionMetric.session_id.in_(session_ids)).delete(synchronize_session=False)
    
    # Delete all user's sessions
    db.query(Session).filter(Session.user_id == user.id).delete(synchronize_session=False)
    
    # Delete user
    db.delete(user)
    db.commit()
    
    return AccountDeleteResponse(
        user_id=payload.user_id,
        deleted=True,
        message="Account and all associated data deleted successfully"
    )

from sqlalchemy import Column, String, DateTime, Float, Integer, JSON, ForeignKey, create_engine
from sqlalchemy.orm import declarative_base, sessionmaker
from sqlalchemy.orm import Session as SASession
import os
import uuid

DATABASE_URL = os.getenv("DATABASE_URL", "postgresql+psycopg2://postgres:postgres@localhost:5432/aicoach")
engine = create_engine(DATABASE_URL, future=True)
SessionLocal = sessionmaker(bind=engine, autoflush=False, autocommit=False, future=True)
Base = declarative_base()

class User(Base):
    __tablename__ = "users"
    id = Column(String, primary_key=True)

class Session(Base):
    __tablename__ = "sessions"
    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    user_id = Column(String, ForeignKey("users.id"), nullable=False)
    started_at = Column(DateTime(timezone=True), nullable=False)
    ended_at = Column(DateTime(timezone=True), nullable=True)

class SessionMetric(Base):
    __tablename__ = "session_metrics"
    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    session_id = Column(String, ForeignKey("sessions.id"), nullable=False)
    t = Column(DateTime(timezone=True), nullable=False, index=True)
    hr = Column(Float, nullable=True)
    hrv = Column(Float, nullable=True)
    rep = Column(Integer, nullable=True)
    rom = Column(Float, nullable=True)
    tempo = Column(Float, nullable=True)
    error_flags = Column(JSON, nullable=True)

# Dependency

def get_db() -> SASession:
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

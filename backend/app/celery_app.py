from celery import Celery
from app.config import settings

celery_app = Celery(
    "ai_coach",
    broker=settings.celery_broker_url,
    backend=settings.celery_result_backend,
    include=["app.workers.personalize"]
)

# Celery configuration
celery_app.conf.update(
    task_serializer="json",
    accept_content=["json"],
    result_serializer="json",
    timezone="UTC",
    enable_utc=True,
    beat_schedule={
        "nightly-personalization": {
            "task": "app.workers.personalize.run_personalization",
            "schedule": 3600.0 * 24,  # Daily at midnight
        },
    },
)

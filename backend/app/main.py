from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.api.v1.routers.sessions import router as sessions_router
from app.api.v1.routers.metrics import router as metrics_router
from app.api.v1.routers.plans import router as plans_router

app = FastAPI(title="AI Coach API", version="0.1.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(sessions_router)
app.include_router(metrics_router)
app.include_router(plans_router)


@app.get("/healthz")
def healthz():
    return {"ok": True}

# AI Coach (MVP Bootstrap)

This is the starter scaffold created for Phase 0.

## What's here
- `server/` minimal FastAPI app with a `/health` endpoint
- `server/docker-compose.yml` for TimescaleDB (Postgres) + Redis
- `server/requirements.txt` for backend dependencies
- `.env.example` for backend environment variables

## Quickstart
```bash
cd server
# bring up DB + Redis
docker compose up -d

# create venv & install deps
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt

# run API
uvicorn app.main:app --reload
# -> visit http://localhost:8000/health
```

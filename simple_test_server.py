#!/usr/bin/env python3
"""
Simple test server for AI Coach MVP - works without PostgreSQL
Uses in-memory SQLite for quick testing and demonstration
"""

import os
import sys
import uvicorn
from datetime import datetime, timezone

# Set environment for testing
os.environ["TESTING"] = "1"
os.environ["DATABASE_URL"] = "sqlite:///:memory:"

# Add backend to path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), 'backend'))

try:
    from app.main import app
    from app.db.models import Base, engine, User, Session, SessionMetric
    
    # Create all tables
    print("🔧 Creating database tables...")
    Base.metadata.drop_all(bind=engine)  # Clean slate
    Base.metadata.create_all(bind=engine)
    
    # Verify tables were created
    from sqlalchemy import inspect
    inspector = inspect(engine)
    tables = inspector.get_table_names()
    print(f"✅ Created tables: {', '.join(tables)}")
    
    print("🚀 AI Coach MVP Test Server")
    print("=" * 50)
    print("✅ Database: In-memory SQLite")
    print("✅ All tables created")
    print("✅ API endpoints ready")
    print("✅ CORS enabled")
    print("")
    print("🌐 Server starting on: http://localhost:8002")
    print("📊 API Documentation: http://localhost:8002/docs")
    print("🎯 Test Dashboard: Open ai_coach_dashboard.html")
    print("")
    print("Press Ctrl+C to stop the server")
    print("=" * 50)
    
    if __name__ == "__main__":
        uvicorn.run(
            app, 
            host="0.0.0.0", 
            port=8002, 
            log_level="info",
            reload=False
        )
        
except ImportError as e:
    print(f"❌ Import error: {e}")
    print("💡 Make sure you're in the ai-coach directory and have installed dependencies:")
    print("   cd /Users/heshi/Downloads/ai-coach")
    print("   backend/.venv/bin/python simple_test_server.py")
    sys.exit(1)
except Exception as e:
    print(f"❌ Error starting server: {e}")
    sys.exit(1)

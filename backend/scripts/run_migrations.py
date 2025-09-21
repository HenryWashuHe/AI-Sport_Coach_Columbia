#!/usr/bin/env python3
"""
Script to run database migrations
"""
import subprocess
import sys
import os
from pathlib import Path

def run_migrations():
    """Run Alembic migrations"""
    
    # Change to backend directory
    backend_dir = Path(__file__).parent.parent
    os.chdir(backend_dir)
    
    try:
        # Run migrations
        print("Running database migrations...")
        result = subprocess.run(
            ["alembic", "upgrade", "head"],
            check=True,
            capture_output=True,
            text=True
        )
        print("✅ Migrations completed successfully")
        print(result.stdout)
        
    except subprocess.CalledProcessError as e:
        print("❌ Migration failed:")
        print(e.stderr)
        sys.exit(1)
    except FileNotFoundError:
        print("❌ Alembic not found. Make sure it's installed:")
        print("pip install alembic")
        sys.exit(1)

if __name__ == "__main__":
    run_migrations()

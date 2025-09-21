import os
import pytest
from app.config import Settings


def test_default_settings():
    """Test default settings values"""
    # Clear test environment variables
    testing_val = os.environ.pop("TESTING", None)
    db_url_val = os.environ.pop("DATABASE_URL", None)
    
    try:
        settings = Settings()
        
        assert settings.api_host == "0.0.0.0"
        assert settings.api_port == 8000
        assert settings.debug is False
        assert settings.algorithm == "HS256"
        assert settings.log_level == "INFO"
        assert "postgresql" in settings.database_url
        assert "redis" in settings.redis_url
        
    finally:
        # Restore environment variables if they were set
        if testing_val is not None:
            os.environ["TESTING"] = testing_val
        if db_url_val is not None:
            os.environ["DATABASE_URL"] = db_url_val


def test_settings_from_env():
    """Test settings loading from environment variables"""
    
    # Set environment variables
    os.environ["API_PORT"] = "9000"
    os.environ["DEBUG"] = "true"
    os.environ["LOG_LEVEL"] = "DEBUG"
    os.environ["AWS_REGION"] = "us-east-1"
    
    try:
        settings = Settings()
        
        assert settings.api_port == 9000
        assert settings.debug is True
        assert settings.log_level == "DEBUG"
        assert settings.aws_region == "us-east-1"
        
    finally:
        # Clean up environment variables
        for key in ["API_PORT", "DEBUG", "LOG_LEVEL", "AWS_REGION"]:
            os.environ.pop(key, None)


def test_cors_origins_list():
    """Test that CORS origins is properly handled as a list"""
    settings = Settings()
    
    assert isinstance(settings.allowed_origins, list)
    assert len(settings.allowed_origins) > 0
    assert all(isinstance(origin, str) for origin in settings.allowed_origins)


def test_database_url_override_for_testing():
    """Test that database URL can be overridden for testing"""
    
    # Set testing environment
    os.environ["TESTING"] = "1"
    
    try:
        # Import settings after setting TESTING env var
        from app.config import Settings
        settings = Settings()
        
        # Should use SQLite for testing
        assert "sqlite" in settings.database_url.lower()
        
    finally:
        os.environ.pop("TESTING", None)


def test_required_vs_optional_settings():
    """Test that settings have appropriate defaults"""
    settings = Settings()
    
    # These should have sensible defaults
    assert settings.secret_key is not None
    assert settings.api_host is not None
    assert settings.database_url is not None
    
    # AWS settings can be empty (optional)
    assert isinstance(settings.aws_access_key_id, str)  # Can be empty string
    assert isinstance(settings.s3_bucket_name, str)


def test_celery_settings():
    """Test Celery-specific settings"""
    settings = Settings()
    
    assert settings.celery_broker_url is not None
    assert settings.celery_result_backend is not None
    assert "redis" in settings.celery_broker_url.lower()
    assert "redis" in settings.celery_result_backend.lower()

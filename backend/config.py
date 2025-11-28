import os
from datetime import timedelta

# Get absolute path to database in the same directory as this config file
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
DB_PATH = os.path.join(BASE_DIR, 'freshreminder.db')

class Config:
    """Base configuration"""
    # Database
    # SQLite database in the backend directory
    SQLALCHEMY_DATABASE_URI = os.getenv(
        'DATABASE_URL',
        f'sqlite:///{DB_PATH}'
    )
    SQLALCHEMY_TRACK_MODIFICATIONS = False
    
    # JWT
    JWT_SECRET_KEY = os.getenv('JWT_SECRET_KEY', 'your-secret-key-change-in-production')
    JWT_ACCESS_TOKEN_EXPIRES = timedelta(days=30)
    
    # Flask
    DEBUG = os.getenv('FLASK_ENV', 'development') == 'development'


class DevelopmentConfig(Config):
    """Development configuration"""
    DEBUG = True
    TESTING = False


class ProductionConfig(Config):
    """Production configuration"""
    DEBUG = False
    TESTING = False
    # In production, use proper database like PostgreSQL
    SQLALCHEMY_DATABASE_URI = os.getenv(
        'DATABASE_URL',
        'postgresql://user:password@localhost/freshreminder'
    )


class TestingConfig(Config):
    """Testing configuration"""
    TESTING = True
    SQLALCHEMY_DATABASE_URI = 'sqlite:///:memory:'


# Select configuration based on environment
config_name = os.getenv('FLASK_ENV', 'development')
if config_name == 'production':
    config = ProductionConfig()
elif config_name == 'testing':
    config = TestingConfig()
else:
    config = DevelopmentConfig()

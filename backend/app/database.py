import os

from sqlalchemy import create_engine
from sqlalchemy.orm import declarative_base, sessionmaker


# For local non-Docker testing, this fallback can be changed later.
DATABASE_URL = os.getenv(
    "DATABASE_URL",
    "postgresql+psycopg://requestflow_user:requestflow_password@localhost:5432/requestflow_db"
)


# The engine manages the connection between FastAPI and PostgreSQL.
engine = create_engine(DATABASE_URL)


# SessionLocal creates database sessions.
# Each API request will use a session to talk to the database.
SessionLocal = sessionmaker(
    autocommit=False,
    autoflush=False,
    bind=engine
)


# Base is used by SQLAlchemy models.
# All database models will inherit from this.
Base = declarative_base()


def get_db():
    """
    Provides a database session to FastAPI routes.

    Flow:
    1. Create a database session.
    2. Give it to the route.
    3. Close it after the request is done.
    """
    db = SessionLocal()

    try:
        yield db
    finally:
        db.close()
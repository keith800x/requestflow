import os

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool

os.environ["ENVIRONMENT"] = "test"

from app.database import Base, get_db
from app.enums import UserRole

# Import all models so SQLAlchemy knows every table.
from app.models.user import User  # noqa: F401
from app.models.request import ServiceRequest  # noqa: F401
from app.models.comment import Comment  # noqa: F401

from app.main import app
from app.services.security_service import create_access_token, hash_password


TEST_DATABASE_URL = "sqlite://"


test_engine = create_engine(
    TEST_DATABASE_URL,
    connect_args={
        "check_same_thread": False
    },
    poolclass=StaticPool
)


TestingSessionLocal = sessionmaker(
    autocommit=False,
    autoflush=False,
    bind=test_engine
)


def override_get_db():
    db = TestingSessionLocal()

    try:
        yield db
    finally:
        db.close()


app.dependency_overrides[get_db] = override_get_db


@pytest.fixture(autouse=True)
def reset_test_database():
    """
    Reset the whole in-memory database before each test.
    """

    Base.metadata.drop_all(bind=test_engine)
    Base.metadata.create_all(bind=test_engine)

    yield


@pytest.fixture
def client():
    """
    Shared FastAPI test client.
    """

    return TestClient(app)


@pytest.fixture
def create_test_user():
    """
    Creates a user and returns:
    - user object
    - auth headers with JWT token
    """

    def _create_test_user(
        email: str = "user@example.com",
        role: UserRole = UserRole.USER
    ):
        db = TestingSessionLocal()

        user = User(
            name="Test User",
            email=email,
            password_hash=hash_password("password123"),
            role=role.value
        )

        db.add(user)
        db.commit()
        db.refresh(user)

        token = create_access_token(
            data={
                "sub": str(user.id),
                "email": user.email,
                "role": user.role
            }
        )

        headers = {
            "Authorization": f"Bearer {token}"
        }

        db.close()

        return user, headers

    return _create_test_user


@pytest.fixture
def create_test_request(client):
    """
    Creates a test service request using the API.
    """

    def _create_test_request(headers: dict[str, str]) -> int:
        response = client.post(
            "/requests/",
            json={
                "title": "Laptop Wi-Fi issue",
                "description": "My laptop disconnects from Wi-Fi during meetings.",
                "category": "Network",
                "priority": "Medium"
            },
            headers=headers
        )

        assert response.status_code == 201

        return response.json()["id"]

    return _create_test_request
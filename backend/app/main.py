import os

from fastapi import FastAPI, Request, Depends

from fastapi.exceptions import RequestValidationError
from fastapi.responses import JSONResponse
from starlette.exceptions import HTTPException as StarletteHTTPException

from app.database import get_db
from app.models import comment, request, user
from app.routers import auth_router, comment_router, request_router

from fastapi.middleware.cors import CORSMiddleware

from sqlalchemy import text
from sqlalchemy.orm import Session

from prometheus_fastapi_instrumentator import Instrumentator

# Create database tables.
# Later, we can replace this with Alembic migrations.

ENVIRONMENT = os.getenv("ENVIRONMENT", "development")

JWT_SECRET_KEY = os.getenv("JWT_SECRET_KEY")

if ENVIRONMENT == "production" and not JWT_SECRET_KEY:
    raise RuntimeError("JWT_SECRET_KEY must be set in production.")

if not JWT_SECRET_KEY:
    JWT_SECRET_KEY = "dev-secret-key-change-this-later"



app = FastAPI(
    title="RequestFlow API",
    description="Backend API for the RequestFlow IT service request tracker.",
    version="1.0.0",
)

allowed_origins = os.getenv(
    "ALLOWED_ORIGINS",
    "http://localhost:5173,http://localhost:5174"
).split(",")

app.add_middleware(
    CORSMiddleware,
    allow_origins=[origin.strip() for origin in allowed_origins],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

instrumentator = Instrumentator(
    should_respect_env_var=True,
    env_var_name="ENABLE_METRICS",
    excluded_handlers=["/metrics"],
)

instrumentator.instrument(app).expose(
    app,
    include_in_schema=False,
)

@app.exception_handler(RequestValidationError)
async def validation_exception_handler(
    request: Request,
    exc: RequestValidationError
):
    """
    Handles validation errors.

    Example:
    Invalid priority, missing title, or description too short.
    """

    return JSONResponse(
        status_code=422,
        content={
            "error": "Validation error.",
            "details": exc.errors()
        }
    )


@app.exception_handler(StarletteHTTPException)
async def http_exception_handler(
    request: Request,
    exc: StarletteHTTPException
):
    """
    Handles normal HTTP errors.

    Example:
    404 service request not found.
    """

    return JSONResponse(
        status_code=exc.status_code,
        content={
            "error": exc.detail
        }
    )

@app.get("/")
def root():
    """
    Simple root endpoint.
    """

    return {
        "message": "RequestFlow API is running."
    }

@app.get("/ready")
def readiness_check(db: Session = Depends(get_db)):
    """
    Readiness check.

    Used by Docker/Kubernetes to check if the API can connect to the database.
    """
    db.execute(text("SELECT 1"))
    return {"status": "ready"}


@app.get("/health")
def health_check():
    """
    Health/Liveness check check endpoint.

    Useful for Docker, deployment, and monitoring tools.
    E.g. It is used by Docker/Kubernetes to check if the API process is running.
    """

    return {
        "status": "healthy"
    }

app.include_router(auth_router.router)
app.include_router(comment_router.router)
app.include_router(request_router.router)
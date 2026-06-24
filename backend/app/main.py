import os

from fastapi import FastAPI, Request

from fastapi.exceptions import RequestValidationError
from fastapi.responses import JSONResponse
from starlette.exceptions import HTTPException as StarletteHTTPException

from app.database import Base, engine
from app.models import comment, request, user
from app.routers import auth_router, comment_router, request_router

from fastapi.middleware.cors import CORSMiddleware
# Create database tables.
# Later, we can replace this with Alembic migrations.
if os.getenv("ENVIRONMENT") != "test":
    # Create database tables.
    # Later, we can replace this with Alembic migrations.
    Base.metadata.create_all(bind=engine)


app = FastAPI(
    title="RequestFlow API",
    description="A mini IT service request tracker backend built with FastAPI.",
    version="0.2.0"
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "http://localhost:5173",
        "http://localhost:5174"

    ],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
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


@app.get("/health")
def health_check():
    """
    Health check endpoint.

    Useful for Docker, deployment, and monitoring tools.
    """

    return {
        "status": "healthy"
    }

app.include_router(auth_router.router)
app.include_router(comment_router.router)
app.include_router(request_router.router)
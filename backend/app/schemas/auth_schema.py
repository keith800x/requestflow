from datetime import datetime

from pydantic import BaseModel, ConfigDict, EmailStr, Field

from app.enums import UserRole


class UserRegister(BaseModel):
    """
    Data required when a new user registers.
    """

    name: str = Field(
        ...,
        min_length=2,
        max_length=100
    )

    email: EmailStr

    password: str = Field(
        ...,
        min_length=8,
        max_length=100
    )


class UserLogin(BaseModel):
    """
    Data required when a user logs in.
    """

    email: EmailStr
    password: str


class UserResponse(BaseModel):
    """
    Data returned to the frontend.

    Notice:
    password_hash is intentionally not included.
    """

    id: int
    name: str
    email: EmailStr
    role: UserRole
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)


class TokenResponse(BaseModel):
    """
    Data returned after successful login.
    """

    access_token: str
    token_type: str = "bearer"
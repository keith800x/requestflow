from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.auth_dependencies import get_current_user
from app.database import get_db
from app.enums import UserRole
from app.models.user import User
from app.schemas.auth_schema import (
    TokenResponse,
    UserLogin,
    UserRegister,
    UserResponse,
)
from app.services.security_service import (
    create_access_token,
    hash_password,
    verify_password,
)


router = APIRouter(
    prefix="/auth",
    tags=["Authentication"]
)


def get_user_by_email(
    email: str,
    db: Session
) -> User | None:
    """
    Finds a user by email address.
    """

    return (
        db.query(User)
        .filter(User.email == email.lower())
        .first()
    )


@router.post(
    "/register",
    response_model=UserResponse,
    status_code=status.HTTP_201_CREATED
)
def register_user(
    user_data: UserRegister,
    db: Session = Depends(get_db)
):
    """
    Registers a new normal user.

    By default, every registered account gets the USER role.
    """

    existing_user = get_user_by_email(
        user_data.email,
        db
    )

    if existing_user is not None:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Email is already registered."
        )

    new_user = User(
        name=user_data.name.strip(),
        email=user_data.email.lower(),
        password_hash=hash_password(user_data.password),
        role=UserRole.USER.value
    )

    db.add(new_user)
    db.commit()
    db.refresh(new_user)

    return new_user


@router.post(
    "/login",
    response_model=TokenResponse
)
def login_user(
    login_data: UserLogin,
    db: Session = Depends(get_db)
):
    """
    Logs in a user.

    If email and password are correct, the API returns a JWT token.
    """

    user = get_user_by_email(
        login_data.email,
        db
    )

    if user is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid email or password."
        )

    password_is_valid = verify_password(
        login_data.password,
        user.password_hash
    )

    if not password_is_valid:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid email or password."
        )

    access_token = create_access_token(
        data={
            "sub": str(user.id),
            "email": user.email,
            "role": user.role
        }
    )

    return {
        "access_token": access_token,
        "token_type": "bearer"
    }


@router.get(
    "/me",
    response_model=UserResponse
)
def get_my_profile(
    current_user: User = Depends(get_current_user)
):
    """
    Returns the currently logged-in user's profile.
    """

    return current_user
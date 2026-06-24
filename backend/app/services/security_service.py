import os
from datetime import datetime, timedelta, timezone
from typing import Any

import jwt
from pwdlib import PasswordHash


# In a real deployed app, this should come from an environment variable.
# For local learning, this fallback is okay.
SECRET_KEY = os.getenv(
    "JWT_SECRET_KEY",
    "dev-secret-key-change-this-later"
)

ALGORITHM = "HS256"

ACCESS_TOKEN_EXPIRE_MINUTES = 60


password_hasher = PasswordHash.recommended()


def hash_password(password: str) -> str:
    """
    Converts a plain password into a secure password hash.

    Example:
    "password123" becomes a long unreadable hash.
    """

    return password_hasher.hash(password)


def verify_password(
    plain_password: str,
    password_hash: str
) -> bool:
    """
    Checks whether a plain password matches the stored password hash.
    """

    return password_hasher.verify(
        plain_password,
        password_hash
    )


def create_access_token(data: dict[str, Any]) -> str:
    """
    Creates a JWT access token.

    The token stores small pieces of user identity data.
    For example:
    - user id
    - email
    - role
    - expiry time
    """

    to_encode = data.copy()

    expire_time = datetime.now(timezone.utc) + timedelta(
        minutes=ACCESS_TOKEN_EXPIRE_MINUTES
    )

    to_encode.update({
        "exp": expire_time
    })

    encoded_jwt = jwt.encode(
        to_encode,
        SECRET_KEY,
        algorithm=ALGORITHM
    )

    return encoded_jwt


def decode_access_token(token: str) -> dict[str, Any]:
    """
    Decodes and verifies a JWT access token.

    If the token is invalid or expired, PyJWT will raise an error.
    """

    payload = jwt.decode(
        token,
        SECRET_KEY,
        algorithms=[ALGORITHM]
    )

    return payload
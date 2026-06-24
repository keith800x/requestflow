from datetime import datetime

from pydantic import BaseModel, ConfigDict, Field, field_validator


class CommentCreate(BaseModel):
    """
    Data required when creating a comment.
    """

    message: str = Field(
        ...,
        min_length=1,
        max_length=2000
    )

    is_internal_note: bool = False

    @field_validator("message")
    @classmethod
    def trim_and_validate_message(cls, value: str) -> str:
        """
        Removes extra spaces and rejects empty messages.
        """

        trimmed_value = value.strip()

        if not trimmed_value:
            raise ValueError("Comment message cannot be empty.")

        return trimmed_value


class CommentResponse(BaseModel):
    """
    Data returned from the API.
    """

    id: int
    request_id: int
    user_id: int
    message: str
    is_internal_note: bool
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)
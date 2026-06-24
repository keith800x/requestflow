from datetime import datetime
from typing import Optional

from pydantic import BaseModel, ConfigDict, Field, field_validator
from app.enums import RequestCategory, RequestPriority, RequestStatus

class ServiceRequestCreate(BaseModel):
    """
    Data required when a user creates a new service request.
    """

    
    title: str = Field(
        ...,
        min_length=3,
        max_length=150,
        description="Short title of the problem."
    )

    description: str = Field(
        ...,
        min_length=10,
        max_length=3000,
        description="Detailed explanation of the issue."
    )
    
    category: RequestCategory = RequestCategory.OTHER
    
    priority: RequestPriority = RequestPriority.MEDIUM

    @field_validator("title", "description")
    @classmethod
    def trim_text(cls, value: str) -> str:
        """
        Removes extra spaces from user input.

        Example:
        '   Laptop issue   ' becomes 'Laptop issue'.
        """

        return value.strip()


class ServiceRequestUpdate(BaseModel):
    """
    Data allowed when updating a service request.

    All fields are optional because the user may only update one field.
    """

    title: Optional[str] = Field(
        default=None,
        min_length=3,
        max_length=150
    )

    description: Optional[str] = Field(
        default=None,
        min_length=10,
        max_length=3000
    )

    category: Optional[RequestCategory] = None

    priority: Optional[RequestPriority] = None

    status: Optional[RequestStatus] = None

    assigned_to_id: Optional[int] = Field(
        default=None,
        ge=1
    )


    @field_validator("title", "description")
    @classmethod
    def trim_optional_text(cls, value: Optional[str]) -> Optional[str]:
        """
        Removes extra spaces from optional text fields.
        """

        if value is None:
            return value

        return value.strip()


class ServiceRequestResponse(BaseModel):
    """
    Data returned from the API to the frontend.
    """

    id: int
    title: str
    description: str
    category: RequestCategory
    priority: RequestPriority
    status: RequestStatus
    created_by_id: int
    assigned_to_id: Optional[int]
    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(from_attributes=True)
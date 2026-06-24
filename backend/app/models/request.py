from datetime import datetime, timezone


from sqlalchemy import DateTime, ForeignKey, Integer, String, Text
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.database import Base
from app.enums import RequestCategory, RequestPriority, RequestStatus

class ServiceRequest(Base):
    """
    Database model for an IT service request.

    This maps to the "service_requests" table in PostgreSQL.
    """

    __tablename__ = "service_requests"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)

    title: Mapped[str] = mapped_column(String(150), nullable=False)

    description: Mapped[str] = mapped_column(Text, nullable=False)

    category: Mapped[str] = mapped_column(
        String(50),
        nullable=False,
        default=RequestCategory.OTHER.value
    )

    priority: Mapped[str] = mapped_column(
        String(20),
        nullable=False,
        default=RequestPriority.MEDIUM.value
    )

    status: Mapped[str] = mapped_column(
        String(30),
        nullable=False,
        default=RequestStatus.OPEN.value
    )

    created_by_id: Mapped[int] = mapped_column(
        ForeignKey("users.id"),
        nullable=False,
        index=True
    )

    assigned_to_id: Mapped[int | None] = mapped_column(
        ForeignKey("users.id"),
        nullable=True,
        index=True
    )

    created_at: Mapped[datetime] = mapped_column(
        DateTime,
        default=lambda: datetime.now(timezone.utc),
        nullable=False
    )

    updated_at: Mapped[datetime] = mapped_column(
        DateTime,
        default=lambda: datetime.now(timezone.utc),
        onupdate=lambda: datetime.now(timezone.utc),
        nullable=False
    )

    created_by = relationship(
        "User",
        foreign_keys="ServiceRequest.created_by_id"
    )

    assigned_to = relationship(
        "User",
        foreign_keys="ServiceRequest.assigned_to_id"
    )
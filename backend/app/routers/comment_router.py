from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.auth_dependencies import get_current_user
from app.database import get_db
from app.enums import UserRole
from app.models.comment import Comment
from app.models.user import User
from app.routers.request_router import (
    ensure_user_can_view_request,
    get_service_request_or_404,
)
from app.schemas.comment_schema import CommentCreate, CommentResponse


router = APIRouter(
    prefix="/requests",
    tags=["Comments"]
)


@router.post(
    "/{request_id}/comments",
    response_model=CommentResponse,
    status_code=status.HTTP_201_CREATED
)
def create_comment(
    request_id: int,
    comment_data: CommentCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Creates a comment on a service request.

    Rules:
    - Request owner can comment on their own request.
    - Admin can comment on any request.
    - Only admin can create internal notes.
    """

    service_request = get_service_request_or_404(
        request_id,
        db
    )

    ensure_user_can_view_request(
        service_request,
        current_user
    )

    user_is_admin = current_user.role == UserRole.ADMIN.value

    if comment_data.is_internal_note and not user_is_admin:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only admins can create internal notes."
        )

    new_comment = Comment(
        request_id=request_id,
        user_id=current_user.id,
        message=comment_data.message,
        is_internal_note=comment_data.is_internal_note
    )

    db.add(new_comment)
    db.commit()
    db.refresh(new_comment)

    return new_comment


@router.get(
    "/{request_id}/comments",
    response_model=list[CommentResponse]
)
def get_comments_for_request(
    request_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Gets comments for a service request.

    Rules:
    - Request owner can view normal comments on their own request.
    - Admin can view all comments, including internal notes.
    - Normal users cannot see internal notes.
    """

    service_request = get_service_request_or_404(
        request_id,
        db
    )

    ensure_user_can_view_request(
        service_request,
        current_user
    )

    user_is_admin = current_user.role == UserRole.ADMIN.value

    query = (
        db.query(Comment)
        .filter(Comment.request_id == request_id)
    )

    if not user_is_admin:
        query = query.filter(Comment.is_internal_note == False)

    return (
        query
        .order_by(Comment.created_at.asc())
        .all()
    )
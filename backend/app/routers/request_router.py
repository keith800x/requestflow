from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from app.models.comment import Comment
from app.auth_dependencies import get_current_user, require_admin
from app.database import get_db
from app.enums import RequestStatus, UserRole

from app.models.request import ServiceRequest
from app.models.user import User
from app.schemas.request_schema import (
    ServiceRequestCreate,
    ServiceRequestResponse,
    ServiceRequestUpdate,
)


router = APIRouter(
    prefix="/requests",
    tags=["Service Requests"]
)

def get_service_request_or_404(
    request_id: int,
    db: Session
) -> ServiceRequest:
    """
    Finds a service request by ID.

    If the request does not exist, this function raises a 404 error.
    This avoids repeating the same query logic in every route.
    """

    service_request = (
        db.query(ServiceRequest)
        .filter(ServiceRequest.id == request_id)
        .first()
    )

    if service_request is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Service request not found."
        )

    return service_request

def ensure_user_can_view_request(
    service_request: ServiceRequest,
    current_user: User
) -> None:
    """
    Allows access if:
    1. The current user is an ADMIN, or
    2. The current user created the request.
    """

    user_is_admin = current_user.role == UserRole.ADMIN.value
    user_owns_request = service_request.created_by_id == current_user.id

    if not user_is_admin and not user_owns_request:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="You do not have permission to view this request."
        )


@router.post(
    "/",
    response_model=ServiceRequestResponse,
    status_code=status.HTTP_201_CREATED
)
def create_request(
    request_data: ServiceRequestCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Creates a new service request.

    Only logged-in users can create requests.
    The request is automatically linked to the current user.
    """

    new_request = ServiceRequest(
        title=request_data.title,
        description=request_data.description,
        category=request_data.category.value,
        priority=request_data.priority.value,
        status=RequestStatus.OPEN.value,
        created_by_id=current_user.id
    )

    db.add(new_request)
    db.commit()
    db.refresh(new_request)

    return new_request



@router.get(
    "/my",
    response_model=list[ServiceRequestResponse]
)
def get_my_requests(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Returns only the requests created by the logged-in user.
    """

    return (
        db.query(ServiceRequest)
        .filter(ServiceRequest.created_by_id == current_user.id)
        .order_by(ServiceRequest.created_at.desc())
        .all()
    )

@router.get(
    "/",
    response_model=list[ServiceRequestResponse]
)
def get_all_requests(
    admin_user: User = Depends(require_admin),
    db: Session = Depends(get_db)
):
    """
    Returns all service requests.

    Admin-only endpoint.
    """

    return (
        db.query(ServiceRequest)
        .order_by(ServiceRequest.created_at.desc())
        .all()
    )



@router.get(
    "/{request_id}",
    response_model=ServiceRequestResponse
)
def get_request_by_id(
    request_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Returns one service request by ID.

    Normal users can only view their own requests.
    Admins can view any request.
    """

    service_request = get_service_request_or_404(request_id, db)

    ensure_user_can_view_request(
        service_request,
        current_user
    )

    return service_request


@router.patch(
    "/{request_id}", 
    response_model=ServiceRequestResponse

)
def update_request(
    request_id: int,
    request_data: ServiceRequestUpdate,
    admin_user: User = Depends(require_admin),
    db: Session = Depends(get_db)
):
    """
    Updates an existing service request.

    Admin-only endpoint.
    """

    service_request = get_service_request_or_404(request_id, db)

    update_data = request_data.model_dump(
        exclude_unset=True,
        mode="json"
    )

    if not update_data:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="No update fields were provided."
        )

    if "assigned_to_id" in update_data and update_data["assigned_to_id"] is not None:
        assigned_user = (
            db.query(User)
            .filter(User.id == update_data["assigned_to_id"])
            .first()
        )

        if assigned_user is None:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Assigned user does not exist."
            )

    for field, value in update_data.items():
        setattr(service_request, field, value)

    db.commit()
    db.refresh(service_request)

    return service_request



@router.delete("/{request_id}")
def delete_request(
    request_id: int,
    admin_user: User = Depends(require_admin),
    db: Session = Depends(get_db)
):
    """
    Deletes a service request.

    Admin-only endpoint.
    """

    service_request = get_service_request_or_404(request_id, db)

    db.query(Comment).filter(Comment.request_id == request_id).delete(
        synchronize_session=False
    )

    db.delete(service_request)
    db.commit()

    return {"message": "Service request deleted successfully."}
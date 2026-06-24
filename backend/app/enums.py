from enum import StrEnum


class RequestCategory(StrEnum):
    """
    Allowed categories for service requests.
    """

    HARDWARE = "Hardware"
    SOFTWARE = "Software"
    ACCOUNT = "Account"
    NETWORK = "Network"
    OTHER = "Other"


class RequestPriority(StrEnum):
    """
    Allowed priority levels for service requests.
    """

    LOW = "Low"
    MEDIUM = "Medium"
    HIGH = "High"


class RequestStatus(StrEnum):
    """
    Allowed status values for service requests.
    """

    OPEN = "Open"
    IN_PROGRESS = "In Progress"
    RESOLVED = "Resolved"
    CLOSED = "Closed"

class UserRole(StrEnum):
    """
    Allowed user roles.

    USER:
    Normal user who can submit service requests.

    ADMIN:
    Support/admin user who can manage service requests.
    """

    USER = "USER"
    ADMIN = "ADMIN"
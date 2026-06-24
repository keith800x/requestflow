from app.enums import UserRole


def test_health_check(client):
    response = client.get("/health")

    assert response.status_code == 200
    assert response.json() == {
        "status": "healthy"
    }


def test_create_service_request(client, create_test_user):
    user, headers = create_test_user()

    response = client.post(
        "/requests/",
        json={
            "title": "Laptop Wi-Fi keeps disconnecting",
            "description": "My laptop disconnects from Wi-Fi during meetings.",
            "category": "Network",
            "priority": "Medium"
        },
        headers=headers
    )

    data = response.json()

    assert response.status_code == 201
    assert data["id"] == 1
    assert data["title"] == "Laptop Wi-Fi keeps disconnecting"
    assert data["category"] == "Network"
    assert data["priority"] == "Medium"
    assert data["status"] == "Open"
    assert data["created_by_id"] == user.id


def test_create_service_request_with_invalid_priority(client, create_test_user):
    user, headers = create_test_user()

    response = client.post(
        "/requests/",
        json={
            "title": "Laptop issue",
            "description": "My laptop is not working properly.",
            "category": "Hardware",
            "priority": "Urgent"
        },
        headers=headers
    )

    assert response.status_code == 422
    assert response.json()["error"] == "Validation error."


def test_get_my_requests(client, create_test_user):
    user, headers = create_test_user()

    client.post(
        "/requests/",
        json={
            "title": "Cannot login",
            "description": "I cannot login to my work account.",
            "category": "Account",
            "priority": "High"
        },
        headers=headers
    )

    client.post(
        "/requests/",
        json={
            "title": "Mouse not working",
            "description": "My wireless mouse is not responding.",
            "category": "Hardware",
            "priority": "Low"
        },
        headers=headers
    )

    response = client.get(
        "/requests/my",
        headers=headers
    )

    data = response.json()

    assert response.status_code == 200
    assert len(data) == 2
    assert data[0]["created_by_id"] == user.id


def test_get_all_requests_admin_only(client, create_test_user):
    user, user_headers = create_test_user(
        email="user@example.com",
        role=UserRole.USER
    )

    admin, admin_headers = create_test_user(
        email="admin@example.com",
        role=UserRole.ADMIN
    )

    client.post(
        "/requests/",
        json={
            "title": "Cannot login",
            "description": "I cannot login to my work account.",
            "category": "Account",
            "priority": "High"
        },
        headers=user_headers
    )

    response = client.get(
        "/requests/",
        headers=admin_headers
    )

    data = response.json()

    assert response.status_code == 200
    assert len(data) == 1
    assert data[0]["created_by_id"] == user.id


def test_normal_user_cannot_get_all_requests(client, create_test_user):
    user, headers = create_test_user(
        email="user@example.com",
        role=UserRole.USER
    )

    response = client.get(
        "/requests/",
        headers=headers
    )

    assert response.status_code == 403
    assert response.json() == {
        "error": "Admin access required."
    }


def test_get_request_by_id(client, create_test_user):
    user, headers = create_test_user()

    create_response = client.post(
        "/requests/",
        json={
            "title": "Software installation",
            "description": "I need help installing approved software.",
            "category": "Software",
            "priority": "Medium"
        },
        headers=headers
    )

    request_id = create_response.json()["id"]

    response = client.get(
        f"/requests/{request_id}",
        headers=headers
    )

    assert response.status_code == 200
    assert response.json()["id"] == request_id
    assert response.json()["category"] == "Software"
    assert response.json()["created_by_id"] == user.id


def test_update_request_status_as_admin(client, create_test_user):
    user, user_headers = create_test_user(
        email="user@example.com",
        role=UserRole.USER
    )

    admin, admin_headers = create_test_user(
        email="admin@example.com",
        role=UserRole.ADMIN
    )

    create_response = client.post(
        "/requests/",
        json={
            "title": "Network unstable",
            "description": "The office network keeps disconnecting.",
            "category": "Network",
            "priority": "High"
        },
        headers=user_headers
    )

    request_id = create_response.json()["id"]

    update_response = client.patch(
        f"/requests/{request_id}",
        json={
            "status": "In Progress",
            "assigned_to_id": admin.id
        },
        headers=admin_headers
    )

    data = update_response.json()

    assert update_response.status_code == 200
    assert data["status"] == "In Progress"
    assert data["assigned_to_id"] == admin.id


def test_normal_user_cannot_update_request_status(client, create_test_user):
    user, user_headers = create_test_user(
        email="user@example.com",
        role=UserRole.USER
    )

    create_response = client.post(
        "/requests/",
        json={
            "title": "Network unstable",
            "description": "The office network keeps disconnecting.",
            "category": "Network",
            "priority": "High"
        },
        headers=user_headers
    )

    request_id = create_response.json()["id"]

    update_response = client.patch(
        f"/requests/{request_id}",
        json={
            "status": "In Progress"
        },
        headers=user_headers
    )

    assert update_response.status_code == 403
    assert update_response.json() == {
        "error": "Admin access required."
    }


def test_update_request_with_no_fields(client, create_test_user):
    user, user_headers = create_test_user(
        email="user@example.com",
        role=UserRole.USER
    )

    admin, admin_headers = create_test_user(
        email="admin@example.com",
        role=UserRole.ADMIN
    )

    create_response = client.post(
        "/requests/",
        json={
            "title": "Account locked",
            "description": "My account is locked after too many login attempts.",
            "category": "Account",
            "priority": "Medium"
        },
        headers=user_headers
    )

    request_id = create_response.json()["id"]

    update_response = client.patch(
        f"/requests/{request_id}",
        json={},
        headers=admin_headers
    )

    assert update_response.status_code == 400
    assert update_response.json() == {
        "error": "No update fields were provided."
    }


def test_get_missing_request_returns_404(client, create_test_user):
    user, headers = create_test_user()

    response = client.get(
        "/requests/999",
        headers=headers
    )

    assert response.status_code == 404
    assert response.json() == {
        "error": "Service request not found."
    }


def test_delete_request_as_admin(client, create_test_user):
    user, user_headers = create_test_user(
        email="user@example.com",
        role=UserRole.USER
    )

    admin, admin_headers = create_test_user(
        email="admin@example.com",
        role=UserRole.ADMIN
    )

    create_response = client.post(
        "/requests/",
        json={
            "title": "Printer issue",
            "description": "The office printer is not printing documents.",
            "category": "Hardware",
            "priority": "Low"
        },
        headers=user_headers
    )

    request_id = create_response.json()["id"]

    delete_response = client.delete(
        f"/requests/{request_id}",
        headers=admin_headers
    )

    assert delete_response.status_code == 200
    assert delete_response.json() == {
        "message": "Service request deleted successfully."
    }

    get_response = client.get(
        f"/requests/{request_id}",
        headers=admin_headers
    )

    assert get_response.status_code == 404
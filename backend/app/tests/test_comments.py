from app.enums import UserRole


def test_user_can_create_comment_on_own_request(
    client,
    create_test_user,
    create_test_request
):
    user, headers = create_test_user(
        email="user@example.com",
        role=UserRole.USER
    )

    request_id = create_test_request(headers)

    response = client.post(
        f"/requests/{request_id}/comments",
        json={
            "message": "This issue is still happening.",
            "is_internal_note": False
        },
        headers=headers
    )

    data = response.json()

    assert response.status_code == 201
    assert data["request_id"] == request_id
    assert data["user_id"] == user.id
    assert data["message"] == "This issue is still happening."
    assert data["is_internal_note"] is False


def test_user_can_get_comments_on_own_request(
    client,
    create_test_user,
    create_test_request
):
    user, headers = create_test_user(
        email="user@example.com",
        role=UserRole.USER
    )

    request_id = create_test_request(headers)

    client.post(
        f"/requests/{request_id}/comments",
        json={
            "message": "First comment.",
            "is_internal_note": False
        },
        headers=headers
    )

    response = client.get(
        f"/requests/{request_id}/comments",
        headers=headers
    )

    data = response.json()

    assert response.status_code == 200
    assert len(data) == 1
    assert data[0]["message"] == "First comment."


def test_admin_can_comment_on_any_request(
    client,
    create_test_user,
    create_test_request
):
    user, user_headers = create_test_user(
        email="user@example.com",
        role=UserRole.USER
    )

    admin, admin_headers = create_test_user(
        email="admin@example.com",
        role=UserRole.ADMIN
    )

    request_id = create_test_request(user_headers)

    response = client.post(
        f"/requests/{request_id}/comments",
        json={
            "message": "Admin is checking this issue.",
            "is_internal_note": False
        },
        headers=admin_headers
    )

    data = response.json()

    assert response.status_code == 201
    assert data["request_id"] == request_id
    assert data["user_id"] == admin.id
    assert data["message"] == "Admin is checking this issue."


def test_user_cannot_comment_on_someone_else_request(
    client,
    create_test_user,
    create_test_request
):
    owner, owner_headers = create_test_user(
        email="owner@example.com",
        role=UserRole.USER
    )

    other_user, other_headers = create_test_user(
        email="other@example.com",
        role=UserRole.USER
    )

    request_id = create_test_request(owner_headers)

    response = client.post(
        f"/requests/{request_id}/comments",
        json={
            "message": "I should not be allowed to comment.",
            "is_internal_note": False
        },
        headers=other_headers
    )

    assert response.status_code == 403
    assert response.json() == {
        "error": "You do not have permission to view this request."
    }


def test_normal_user_cannot_create_internal_note(
    client,
    create_test_user,
    create_test_request
):
    user, headers = create_test_user(
        email="user@example.com",
        role=UserRole.USER
    )

    request_id = create_test_request(headers)

    response = client.post(
        f"/requests/{request_id}/comments",
        json={
            "message": "This should be internal.",
            "is_internal_note": True
        },
        headers=headers
    )

    assert response.status_code == 403
    assert response.json() == {
        "error": "Only admins can create internal notes."
    }


def test_admin_can_create_internal_note(
    client,
    create_test_user,
    create_test_request
):
    user, user_headers = create_test_user(
        email="user@example.com",
        role=UserRole.USER
    )

    admin, admin_headers = create_test_user(
        email="admin@example.com",
        role=UserRole.ADMIN
    )

    request_id = create_test_request(user_headers)

    response = client.post(
        f"/requests/{request_id}/comments",
        json={
            "message": "Likely a router issue.",
            "is_internal_note": True
        },
        headers=admin_headers
    )

    data = response.json()

    assert response.status_code == 201
    assert data["is_internal_note"] is True
    assert data["user_id"] == admin.id


def test_internal_notes_hidden_from_normal_user(
    client,
    create_test_user,
    create_test_request
):
    user, user_headers = create_test_user(
        email="user@example.com",
        role=UserRole.USER
    )

    admin, admin_headers = create_test_user(
        email="admin@example.com",
        role=UserRole.ADMIN
    )

    request_id = create_test_request(user_headers)

    client.post(
        f"/requests/{request_id}/comments",
        json={
            "message": "Visible user comment.",
            "is_internal_note": False
        },
        headers=user_headers
    )

    client.post(
        f"/requests/{request_id}/comments",
        json={
            "message": "Hidden admin note.",
            "is_internal_note": True
        },
        headers=admin_headers
    )

    user_response = client.get(
        f"/requests/{request_id}/comments",
        headers=user_headers
    )

    user_comments = user_response.json()

    assert user_response.status_code == 200
    assert len(user_comments) == 1
    assert user_comments[0]["message"] == "Visible user comment."

    admin_response = client.get(
        f"/requests/{request_id}/comments",
        headers=admin_headers
    )

    admin_comments = admin_response.json()

    assert admin_response.status_code == 200
    assert len(admin_comments) == 2
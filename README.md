# RequestFlow — IT Service Request Tracker

![Frontend](https://img.shields.io/badge/Frontend-React%20%2B%20TypeScript%20%2B%20Vite-blue)
![Backend](https://img.shields.io/badge/Backend-FastAPI-green)
![Database](https://img.shields.io/badge/Database-PostgreSQL-blue)
![Testing](https://img.shields.io/badge/Testing-Pytest%20%2B%20Vitest-yellow)
![Container](https://img.shields.io/badge/Container-Docker-blue)
![CI](https://github.com/keith800x/requestflow/actions/workflows/ci.yml/badge.svg?branch=master)
![Status](https://img.shields.io/badge/Status-In%20Progress-yellow)

A full-stack IT service request tracker that allows users to submit and track IT support requests, while admins can manage all requests, update statuses, delete requests, and add internal notes.

![Screenshot](assets/AppUIScreenshot.png)

## Live Demo

Frontend: https://requestflow-silk.vercel.app/
Backend API Docs: https://requestflow-backend.onrender.com/docs

---

## Problem

IT support requests can become difficult to manage when they are handled through scattered messages, emails, or informal communication channels.

Users may not know the status of their reported issue, while admins or support staff may struggle to track open requests, priorities, comments, and internal notes in one place.

This project helps simulate a basic internal IT help desk workflow where:

- Users can submit and view their own service requests.
- Admins can view and manage all requests.
- Comments can be added to keep request history clear.
- Internal notes can be used by admins for support-only information.

---

## Approach

RequestFlow is built as a full-stack web application with a separated frontend, backend, and database architecture.

The frontend is a React and TypeScript application that provides the user interface, protected routes, role-based navigation, request forms, request tables, loading/error states, and comment views.

The backend is a FastAPI application that handles authentication, authorization, request management, comment management, role-based access control, and database access.

The application uses JWT-based authentication. After logging in, the frontend stores the access token and includes it in future API requests. The backend validates the token and checks the user's role before returning protected data.

The authentication and authorization flow is:

The application flow is:

```text
User logs in
→ backend verifies credentials
→ backend returns JWT access token
→ frontend stores token
→ frontend sends token with API requests
→ backend validates token
→ backend checks user role
→ user/admin receives allowed request data
```

The main system flow is:

```text
React frontend
→ Axios API client
→ FastAPI backend
→ SQLAlchemy models
→ PostgreSQL database
```

To improve reliability and maintainability, the project includes:

- **JWT authentication** for login sessions.
- **Role-based access control** for USER and ADMIN permissions.
- **Protected frontend routes** to prevent unauthenticated page access.
- **Admin-only routes** for all-request management.
- **Comment support** for request discussion.
- **Internal admin notes** that are hidden from normal users.
- **Docker Compose** for running the backend and PostgreSQL locally.
- **GitHub Actions CI** for backend tests, frontend component tests, frontend build checks, and Docker build validation.

---

## Tech Stack

| Layer | Technology |
|---|---|
| Frontend | React, TypeScript, Vite |
| Frontend Routing | React Router |
| API Client | Axios |
| Backend | FastAPI |
| Database ORM | SQLAlchemy |
| Data Validation | Pydantic |
| Database | PostgreSQL |
| Authentication | JWT |
| Password Hashing | pwdlib / Argon2 |
| Testing | Pytest, Vitest, React Testing Library |
| Containerization | Docker, Docker Compose |
| CI/CD | GitHub Actions, Vercel, Render |
| Version Control | Git and GitHub |

---

## Results

The app currently supports a complete basic IT service request workflow.

Successful behaviours tested:

- Registered and logged in users.
- Stored authenticated JWT tokens in the frontend.
- Created service requests as a normal user.
- Viewed only the logged-in user's own requests.
- Promoted a user to ADMIN through PostgreSQL for development testing.
- Viewed all service requests as an admin.
- Updated request status as an admin.
- Deleted requests as an admin.
- Added comments to requests.
- Added admin internal notes.
- Hid internal notes from normal users.
- Protected frontend routes from unauthenticated users.
- Hid admin navigation links from normal users.
- Ran backend tests with Pytest.
- Ran frontend component tests using Vitest and React Testing Library to verify core pages and role-based navigation behaviour.
- Built the frontend successfully with Vite.
- Verified backend Docker image build through GitHub Actions.

Example service request:

```text
Title: Unable to access company email

Description: I am unable to log in to my company email account. I tried resetting my password, but I still receive an invalid credentials error.

Category: Account

Priority: High
```

---

## Setup & Usage

#### Prerequisites

- Git
- Docker Desktop
- Node.js and npm
- Python 3.12 or later, if running backend tests locally without Docker

---

### Installation

Clone the repository:

```bash
git clone https://github.com/keith800x/requestflow.git
cd requestflow
```

---

### Local Environment Variables

The project uses environment variables for backend and frontend configuration.

Example environment files are provided at:

```text
backend/.env.example
frontend/.env.example
.env.remote.example
```

Backend example:

```env
DATABASE_URL=postgresql+psycopg://requestflow_user:requestflow_password@localhost:5432/requestflow_db
JWT_SECRET_KEY=dev-secret-key-change-this-later
ENVIRONMENT=development
ALLOWED_ORIGINS=http://localhost:5173,http://localhost:5174
```

Frontend example:

```env
VITE_API_BASE_URL=http://localhost:8000
```

Remote frontend testing example:

```env
DEPLOYED_BACKEND_URL=https://your-render-backend-url.onrender.com
```

For the Docker Compose local setup, the required backend and frontend environment variables are already provided inside `docker-compose.yml`.

For deployed environments, production values are configured in the Render and Vercel dashboards instead of local `.env` files.

Do not commit real `.env` files to GitHub.
---

### Run the Full Local Stack

From the project root:

```bash
docker compose up --build
```

This starts:

```text
Frontend:  http://localhost:5173
Backend:   http://localhost:8000
Database:  PostgreSQL container on localhost:5432
```

FastAPI Swagger documentation:

```text
http://localhost:8000/docs
```

To stop the local stack:

```bash
docker compose down
```

To stop the local stack and remove the local PostgreSQL Docker volume:

```bash
docker compose down -v
```

Use `down -v` only when you want to reset the local database data.

---


The frontend will be available at:

```text
http://localhost:5173
```

---

### Optional: Run Local Frontend Against Deployed Backend

This mode is useful for testing the deployed Render backend with a local frontend.

Create a local `.env.remote` file from the example:

```bash
cp .env.remote.example .env.remote
```

Then update `.env.remote` with your deployed backend URL:

```env
DEPLOYED_BACKEND_URL=https://your-render-backend-url.onrender.com
```

Run:

```bash
docker compose --env-file .env.remote -f docker-compose.frontend-remote.yml up --build
```

The local frontend will be available at:

```text
http://localhost:5173
```

In this mode:

```text
Local Docker frontend
→ deployed Render backend
→ deployed Render PostgreSQL database
```

The real `.env.remote` file should not be committed to GitHub.

## Usage Examples

### Example 1 — Register and Login

Register a new user through the frontend or Swagger.

Example:

```text
Name: Keith
Email: keith@example.com
Password: password123
```

Then login with the same email and password.

Normal registered users are assigned the `USER` role by default.

---

### Example 2 — Create a Service Request

After logging in as a normal user, go to **Create Request** and submit:

```text
Title: Laptop Wi-Fi keeps disconnecting

Description: My laptop disconnects from Wi-Fi during online meetings and file uploads.

Category: Network

Priority: Medium
```

Expected result:

```text
The request is created and appears under My Requests.
```

---

### Example 3 — Promote a User to Admin for Development

Open PostgreSQL inside Docker:

```bash
docker exec -it requestflow-postgres psql -U requestflow_user -d requestflow_db
```

Run:

```sql
UPDATE users
SET role = 'ADMIN'
WHERE email = 'keith@example.com';

SELECT id, name, email, role
FROM users;
```

Exit PostgreSQL:

```sql
\q
```

Log out and log in again so the new JWT token contains the updated role.

Expected result:

```text
The All Requests page becomes visible in the navigation bar.
```

---

### Example 4 — Admin Updates a Request

As an admin:

```text
1. Go to All Requests.
2. Select a request.
3. Change its status from Open to In Progress.
4. Confirm the status update appears in both All Requests and My Requests.
```

---

### Example 5 — Admin Adds an Internal Note

As an admin:

```text
1. Open a request detail page.
2. Add a comment.
3. Tick Internal admin note.
4. Submit the comment.
```

Expected result:

```text
The internal note is visible to admins but hidden from normal users.
```

---

## Running Tests

The project includes backend and frontend tests.

### Backend Tests

Backend tests are written with Pytest and cover authentication, request management, role-based access control, and comments.

From the backend folder:

```bash
cd backend
python -m pytest
```

---

### Frontend Tests

Frontend tests are written with Vitest and React Testing Library. They cover core UI behaviour such as login rendering, registration rendering, request form rendering, and role-based navigation.

From the frontend folder:
```bash
cd frontend
npm test
```

---

### Frontend Build Check

From the frontend folder:

```bash
cd frontend
npm run build
```

---

### Docker Build Check

From the project root:

```bash
docker build ./backend
```

---

## GitHub Actions CI

This project uses GitHub Actions to automatically check the project on push and pull request.

The workflow currently checks:

- Backend tests with Pytest.
- Frontend tests with Vitest
- Frontend production build.
- Backend Docker image build.

This helps ensure that backend logic, frontend UI behaviour, and build configuration remain working before deployment.

Workflow file:

```text
.github/workflows/ci.yml
```

---

## Deployment

The application is deployed using:

| Component | Platform |
|---|---|
| Frontend | Vercel |
| Backend API | Render Web Service |
| Database | Render PostgreSQL |
| CI | GitHub Actions |

Deployment flow:

```text
Push to GitHub master branch
→ GitHub Actions runs backend tests, run frontend component tests, frontend build, and Docker build checks
→ Vercel redeploys the frontend
→ Render redeploys the backend
```

## API Overview

| Method | Endpoint | Description | Access |
|---|---|---|---|
| POST | `/auth/register` | Register a new user | Public |
| POST | `/auth/login` | Login and receive JWT token | Public |
| GET | `/auth/me` | Get current logged-in user profile | User/Admin |
| POST | `/requests/` | Create a service request | User/Admin |
| GET | `/requests/my` | View own service requests | User/Admin |
| GET | `/requests/` | View all service requests | Admin |
| GET | `/requests/{id}` | View one request | Owner/Admin |
| PATCH | `/requests/{id}` | Update a request | Admin |
| DELETE | `/requests/{id}` | Delete a request | Admin |
| POST | `/requests/{id}/comments` | Add a comment to a request | Owner/Admin |
| GET | `/requests/{id}/comments` | View comments for a request | Owner/Admin |

---

## Project Structure

```text
requestflow/
├── backend/
│   ├── app/
│   │   ├── models/                    # SQLAlchemy database models
│   │   ├── routers/                   # FastAPI route handlers
│   │   ├── schemas/                   # Pydantic request/response schemas
│   │   ├── services/                  # Security and helper services
│   │   ├── tests/                     # Pytest backend tests
│   │   ├── auth_dependencies.py       # Authentication and admin dependencies
│   │   ├── database.py                # Database engine and session setup
│   │   ├── enums.py                   # Shared enum values
│   │   └── main.py                    # FastAPI application entry point
│   ├── Dockerfile                     # Backend Docker image
│   ├── requirements.txt               # Backend dependencies
│   └── .env.example                   # Example backend environment variables
│
├── frontend/
│   ├── public/                        # Static public assets
│   ├── src/
│   │   ├── api/                       # Axios API clients
│   │   ├── assets/                    # Frontend assets imported by React
│   │   ├── components/                # Shared layout and route guards
│   │   ├── pages/                     # React page components and page tests
│   │   ├── test/                      # Vitest and React Testing Library setup
│   │   ├── utils/                     # Reusable frontend helper functions such as date formatting, error messages, and request filtering
│   │   ├── App.tsx                    # Frontend route configuration
│   │   ├── App.css                    # App-level component styling
│   │   ├── main.tsx                   # React entry point
│   │   └── index.css                  # Global styling
│   ├── index.html                     # Vite HTML entry point
│   ├── package.json                   # Frontend scripts and dependencies
│   ├── package-lock.json              # Locked npm dependencies
│   ├── vite.config.ts                 # Vite and Vitest configuration
│   ├── eslint.config.js               # ESLint configuration
│   ├── tsconfig.json                  # Main TypeScript configuration
│   ├── tsconfig.app.json              # TypeScript config for frontend app code
│   ├── tsconfig.node.json             # TypeScript config for Node/Vite config files
│   └── .env.example                   # Example frontend environment variables
│
├── assets/
│   └── AppUIScreenshot.png            # Screenshot for README
│
├── .github/
│   └── workflows/
│       └── ci.yml                     # GitHub Actions CI workflow
│
├── docker-compose.yml                 # Local frontend, backend, and PostgreSQL setup
├── docker-compose.frontend-remote.yml # Local frontend connected to deployed backend
├── .env.remote.example                # Example env file for remote backend testing
├── .gitignore                         # Git ignore rules
├── README.md                          # Project documentation
└── LICENSE                            # Project license
```

---

## Limitations & Future Work

### Limitations

- The project is currently designed for local development and portfolio demonstration.
- The project is deployed for portfolio demonstration, but production hardening is still limited.
- The deployed backend may take longer to respond after inactivity because the Render free web service can spin down and wake on the next request.
- Admin account promotion is currently done manually through PostgreSQL.
- The backend currently uses SQLAlchemy table creation for development rather than a full migration tool such as Alembic.
- User management is limited; admins cannot yet promote or demote users through the frontend.
- The UI is functional but can be further polished with better styling, loading states, and validation messages.
- The application should not be used for real confidential IT tickets without stronger production security controls.

### Future Improvements

- Add admin user management for promoting and demoting users.
- Add search, filter, and sorting for requests.
- Add request assignment to specific admins or support staff.
- Add request analytics dashboard.
- Add database migrations with Alembic.
- Improve production deployment with database migrations, stronger monitoring, and automated release checks.
- Add email notifications for request updates.
- Add file attachment support for service requests.
- Add audit logs for admin actions.
- Improve UI styling with a component library or design system.

---

## Ethical Considerations

This app is designed as a learning and portfolio project for managing basic IT service request workflows.

Role-based access control is implemented to separate normal user actions from admin actions. However, production systems require stronger security practices, including proper secret management, secure deployment configuration, audit logging, rate limiting, input validation, and access reviews.

The project should not be used to store real confidential company issues, personal data, or sensitive IT information unless proper production security, privacy, and compliance measures are added.

Admins are able to view and manage all requests, so this role should only be given to trusted users.

---

## About the Author

**Keith Lua** - [LinkedIn](https://www.linkedin.com/in/keith-lua) | [Github](https://github.com/keith800x/)

---

## License

[MIT](LICENSE)

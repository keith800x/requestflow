# RequestFlow — IT Service Request Tracker

![Frontend](https://img.shields.io/badge/Frontend-React%20%2B%20TypeScript%20%2B%20Vite-blue)
![Backend](https://img.shields.io/badge/Backend-FastAPI-green)
![Database](https://img.shields.io/badge/Database-PostgreSQL-blue)
![Testing](https://img.shields.io/badge/Testing-Pytest%20%2B%20Vitest-yellow)
![Container](https://img.shields.io/badge/Container-Docker-blue)
![Orchestration](https://img.shields.io/badge/Orchestration-Kubernetes-326CE5)
![Monitoring](https://img.shields.io/badge/Monitoring-Prometheus%20%2B%20Grafana-orange)
![Registry](https://img.shields.io/badge/Registry-GHCR-black)
![Ingress](https://img.shields.io/badge/Ingress-Traefik-24A1C1)
![Deployment](https://img.shields.io/badge/Deployment-Vercel%20%2B%20Render%20%2B%20Neon-purple)
![Migrations](https://img.shields.io/badge/Migrations-Alembic-6BA81E)
![Security](https://img.shields.io/badge/Security-Trivy-1904DA)
![CI](https://github.com/keith800x/requestflow/actions/workflows/ci.yml/badge.svg?branch=master)
![Status](https://img.shields.io/badge/Status-MVP%20%2B%20DevOps%20Extension-brightgreen)

A full-stack IT service request tracker that allows users to submit and track IT support requests, while admins can manage all requests, update statuses, delete requests, and add internal notes. The project also includes a DevOps extension covering containerisation, CI, GHCR image publishing, Kubernetes orchestration, Ingress routing, persistent storage, Alembic database migrations, health probes, Prometheus monitoring and alert rules, Grafana dashboard provisioning, Trivy container scanning, and repeatable deployment scripts. The public deployment uses Vercel for the frontend, Render for the API, and Neon PostgreSQL for the production database.

![RequestFlow login page](assets/app/login-page.png)

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
- **GitHub Container Registry publishing** for versioned frontend and backend images.
- **Kubernetes manifests** for the frontend, backend, PostgreSQL, Prometheus, Grafana, configuration, secrets, storage, and routing.
- **Traefik Ingress** for routing the frontend and `/api` traffic through one local hostname.
- **PowerShell deployment and verification scripts** for repeatable local Kubernetes deployment.
- **Alembic migrations** for versioned PostgreSQL schema changes instead of runtime table creation.
- **Migration gates** in Docker Compose, Render startup, and Kubernetes init containers.
- **Trivy container scanning** that fails CI on fixable HIGH or CRITICAL vulnerabilities.
- **Prometheus alert rules** that detect when the backend cannot be scraped for more than one minute.
- **Neon PostgreSQL** as the managed production database used by the Render backend.

---

## DevOps Extension

The DevOps work was developed separately on the `devops-extension` branch so that infrastructure changes could be tested without disrupting the stable `master` branch.

The extension was completed incrementally:

```text
Create safe Git branch
→ add FastAPI health and readiness endpoints
→ add Docker Compose health checks
→ add production-style Nginx frontend image
→ add Prometheus metrics
→ provision Prometheus and Grafana with Docker Compose
→ create Kubernetes namespace, ConfigMap, Secret, Services, Deployments, StatefulSet, and PVCs
→ publish frontend and backend images to GHCR
→ deploy Prometheus and Grafana in Kubernetes
→ provision the Grafana datasource and dashboard automatically
→ add Alembic migration execution to Compose, Render, and Kubernetes startup
→ add Traefik Ingress routing
→ add Trivy container vulnerability scanning in GitHub Actions
→ add the RequestFlowBackendDown Prometheus alert rule
→ migrate the production database from Render PostgreSQL to Neon PostgreSQL
→ add repeatable deployment and verification scripts
```

### DevOps architecture

```mermaid
flowchart LR
    User[Browser]

    subgraph Cluster["Docker Desktop Kubernetes"]
        Traefik[Traefik Ingress]

        Frontend["React Frontend<br/>Nginx"]
        Backend["FastAPI Backend"]
        Database[("PostgreSQL<br/>StatefulSet + PVC")]

        Prometheus["Prometheus<br/>Deployment + PVC"]
        Grafana["Grafana<br/>Deployment + PVC"]

        ConfigMap["ConfigMap"]
        Secret["Kubernetes Secret"]
    end

    User -->|"requestflow.localhost/"| Traefik
    Traefik -->|"/"| Frontend
    Traefik -->|"/api/*"| Backend

    Backend -->|"SQL / TCP 5432"| Database
    Prometheus -->|"Scrape /metrics"| Backend
    Grafana -->|"PromQL queries"| Prometheus

    ConfigMap -.-> Backend
    Secret -.-> Backend
    Secret -.-> Database
    Secret -.-> Grafana
```

### CI and Container Publishing Flow

```mermaid
flowchart LR
    Developer["Developer Push"]
    GitHub["GitHub Repository"]
    CI["GitHub Actions"]

    Tests["Backend Tests<br/>Frontend Tests<br/>Build Checks"]
    BackendImage["Backend Container Image"]
    FrontendImage["Frontend Container Image"]
    Trivy["Trivy HIGH/CRITICAL Scan"]
    GHCR["GitHub Container Registry"]
    Kubernetes["Docker Desktop Kubernetes"]

    Developer --> GitHub
    GitHub --> CI
    CI --> Tests
    Tests --> BackendImage
    Tests --> FrontendImage
    BackendImage --> GHCR
    FrontendImage --> GHCR
    GHCR --> Kubernetes
```

### Request Routing

```mermaid
sequenceDiagram
    participant Browser
    participant Traefik
    participant Frontend as React/Nginx
    participant Backend as FastAPI
    participant Database as PostgreSQL

    Browser->>Traefik: GET /
    Traefik->>Frontend: Forward /
    Frontend-->>Browser: React application

    Browser->>Traefik: POST /api/auth/login
    Traefik->>Backend: POST /auth/login
    Backend->>Database: Query user
    Database-->>Backend: User record
    Backend-->>Browser: JWT access token
```

### Runtime endpoints

| Endpoint | Purpose |
|---|---|
| `/health` | Confirms that the FastAPI process is alive |
| `/ready` | Confirms that the backend can connect to PostgreSQL |
| `/metrics` | Exposes Prometheus-compatible application metrics |

### Kubernetes reliability features

- PostgreSQL runs as a **StatefulSet** with persistent storage.
- Frontend, backend, Prometheus, and Grafana run as **Deployments**.
- PostgreSQL, Prometheus, and Grafana use **PersistentVolumeClaims**.
- Kubernetes **startup, readiness, and liveness probes** monitor the workloads.
- Backend **init containers** wait for PostgreSQL and run `alembic upgrade head` before FastAPI starts.
- Application configuration is stored in a **ConfigMap**.
- Local passwords and connection strings are stored in an ignored **Secret manifest**.
- Grafana automatically provisions the Prometheus datasource and RequestFlow dashboard.
- Prometheus loads the `RequestFlowBackendDown` alert rule from a ConfigMap.
- Prometheus uses the Kubernetes `Recreate` deployment strategy so only one process writes to its persistent TSDB volume during upgrades.
- Traefik routes `requestflow.localhost/` to the frontend and `/api/` to the backend.
- Kubernetes workloads pull versioned images from **GitHub Container Registry**.
- The complete namespace was deleted and successfully recreated using the version-controlled manifests and deployment script.
- Deployment verification checks the frontend, backend health endpoint, and backend readiness endpoint through Traefik Ingress.

---

## Application Features

### User Request Management

![RequestFlow user request list](assets/app/user-requests.png)

### Admin Request Detail and Internal Notes

![Admin request detail](assets/app/admin-request-detail.png)

### Deployed Backend API

![RequestFlow FastAPI documentation](assets/app/api-documentation.png)

## DevOps Evidence

The following screenshots document the clean-state Kubernetes recreation test, automated verification, monitoring setup, and container publishing pipeline.

### Versioned Database Migrations

Database schema changes are managed with Alembic rather than creating tables automatically when the API starts.

The migration chain currently includes the initial schema and a follow-up migration that converts service-request timestamps to timezone-aware PostgreSQL columns. Migration execution is integrated into:

- Docker Compose through a one-off migration service
- Kubernetes through the backend `run-migrations` init container
- Render through `alembic upgrade head` before Uvicorn starts

This keeps local, Kubernetes, and public production environments aligned to the same schema revision.

### Kubernetes State Before Recreation

Before the clean-state test, the existing `requestflow` namespace contained healthy application and monitoring workloads, Services, persistent volume claims, and Traefik Ingress resources.

The resources had been running for several days before the namespace was deleted.

![Kubernetes state before recreation](assets/devops/kubernetes-before-recreation.png)

### Clean Kubernetes Deployment

The `requestflow` namespace was deleted and recreated using the version-controlled Kubernetes manifests and automated deployment script.

The recreated environment contains:

- Running frontend, backend, PostgreSQL, Prometheus, and Grafana Pods
- Kubernetes Services for all application and monitoring components
- Bound persistent volume claims for PostgreSQL, Prometheus, and Grafana
- Traefik Ingress routing for `requestflow.localhost`

The recently created resource ages shown below confirm that the environment was recreated from a clean namespace.

![Kubernetes clean deployment](assets/devops/kubernetes-clean-deployment.png)

### Automated Kubernetes Verification

The verification script inspects the Kubernetes resources and tests the application through Traefik Ingress.

It confirms that:

- The frontend returns HTTP `200`
- The backend health endpoint reports healthy
- The backend readiness endpoint confirms PostgreSQL connectivity
- The complete verification process passes

![Kubernetes verification](assets/devops/kubernetes-verification.png)

### Prometheus Target Health

Prometheus automatically discovers and scrapes the FastAPI `/metrics` endpoint through the Kubernetes backend Service.

Both the Prometheus server and the `requestflow-backend` target report an `UP` state.

![Prometheus targets](assets/devops/prometheus-targets.png)

### Prometheus Backend Availability Alert

Prometheus evaluates the `RequestFlowBackendDown` alert rule every 15 seconds.

The rule fires when:

```promql
up{job="requestflow-backend"} == 0
```

and the backend remains unavailable for more than one minute. The alert was tested by scaling the Kubernetes backend Deployment to zero and confirming that the rule changed to `FIRING` with `severity="critical"`.

![Prometheus backend availability alert](assets/devops/prometheus-backend-down-alert.png)

### Provisioned Grafana Datasource

The Prometheus datasource is provisioned automatically through version-controlled Grafana configuration.

The datasource uses the internal Kubernetes Service URL:

```text
http://requestflow-prometheus:9090
```
Because the datasource is provisioned through configuration, it cannot be manually modified through the Grafana interface.

![Provisioned Grafana datasource](assets/devops/grafana-datasource.png)

### Grafana Monitoring Dashboard

The RequestFlow Grafana dashboard is provisioned automatically and displays live backend metrics, including:

- Backend health
- API request rate
- API error rate
- 95th-percentile response time
- Requests grouped by endpoint
- Requests grouped by status code
- Backend CPU usage
- Backend memory usage

![Grafana monitoring dashboard](assets/devops/grafana-dashboard.png)

### GitHub Actions Container Publishing

GitHub Actions builds and publishes the frontend and backend container images when changes are pushed to the `devops-extension` branch.

The workflow performs:

- Frontend container build and publication
- Backend container build and publication
- Branch-tagged image publishing
- Commit-specific image tagging for traceability

[View the container publishing workflow runs](https://github.com/keith800x/requestflow/actions/workflows/docker-publish.yml)

![Successful GitHub Actions container publishing](assets/devops/github-actions-publish.png)

Published container versions:

- [Backend container versions](https://github.com/keith800x/requestflow/pkgs/container/requestflow-backend/versions)
- [Frontend container versions](https://github.com/keith800x/requestflow/pkgs/container/requestflow-frontend/versions)

### Trivy Container Security Scanning

The `security.yml` workflow builds the frontend and backend images and scans both images with Trivy.

The security gate checks operating-system and application-library vulnerabilities, ignores vulnerabilities that do not yet have a fix, and fails the workflow when a fixable `HIGH` or `CRITICAL` vulnerability is found.

![Successful Trivy container security scan](assets/devops/github-actions-trivy.png)

### Published GHCR Packages

The versioned frontend and backend images are published to GitHub Container Registry and can be pulled by the Kubernetes manifests.

![Published RequestFlow GHCR packages](assets/devops/ghcr-packages.png)

## Tech Stack

| Layer | Technology |
|---|---|
| Frontend | React, TypeScript, Vite |
| Frontend Routing | React Router |
| API Client | Axios |
| Frontend Web Server | Nginx |
| Backend | FastAPI |
| Database ORM | SQLAlchemy |
| Database Migrations | Alembic |
| Data Validation | Pydantic |
| Database | PostgreSQL; Neon PostgreSQL in production |
| Authentication | JWT |
| Password Hashing | pwdlib / Argon2 |
| Testing | Pytest, Vitest, React Testing Library |
| Containerization | Docker, Docker Compose |
| Container Registry | GitHub Container Registry |
| Orchestration | Kubernetes |
| Kubernetes Routing | Traefik Ingress |
| Monitoring | Prometheus, Grafana |
| Alerting | Prometheus alert rules |
| Container Security | Trivy |
| CI/CD | GitHub Actions, Vercel, Render, Neon |
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
- Added `/health`, `/ready`, and `/metrics` backend endpoints.
- Added Docker Compose health checks and service startup ordering.
- Built a production-style React image served by Nginx.
- Collected FastAPI metrics with Prometheus and visualised them in Grafana.
- Provisioned Grafana datasources and dashboards from version-controlled files.
- Deployed PostgreSQL as a Kubernetes StatefulSet with persistent storage.
- Deployed the frontend, backend, Prometheus, and Grafana as Kubernetes workloads.
- Published frontend and backend images to GitHub Container Registry.
- Routed frontend and API traffic through Traefik Ingress.
- Verified the complete Kubernetes route with automated deployment and health-check scripts.
- Recreated the complete application from a deleted Kubernetes namespace using the automated deployment script.
- Verified that all Pods, Services, PVCs, monitoring resources, and Ingress routes were recreated successfully.
- Verified the frontend, backend health endpoint, and backend readiness endpoint using an automated verification script.
- Confirmed automatic Prometheus target discovery and Grafana datasource/dashboard provisioning.
- Confirmed PostgreSQL data persistence after deleting and recreating its Pod.
- Replaced runtime SQLAlchemy table creation with versioned Alembic migrations.
- Verified the Alembic revision chain, upgraded PostgreSQL to the latest revision, and confirmed no pending schema operations.
- Ran migrations automatically before the backend starts in Docker Compose, Kubernetes, and Render.
- Migrated the public production database from expiring Render PostgreSQL to Neon PostgreSQL.
- Added Trivy container scans for both frontend and backend images with a HIGH/CRITICAL security gate.
- Added and tested the `RequestFlowBackendDown` Prometheus alert by simulating a Kubernetes backend outage.
- Updated the Prometheus Deployment strategy to `Recreate` to protect the single-writer TSDB persistent volume during upgrades.

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
- `kubectl`, for the Kubernetes extension
- Helm, for installing Traefik

---

### Installation

Clone the repository:

```cmd
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

For deployed environments, frontend values are configured in Vercel, while the Render backend receives its Neon `DATABASE_URL`, JWT secret, allowed origins, and production environment settings through Render environment variables.

Do not commit real `.env` files to GitHub.
---

### Local Environment Options

RequestFlow supports several alternative local environments. Run **one local environment at a time** to avoid port conflicts and confusion over which backend or database the browser is using.

| Environment | Purpose | Main URL |
|---|---|---|
| Full local development stack | Develop the frontend and backend locally with monitoring | `http://localhost:5173` |
| Local frontend with deployed backend | Test the local frontend against the Render backend and Neon database | `http://localhost:5173` |
| Production-like local stack | Test the built React application served through Nginx | `http://localhost:8080` |
| Kubernetes | Test orchestration, persistence, monitoring, and Ingress | `http://requestflow.localhost` |

The full development stack and the production-like stack both use backend port `8000` and PostgreSQL port `5432`. The full development stack and remote-backend frontend mode both use frontend port `5173`. Stop the current environment before starting another one.

---

### Run the Full Local Development Stack

Use this environment while actively developing the frontend and backend.

From the project root:

```cmd
docker compose up --build
```

This starts:

```text
Frontend:  http://localhost:5173
Backend:   http://localhost:8000
Database:  PostgreSQL container on localhost:5432
Prometheus:  http://localhost:9090
Grafana:     http://localhost:3001
```

FastAPI endpoints:

```text
Swagger documentation: http://localhost:8000/docs
Health:                http://localhost:8000/health
Readiness:             http://localhost:8000/ready
Metrics:               http://localhost:8000/metrics
```

Stop the development stack with:

```cmd
docker compose down
```

Stop the stack and remove its local Docker volumes with:

```cmd
docker compose down -v
```

Use `down -v` only when you intentionally want to reset local database and monitoring data.

---


The frontend will be available at:

```text
http://localhost:5173
```

---

### Run Local Frontend Against Deployed Backend

This mode runs only the frontend locally while connecting it to the deployed Render backend and Neon PostgreSQL database.
Stop the full local development stack before using this mode because both environments use frontend port `5173`.

Stop the development stack:

```cmd
docker compose down
```

Create a local `.env.remote` file from the example:

```cmd
copy .env.remote.example .env.remote
```

Then update `.env.remote` with your deployed backend URL:

```env
DEPLOYED_BACKEND_URL=https://your-render-backend-url.onrender.com
```

Run:

```cmd
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
→ Neon PostgreSQL database
```

Stop this environment with:

```cmd
docker compose -p requestflow-frontend-remote --env-file .env.remote -f docker-compose.frontend-remote.yml down
```

The real `.env.remote` file should not be committed to GitHub.

### Run the Production-Like Local Docker Stack

This environment builds the React application for production and serves it through Nginx.

Stop the full local development stack first because both environments use backend port `8000` and PostgreSQL port `5432`.

Stop the development stack:

```cmd
docker compose down
```

Start the production-like stack under a separate Docker Compose project name:

```cmd
docker compose -p requestflow-prod-local -f docker-compose.prod-local.yml up --build
```

This starts:

```text
Frontend through Nginx: http://localhost:8080
Backend:                http://localhost:8000
PostgreSQL:             localhost:5432
```

The production-style frontend image supports React Router refreshes through the Nginx fallback configuration.

Stop this environment with:

```cmd
docker compose -p requestflow-prod-local -f docker-compose.prod-local.yml down
```

Do not add `-v` unless you intentionally want to delete the production-local PostgreSQL volume.

---

### Kubernetes Deployment

The Kubernetes extension is designed for Docker Desktop Kubernetes and uses GHCR-hosted frontend and backend images.

#### Required local Secret

Copy the example Secret:

```cmd
copy k8s\secret.example.yml k8s\secret.local.yml
```

PowerShell alternative:

```powershell
Copy-Item k8s/secret.example.yml k8s/secret.local.yml
```

WSL or Git Bash alternative:

```bash
cp k8s/secret.example.yml k8s/secret.local.yml
```

Update the real values inside `k8s/secret.local.yml`.

This file is intentionally ignored by Git and must not be committed.

#### Install Traefik

```cmd
helm repo add traefik https://traefik.github.io/charts
helm repo update

helm upgrade --install traefik traefik/traefik ^
  --namespace traefik ^
  --create-namespace ^
  -f k8s/traefik-values.yml
```

#### Deploy RequestFlow

From PowerShell:

```powershell
.\scripts\deploy-k8s.ps1
```

From Command Prompt:

```cmd
powershell.exe -NoProfile -ExecutionPolicy Bypass -File ".\scripts\deploy-k8s.ps1"
```

The script applies the resources in dependency order and waits for PostgreSQL, the backend, frontend, Prometheus, and Grafana to become ready.

#### Verify RequestFlow

From PowerShell:

```powershell
.\scripts\verify-k8s.ps1
```

From Command Prompt:

```cmd
powershell.exe -NoProfile -ExecutionPolicy Bypass -File ".\scripts\verify-k8s.ps1"
```

The verification script checks:

```text
Kubernetes Pods, Services, PVCs, and Ingress
→ frontend through Traefik
→ backend /health through Traefik
→ backend /ready through Traefik
```

Successful output ends with:

```text
RequestFlow Kubernetes verification passed.
```

#### Local Kubernetes URLs

```text
Application: http://requestflow.localhost
API health:  http://requestflow.localhost/api/health
API ready:   http://requestflow.localhost/api/ready
```

Prometheus and Grafana remain internal Kubernetes Services. Use port forwarding when needed:

```cmd
kubectl port-forward service/requestflow-prometheus 9091:9090 -n requestflow
kubectl port-forward service/requestflow-grafana 3002:3000 -n requestflow
```

Then open:

```text
Prometheus: http://localhost:9091
Grafana:    http://localhost:3002
```

#### Useful Kubernetes checks

```cmd
kubectl get pods -n requestflow
kubectl get services -n requestflow
kubectl get pvc -n requestflow
kubectl get ingress -n requestflow
```

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

For the normal development stack:

```cmd
docker compose exec postgres psql -U requestflow_user -d requestflow_db
```

For the production-local stack:

```cmd
docker compose -p requestflow-prod-local -f docker-compose.prod-local.yml exec postgres psql -U requestflow_user -d requestflow_db
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

## Database Migrations

Alembic is the source of truth for database schema changes.

From the backend virtual environment:

```cmd
cd backend
.venv\Scripts\activate.bat
alembic current
alembic upgrade head
alembic check
```

Expected behaviour:

```text
alembic current      → shows the active database revision
alembic upgrade head → applies all pending migrations
alembic check        → confirms that model changes do not require a new migration
```

In normal startup flows, migrations run automatically before the API starts:

```text
Docker Compose → migrate service → backend
Kubernetes     → run-migrations init container → backend container
Render         → alembic upgrade head → Uvicorn
```

Create a new migration only after intentionally changing SQLAlchemy models:

```cmd
alembic revision --autogenerate -m "describe schema change"
alembic upgrade head
alembic check
```

Review every autogenerated migration before committing it.

---

## Running Tests

The project includes backend and frontend tests.

### Backend Tests

Backend tests are written with Pytest and cover authentication, request management, role-based access control, and comments.

A Python virtual environment is only needed when running the backend or backend tests directly on Windows. It is not needed when using Docker Compose or Kubernetes.

#### First-time Windows Command Prompt setup

From the project root:

```cmd
cd backend
python -m venv .venv
.venv\Scripts\activate.bat
python -m pip install --upgrade pip
python -m pip install -r requirements.txt
python -m pytest
```

#### Later Windows Command Prompt sessions

```cmd
cd backend
.venv\Scripts\activate.bat
python -m pytest
```

Deactivate the environment with:

```cmd
deactivate
```

---

### When to Use the Backend `.venv`

| Task | Use backend `.venv`? |
|---|---|
| Run `python -m pytest` locally | Yes |
| Run FastAPI directly with Uvicorn | Yes |
| Install backend Python dependencies locally | Yes |
| Run frontend `npm` commands | No |
| Run Docker Compose | No |
| Run Kubernetes, `kubectl`, or Helm | No |
| Run Git commands | No |
| Use WSL | Use a separate `.venv-wsl` |

The `.venv` only isolates Python packages for direct local backend work. Docker and Kubernetes use the dependencies installed inside their own container images.

---

### Frontend Tests

Frontend tests are written with Vitest and React Testing Library. They cover core UI behaviour such as login rendering, registration rendering, request form rendering, and role-based navigation.

From the project root:

```cmd
cd frontend
npm test
```

---

### Frontend Build Check

From the project root:

```cmd
cd frontend
npm run build
```

---

### Docker Build Check

From the project root:

```cmd
docker build ./backend
```

---

## GitHub Actions CI and Container Publishing

This project uses GitHub Actions for both validation and container publishing.

### CI workflow

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

### Container security workflow

The Trivy workflow builds and scans both application images.

It checks:

- Operating-system packages
- Python, npm, and other detected application libraries
- Fixable `HIGH` and `CRITICAL` vulnerabilities

Workflow file:

```text
.github/workflows/security.yml
```

A fixable HIGH or CRITICAL vulnerability causes the workflow to fail, preventing a green security check until the vulnerable base image or dependency is updated.

---

### GHCR publishing workflow

The DevOps workflow builds and publishes both application images to GitHub Container Registry:

```text
ghcr.io/keith800x/requestflow-backend:devops
ghcr.io/keith800x/requestflow-frontend:devops
```

Each build also receives a Git commit SHA tag, providing a traceable image for a specific source revision.

Workflow file:

```text
.github/workflows/docker-publish.yml
```

Publishing flow:

```text
Push to devops-extension
→ GitHub Actions builds backend image
→ GitHub Actions builds frontend image with VITE_API_BASE_URL=/api
→ both images are pushed to GHCR
→ Kubernetes pulls the published images
```

---

## Deployment

The application is deployed using:

| Component | Platform |
|---|---|
| Frontend | Vercel |
| Backend API | Render Web Service |
| Database | Neon PostgreSQL |
| CI and Security | GitHub Actions and Trivy |

Public Deployment flow:

```text
Push to GitHub master branch
→ GitHub Actions runs backend tests, run frontend component tests, frontend build, and Docker build checks
→ Vercel redeploys the frontend
→ Render redeploys the backend
→ Render runs Alembic migrations and connects to Neon PostgreSQL
```

The DevOps extension provides a second deployment model for local infrastructure testing:

```text
GHCR images
→ Docker Desktop Kubernetes
→ Traefik Ingress
→ React/Nginx frontend
→ FastAPI backend
→ PostgreSQL StatefulSet

Prometheus → FastAPI metrics
Grafana → Prometheus
```

The local Kubernetes deployment is a portfolio and learning environment. It does not replace the public Vercel and Render demonstration.


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
│   │   ├── models/                                     # SQLAlchemy database models
│   │   ├── routers/                                    # FastAPI route handlers
│   │   ├── schemas/                                    # Pydantic request/response schemas
│   │   ├── services/                                   # Security and helper services
│   │   ├── tests/                                      # Pytest backend tests
│   │   ├── auth_dependencies.py                        # Authentication and admin dependencies
│   │   ├── database.py                                 # Database engine and session setup
│   │   ├── enums.py                                    # Shared enum values
│   │   └── main.py                                     # FastAPI application entry point
│   ├── alembic/                                        # Versioned database migration scripts
│   ├── alembic.ini                                     # Alembic configuration
│   ├── Dockerfile                                      # Backend Docker image
│   ├── requirements.txt                                # Backend dependencies
│   └── .env.example                                    # Example backend environment variables
│
├── frontend/
│   ├── public/                                         # Static public assets
│   ├── src/
│   │   ├── api/                                        # Axios API clients
│   │   ├── assets/                                     # Frontend assets imported by React
│   │   ├── components/                                 # Shared layout and route guards
│   │   ├── pages/                                      # React page components and page tests
│   │   ├── test/                                       # Vitest and React Testing Library setup
│   │   ├── utils/                                      # Date, error, search, filter, and sorting helpers
│   │   ├── App.tsx                                     # Frontend route configuration
│   │   ├── App.css                                     # App-level component styling
│   │   ├── main.tsx                                    # React entry point
│   │   └── index.css                                   # Global styling
│   ├── index.html                                      # Vite HTML entry point
│   ├── package.json                                    # Frontend scripts and dependencies
│   ├── package-lock.json                               # Locked npm dependencies
│   ├── vite.config.ts                                  # Vite and Vitest configuration
│   ├── eslint.config.js                                # ESLint configuration
│   ├── tsconfig.json                                   # Main TypeScript configuration
│   ├── tsconfig.app.json                               # TypeScript config for frontend app code
│   ├── tsconfig.node.json                              # TypeScript config for Node/Vite config files
│   ├── .env.example                                    # Example frontend environment variables
│   └── vercel.json                                     # SPA route fallback for Vercel
│ 
│
├── monitoring/
│   ├── prometheus.yml                                  #  Prometheus scrape and rule configuration
│   ├── requestflow-alerts.yml                          # Backend availability alert rule
│   └── grafana/
│       ├── dashboards/
│       │   └── requestflow-backend-dashboard.json
│       └── provisioning/
│           ├── dashboards/
│           └── datasources/
│
├── k8s/
│   ├── monitoring/
│   │   ├── prometheus.yml
│   │   ├── prometheus-config.yml                       # Backend availability alert rule
│   │   ├── grafana-provisioning.yml
│   │   ├── grafana-dashboard-configmap.yml
│   │   └── grafana.yml
│   ├── namespace.yml
│   ├── configmap.yml
│   ├── secret.example.yml
│   ├── secret.local.yml                                # Local only; ignored by Git
│   ├── postgres.yml                                    # PostgreSQL StatefulSet, Service, and PVC
│   ├── backend.yml                                     # FastAPI Deployment and Service
│   ├── frontend.yml                                    # React/Nginx Deployment and Service
│   ├── ingress.yml                                     # Traefik routes and StripPrefix middleware
│   └── traefik-values.yml                              # Helm values for Traefik
│
├── scripts/
│   ├── deploy-k8s.ps1                                  # Repeatable Kubernetes deployment
│   └── verify-k8s.ps1                                  # Ingress and health verification
│
│
├── .github/
│   └── workflows/
│       ├── ci.yml                                      # Test and build validation
│       ├── docker-publish.yml                          # GHCR image publishing
│       └── security.yml                                # Trivy container vulnerability scanning
├── assets/
│   ├── app/
│   │   ├── login-page.png
│   │   ├── user-requests.png
│   │   ├── admin-request-detail.png
│   │   └── api-documentation.png
│   └── devops/
│       ├── kubernetes-before-recreation.png
│       ├── kubernetes-clean-deployment.png
│       ├── kubernetes-verification.png
│       ├── prometheus-targets.png
│       ├── prometheus-backend-down-alert.png
│       ├── grafana-dashboard.png
│       ├── grafana-datasource.png
│       ├── github-actions-publish.png
│       ├── github-actions-trivy.png
│       └── ghcr-packages.png
│
├── docker-compose.yml                                  # Local frontend, backend, and PostgreSQL setup
├── docker-compose.prod-local.yml                       # Production-style local Nginx stack
├── docker-compose.frontend-remote.yml                  # Local frontend connected to deployed backend
├── .env.remote.example                                 # Example env file for remote backend testing
├── .gitignore                                          # Git ignore rules
├── README.md                                           # Project documentation
└── LICENSE                                             # Project license
```

---

## Limitations & Future Work

### Limitations

- The public demonstration uses Vercel and Render rather than the local Kubernetes environment.
- The Kubernetes environment currently runs on Docker Desktop and is intended for portfolio and learning use.
- The project is currently designed for local development and portfolio demonstration.
- The project is deployed for portfolio demonstration, but production hardening is still limited.
- The deployed backend may take longer to respond after inactivity because the Render free web service can spin down and wake on the next request.
- Admin account promotion is currently done manually through PostgreSQL.
- User management is limited; admins cannot yet promote or demote users through the frontend.
- The application should not be used for real confidential IT tickets without stronger production security controls.
- Kubernetes secrets are managed through a local ignored manifest rather than an external secret manager.
- The Ingress currently uses local HTTP rather than trusted HTTPS.
- Prometheus and Grafana are configured for local monitoring; the alert rule is evaluated successfully, but no Alertmanager notification receiver is configured.

### Future Improvements

- Add admin user management for promoting and demoting users.
- Add search, filter, and sorting for requests.
- Add request assignment to specific admins or support staff.
- Add request analytics dashboard.
- Improve production deployment with database migrations, stronger monitoring, and automated release checks.
- Add email notifications for request updates
- Add file attachment support for service requests.
- Add audit logs for admin actions.
- Improve UI styling with a component library or design system.
- Add Kubernetes NetworkPolicies between frontend, backend, PostgreSQL, Prometheus, and Grafana.
- Add TLS/HTTPS termination for Traefik.
- Create a separate networking or cloud branch for cloud VM or managed Kubernetes deployment.
- Optionally package the Kubernetes resources with Kustomize or Helm.
- Run clean-state Kubernetes deployment verification automatically in CI using an ephemeral test cluster.
- Add Alertmanager with email, Slack, or another external notification receiver.
- Add dependency-update automation, secret scanning, and software bill of materials generation.
- Add a production release workflow with migration approval, smoke testing, and rollback documentation.

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

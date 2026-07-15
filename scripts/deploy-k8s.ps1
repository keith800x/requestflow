$ErrorActionPreference = "Stop"

Write-Host "Deploying RequestFlow to Kubernetes..." -ForegroundColor Cyan

Write-Host "`n1. Creating namespace..."
kubectl apply -f k8s/namespace.yml

Write-Host "`n2. Applying application configuration..."
kubectl apply -f k8s/configmap.yml

if (-not (Test-Path "k8s/secret.local.yml")) {
    Write-Host "`nMissing k8s/secret.local.yml" -ForegroundColor Red
    Write-Host "Copy k8s/secret.example.yml and insert your local secrets."
    exit 1
}

Write-Host "`n3. Applying local Kubernetes Secret..."
kubectl apply -f k8s/secret.local.yml

Write-Host "`n4. Deploying PostgreSQL..."
kubectl apply -f k8s/postgres.yml

Write-Host "Waiting for PostgreSQL..."
kubectl rollout status statefulset/requestflow-postgres `
    --namespace requestflow `
    --timeout=180s

Write-Host "`n5. Deploying backend..."
kubectl apply -f k8s/backend.yml

Write-Host "Waiting for backend..."
kubectl rollout status deployment/requestflow-backend `
    --namespace requestflow `
    --timeout=180s

Write-Host "`n6. Deploying frontend..."
kubectl apply -f k8s/frontend.yml

Write-Host "Waiting for frontend..."
kubectl rollout status deployment/requestflow-frontend `
    --namespace requestflow `
    --timeout=180s

Write-Host "`n7. Deploying Prometheus..."
kubectl apply -f k8s/monitoring/prometheus-config.yml
kubectl apply -f k8s/monitoring/prometheus.yml

Write-Host "Waiting for Prometheus..."
kubectl rollout status deployment/requestflow-prometheus `
    --namespace requestflow `
    --timeout=180s

Write-Host "`n8. Deploying Grafana..."
kubectl apply -f k8s/monitoring/grafana-provisioning.yml
kubectl apply -f k8s/monitoring/grafana-dashboard-configmap.yml
kubectl apply -f k8s/monitoring/grafana.yml

Write-Host "Waiting for Grafana..."
kubectl rollout status deployment/requestflow-grafana `
    --namespace requestflow `
    --timeout=180s

Write-Host "`n9. Applying RequestFlow Ingress..."
kubectl apply -f k8s/ingress.yml

Write-Host "`nDeployment complete." -ForegroundColor Green

kubectl get pods -n requestflow
kubectl get services -n requestflow
kubectl get ingress -n requestflow

Write-Host "`nApplication: http://requestflow.localhost" -ForegroundColor Cyan
Write-Host "API health: http://requestflow.localhost/api/health"
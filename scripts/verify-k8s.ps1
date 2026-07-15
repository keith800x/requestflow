$ErrorActionPreference = "Stop"

Write-Host "Checking Kubernetes resources..." -ForegroundColor Cyan

kubectl get pods -n requestflow
kubectl get services -n requestflow
kubectl get pvc -n requestflow
kubectl get ingress -n requestflow

Write-Host "`nTesting frontend through Traefik Ingress..."

$frontendStatus = & curl.exe `
    -sS `
    -o NUL `
    -w "%{http_code}" `
    -H "Host: requestflow.localhost" `
    http://127.0.0.1/

if ($LASTEXITCODE -ne 0) {
    throw "Could not connect to the Traefik Ingress."
}

if ($frontendStatus.Trim() -ne "200") {
    throw "Frontend check failed with HTTP status $frontendStatus."
}

Write-Host "Frontend returned HTTP 200." -ForegroundColor Green

Write-Host "`nTesting backend health through Ingress..."

$healthJson = & curl.exe `
    -sS `
    -H "Host: requestflow.localhost" `
    http://127.0.0.1/api/health

if ($LASTEXITCODE -ne 0) {
    throw "Backend health request failed."
}

$health = $healthJson | ConvertFrom-Json

if ($health.status -ne "healthy") {
    throw "Backend health check failed."
}

Write-Host "Backend is healthy." -ForegroundColor Green

Write-Host "`nTesting backend readiness through Ingress..."

$readyJson = & curl.exe `
    -sS `
    -H "Host: requestflow.localhost" `
    http://127.0.0.1/api/ready

if ($LASTEXITCODE -ne 0) {
    throw "Backend readiness request failed."
}

$ready = $readyJson | ConvertFrom-Json

if ($ready.status -ne "ready") {
    throw "Backend readiness check failed."
}

Write-Host "Backend is ready." -ForegroundColor Green

Write-Host "`nRequestFlow Kubernetes verification passed." -ForegroundColor Green
# PowerShell-Skript zum Einrichten einer Kubernetes-Entwicklungsumgebung

$currentPath = (Get-Location).Path
$k8sPath = $currentPath -replace "\\", "/"

# Git-Configuration and ssh path
$userProfile = $env:USERPROFILE
$gitConfigPath = "$userProfile\.gitconfig"
$sshPath = "$userProfile\.ssh"

# update kubernetes-pod.yaml
$podYaml = Get-Content -Path "kubernetes-pod.yaml" -Raw
$podYaml = $podYaml -replace "REPLACE_WITH_ABSOLUTE_PATH", $k8sPath
$podYaml = $podYaml -replace "C:/Users/YOURUSER/.gitconfig", $gitConfigPath.Replace("\", "/")
$podYaml = $podYaml -replace "C:/Users/YOURUSER/.ssh", $sshPath.Replace("\", "/")
$podYaml | Set-Content -Path "kubernetes-pod.yaml" -Force

Write-Host "Kubernetes-Pod-Configuration updated." -ForegroundColor Green

# Build Docker image
Write-Host "Building Docker-Image..." -ForegroundColor Yellow
docker build -t  glowphonic-zig-dev:latest -f .devcontainer/Dockerfile .

# Create and test Kubernetes-Namespace
$namespaceExists = kubectl get namespace mhudasch-glowphonic 2>$null
if (-not $namespaceExists) {
    Write-Host "Creating namespace 'mhudasch-glowphonic'..." -ForegroundColor Yellow
    kubectl create namespace mhudasch-glowphonic
} else {
    Write-Host "Namespace 'mhudasch-glowphonic' already exists." -ForegroundColor Green
}

Write-Host "Create dev-pod for kubernetes cluster..." -ForegroundColor Yellow
kubectl apply -f kubernetes-pod.yaml

Write-Host "Waiting for pod to be up..." -ForegroundColor Yellow
kubectl wait --for=condition=Ready pod/ glowphonic-zig-dev -n mhudasch-glowphonic --timeout=120s

Write-Host "Kubernetes development environment is ready!" -ForegroundColor Green
Write-Host "You can now use the Kubernetes dev-pod provider:" -ForegroundColor Green
Write-Host "  devpod up ." -ForegroundColor Cyan
Write-Host "Or connect directly using kubectl:" -ForegroundColor Green
Write-Host "  kubectl exec -it  glowphonic-zig-dev -n mhudasch-glowphonic -- bash" -ForegroundColor Cyan
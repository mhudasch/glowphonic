#!/bin/bash
# WSL2 setup script for Kubernetes deployment

# Exit on error
set -e

echo "Setting up Kubernetes environment for Zig Audio Player in WSL2..."

# Get current directory (WSL2 path)
CURRENT_DIR=$(pwd)

# Function to convert Windows path to WSL path
win_to_wsl_path() {
    # Replace backslashes with forward slashes and convert drive letter
    echo "$1" | sed 's/\\/\//g' | sed 's/^\([A-Za-z]\):/\/mnt\/\L\1/'
}

# Function to check if running in WSL2
check_wsl() {
    if grep -qi microsoft /proc/version; then
        echo "WSL2 detected."
    else
        echo "Not running in WSL2. This script is designed for WSL2 environments."
        exit 1
    fi
}

# Check WSL2
check_wsl

# Check if kubectl is installed
if ! command -v kubectl &> /dev/null; then
    echo "kubectl is not installed. Installing..."
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
    rm kubectl
else
    echo "kubectl is already installed."
fi

# Check Docker connection
if ! docker info &> /dev/null; then
    echo "Cannot connect to Docker. Please ensure Docker Desktop is running with WSL2 integration enabled."
    exit 1
fi

# Check if Kubernetes is enabled in Docker Desktop
if ! kubectl get nodes &> /dev/null; then
    echo "Cannot connect to Kubernetes. Please enable Kubernetes in Docker Desktop."
    exit 1
fi

# Update kubernetes-pod.yaml paths for WSL2
echo "Updating Kubernetes pod configuration for WSL2 paths..."

# Get Windows home path
WIN_HOME=$(wslpath -w "$HOME" | sed 's/\\/\//g' | sed 's/\([A-Za-z]\):\//\L\1\//')
WSL_PROJECT_PATH=$CURRENT_DIR

# Create a temporary file with updated paths
cat kubernetes-pod.yaml | \
  sed "s|REPLACE_WITH_ABSOLUTE_PATH|$WSL_PROJECT_PATH|g" | \
  sed "s|C:/Users/YOURUSER/.gitconfig|$HOME/.gitconfig|g" | \
  sed "s|C:/Users/YOURUSER/.ssh|$HOME/.ssh|g" > kubernetes-pod-wsl.yaml

# Build Docker image
echo "Building Docker image..."
docker build -t glowphonic-zig-dev:latest -f .devcontainer/Dockerfile .

# Create namespace if it doesn't exist
if ! kubectl get namespace zig-dev &> /dev/null; then
    echo "Creating Kubernetes namespace 'zig-dev'..."
    kubectl create namespace zig-dev
else
    echo "Namespace 'zig-dev' already exists."
fi

# Apply Kubernetes configuration
echo "Deploying to Kubernetes..."
kubectl apply -f kubernetes-pod-wsl.yaml

# Wait for pod to be ready
echo "Waiting for pod to be ready..."
kubectl wait --for=condition=Ready pod/glowphonic-zig-dev -n zig-dev --timeout=120s

echo "Kubernetes environment setup complete!"
echo "You can now connect to your development environment with:"
echo "  kubectl exec -it glowphonic-zig-dev -n zig-dev -- bash"
echo "Or use DevPod:"
echo "  devpod up ."
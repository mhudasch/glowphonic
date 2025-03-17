#!/bin/bash
# WSL2 setup script for Kubernetes deployment with custom namespace and image name

# Exit on error
set -e

# Custom configuration
NAMESPACE="mhudasch-glowphonic"
IMAGE_NAME="glowphonic-zig-dev"
POD_NAME="glowphonic-zig-dev"

echo "Setting up Kubernetes environment for Glowphonic in WSL2..."

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
    echo "If you're getting permission errors, try these commands:"
    echo "  sudo groupadd docker"
    echo "  sudo usermod -aG docker \$USER"
    echo "  newgrp docker"
    echo "Then restart Docker Desktop."
    exit 1
fi

# Check if Kubernetes is enabled in Docker Desktop
if ! kubectl get nodes &> /dev/null; then
    echo "Cannot connect to Kubernetes. Please enable Kubernetes in Docker Desktop."
    exit 1
fi

# Update kubernetes-pod.yaml paths for WSL2
echo "Updating Kubernetes pod configuration for WSL2 paths..."

# Create a temporary pod YAML with updated paths and names
cat > kubernetes-pod-wsl.yaml << EOF
apiVersion: v1
kind: Pod
metadata:
  name: ${POD_NAME}
  namespace: ${NAMESPACE}
  labels:
    app: glowphonic
spec:
  containers:
  - name: dev
    image: ${IMAGE_NAME}:latest
    imagePullPolicy: Never  # Use local image
    command: ["sleep", "infinity"]
    resources:
      requests:
        memory: "1Gi"
        cpu: "500m"
      limits:
        memory: "2Gi"
        cpu: "1"
    volumeMounts:
    - name: workspace
      mountPath: /workspace
    - name: git-config
      mountPath: /home/vscode/.gitconfig
      readOnly: true
    - name: ssh
      mountPath: /home/vscode/.ssh
      readOnly: true
    securityContext:
      privileged: true  # For debugging tools
  volumes:
  - name: workspace
    hostPath:
      path: "${CURRENT_DIR}"
  - name: git-config
    hostPath:
      path: "${HOME}/.gitconfig"
  - name: ssh
    hostPath:
      path: "${HOME}/.ssh"
EOF

# Build Docker image with custom name
echo "Building Docker image: ${IMAGE_NAME}:latest..."
docker build -t ${IMAGE_NAME}:latest -f .devcontainer/Dockerfile .

# Create namespace if it doesn't exist
if ! kubectl get namespace ${NAMESPACE} &> /dev/null; then
    echo "Creating Kubernetes namespace '${NAMESPACE}'..."
    kubectl create namespace ${NAMESPACE}
else
    echo "Namespace '${NAMESPACE}' already exists."
fi

# Apply Kubernetes configuration
echo "Deploying to Kubernetes..."
kubectl apply -f kubernetes-pod-wsl.yaml

# Wait for pod to be ready
echo "Waiting for pod to be ready..."
kubectl wait --for=condition=Ready pod/${POD_NAME} -n ${NAMESPACE} --timeout=120s

echo "Kubernetes environment setup complete!"
echo "You can now connect to your development environment with:"
echo "  kubectl exec -it ${POD_NAME} -n ${NAMESPACE} -- bash"
echo "Or use DevPod:"
echo "  devpod up ."

# Setting up Docker with WSL2 for glowphonic Development

This guide walks through setting up Docker with WSL2 and configuring Kubernetes for the glowphonic project.

## Prerequisites

1. Windows 10 version 2004 or higher (Build 19041 or higher) or Windows 11
2. At least 8GB of RAM (16GB recommended)
3. Administrator rights on your Windows machine

## Step 1: Enable WSL2 on Windows

1. Open PowerShell as Administrator and run:

```powershell
# Enable Windows features
dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart

# Restart your computer
```

1. After restarting, download and install the WSL2 Linux kernel update package:
   - Download from: https://aka.ms/wsl2kernel
   - Double-click the downloaded file and follow the installation instructions

2. Set WSL2 as the default version:

```powershell
wsl --set-default-version 2
```

## Step 2: Install Ubuntu on WSL2

1. Open Microsoft Store
2. Search for "Ubuntu" (Ubuntu 20.04 LTS or the latest version)
3. Click "Get" to install it
4. Launch Ubuntu and complete the initial setup (create a username and password)

## Step 3: Install Docker Desktop

1. Download Docker Desktop from: https://www.docker.com/products/docker-desktop
2. Install Docker Desktop, ensuring WSL2 integration is selected during installation
3. After installation, open Docker Desktop settings:
   - Go to Settings > Resources > WSL Integration
   - Enable integration with Ubuntu
   - Click "Apply & Restart"

## Step 4: Configure Docker in WSL2

1. Open Ubuntu terminal and verify Docker is working:

```bash
docker --version
docker run hello-world
```

2. Install additional tools in WSL2 Ubuntu:

```bash
# Update packages
sudo apt update && sudo apt upgrade -y

# Install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
rm kubectl

# Install Helm
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Install k9s (optional Kubernetes UI)
curl -sS https://webinstall.dev/k9s | bash
```

## Step 5: Enable Kubernetes in Docker Desktop

1. Open Docker Desktop
2. Go to Settings > Kubernetes
3. Check "Enable Kubernetes"
4. Click "Apply & Restart"
5. Wait for Kubernetes to start (this may take several minutes)

## Step 6: Set Up Path Sharing between Windows and WSL2

WSL2 has its own filesystem, so we need to ensure proper path mapping:

1. From within WSL2, Windows drives are mounted under `/mnt/`
   - For example, `C:\Users\` is accessible as `/mnt/c/Users/`

2. For the Kubernetes configuration, we need to update our paths:

```bash
# In WSL2 Ubuntu terminal
cd /mnt/c/path/to/your/project
```

3. Update the Kubernetes pod configuration to use WSL2 paths:

```bash
# Convert Windows paths to WSL2 paths in kubernetes-pod.yaml
sed -i 's|C:/Users|/mnt/c/Users|g' kubernetes-pod.yaml
```

## Step 7: Configure kubectl to use Docker Desktop's Kubernetes

```bash
# In WSL2 Ubuntu terminal
mkdir -p ~/.kube
cp /mnt/c/Users/[YourUsername]/.kube/config ~/.kube/config

# Verify Kubernetes connection
kubectl get nodes
```

## Step 8: Run the Development Environment

Option 1: Using DevPod:

```bash
# Install DevPod in WSL2
curl -fsSL https://devpod.sh/install.sh | bash

# Start DevPod
devpod up .
```

Option 2: Using kubectl directly:

```bash
# Create namespace
kubectl create namespace mhudasch-glowphonic

# Apply pod configuration
kubectl apply -f kubernetes-pod.yaml

# Connect to the pod
kubectl exec -it glowphonic-zig-dev -n mhudasch-glowphonic -- bash
```

## Notes on WSL2 Performance

- Docker runs natively in WSL2, providing better performance than the previous Hyper-V backend
- File I/O is much faster when working with files in the Linux filesystem (not in /mnt/)
- For best performance, clone your repository into the WSL2 filesystem
- If working on Windows files through /mnt/, expect some performance degradation
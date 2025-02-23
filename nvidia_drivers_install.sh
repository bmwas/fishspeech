#!/bin/bash

## installs docker
# Exit immediately if a command exits with a non-zero status
set -e


# Function to check if NVIDIA drivers are installed
check_nvidia_drivers() {
    if command -v nvidia-smi &> /dev/null; then
        echo "NVIDIA drivers are installed."
        return 0
    else
        echo "NVIDIA drivers are not installed."
        return 1
    fi
}

# Function to install or update NVIDIA drivers
install_or_update_nvidia_drivers() {
    echo "Adding NVIDIA PPA..."
    sudo add-apt-repository -y ppa:graphics-drivers/ppa
    sudo apt-get update -y

    # Install ubuntu-drivers-common if not installed
    if ! dpkg -l | grep -q ubuntu-drivers-common; then
        echo "Installing ubuntu-drivers-common package..."
        sudo apt-get install -y ubuntu-drivers-common
    fi

    # Automatically install the recommended NVIDIA driver
    echo "Installing the recommended NVIDIA driver..."
    sudo ubuntu-drivers autoinstall
}

# Function to install Docker
install_docker() {
    echo "Installing Docker..."
    sudo apt-get remove -y docker docker-engine docker.io containerd runc || true
    sudo apt-get update -y
    sudo apt-get install -y \
        ca-certificates \
        curl \
        gnupg \
        lsb-release

    # Add Docker's official GPG key
    sudo mkdir -p /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

    # Set up the Docker repository
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
      $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    # Install Docker Engine
    sudo apt-get update -y
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

    # Start and enable Docker service
    sudo systemctl start docker
    sudo systemctl enable docker
}

# Function to install NVIDIA Container Toolkit
install_nvidia_container_toolkit() {
    echo "Installing NVIDIA Container Toolkit..."

    # Add the NVIDIA Container Toolkit repository
    distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
    curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg
    curl -s -L https://nvidia.github.io/libnvidia-container/stable/$distribution/nvidia-container-toolkit.list |
        sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' |
        sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list

    # Install the NVIDIA Container Toolkit
    sudo apt-get update -y
    sudo apt-get install -y nvidia-container-toolkit

    # Configure the Docker daemon to use the NVIDIA Container Toolkit
    sudo nvidia-ctk runtime configure --runtime=docker

    # Restart the Docker daemon to apply changes
    sudo systemctl restart docker
}

# Step 1: Update the system
echo "Updating the system..."
sudo apt-get update -y && sudo apt-get upgrade -y

# Step 2: Check and handle NVIDIA drivers
if check_nvidia_drivers; then
    echo "Updating NVIDIA drivers..."
    install_or_update_nvidia_drivers
else
    echo "Installing NVIDIA drivers..."
    install_or_update_nvidia_drivers
fi

# Step 3: Install Docker
if ! command -v docker &> /dev/null; then
    install_docker
else
    echo "Docker is already installed."
fi

# Step 4: Install NVIDIA Container Toolkit
install_nvidia_container_toolkit

# Step 5: Verify installation
echo "Verifying NVIDIA driver installation..."
if command -v nvidia-smi &> /dev/null; then
    nvidia-smi
else
    echo "Failed to install NVIDIA drivers. Please check logs for details."
    exit 1
fi

echo "Verifying Docker installation..."
if sudo docker run --rm --gpus all nvcr.io/nvidia/cuda:11.3.1-cudnn8-devel-ubuntu20.04 nvidia-smi; then
    echo "Docker and NVIDIA Container Toolkit are installed and configured successfully."
else
    echo "Failed to run Docker container with GPU support. Please check logs for details."
    exit 1
fi

## Install CUDA

echo "Installing CUDA..."
sudo apt install nvidia-cuda-toolkit
echo "CUDA installation complete."

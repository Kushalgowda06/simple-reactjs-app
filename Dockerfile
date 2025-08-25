name: CI/CD for Simple ReactJS App

on:
  push:
    branches:
      - main

jobs:
  build_and_deploy:
    runs-on: ubuntu-latest
    steps:
    
    # Checkout the repository
    - name: Checkout code
      uses: actions/checkout@v2

    # Set up Docker Buildx
    - name: Set up Docker Buildx
      uses: docker/setup-buildx-action@v1

    # Cache Docker layers
    - name: Cache Docker layers
      uses: actions/cache@v2
      with:
        path: /tmp/.buildx-cache
        key: ${{ runner.os }}-docker-${{ github.sha }}
        restore-keys: |
          ${{ runner.os }}-docker-

    # Log in to Docker Hub
    - name: Log in to Docker Hub
      uses: docker/login-action@v2
      with:
        username: ${{ secrets.DOCKER_USERNAME }}
        password: ${{ secrets.DOCKER_PASSWORD }}

    # Build Docker image
    - name: Build Docker image
      run: |
        docker build -t ${{ secrets.DOCKER_USERNAME }}/simple-reactjs-app:latest .

    # Push Docker image to Docker Hub
    - name: Push Docker image to Docker Hub
      run: |
        docker push ${{ secrets.DOCKER_USERNAME }}/simple-reactjs-app:latest

    # Deploy to EC2 via SSH
    - name: Deploy to EC2 via SSH
      uses: appleboy/ssh-action@v0.1.10
      with:
        host: ${{ secrets.EC2_HOST }}
        username: ${{ secrets.EC2_USERNAME }}
        key: ${{ secrets.EC2_SSH_KEY }}
        port: ${{ secrets.EC2_SSH_PORT }}
        script: |
          # Log the start time for troubleshooting
          echo "Starting the deployment process at $(date)"

          # Check for available disk space
          echo "Checking disk space..."
          df -h

          # Install Docker if not installed
          if ! command -v docker &> /dev/null
          then
            echo "Docker not found. Installing Docker..."

            # Update system packages
            echo "Running apt-get update..."
            sudo apt-get update || { echo "apt-get update failed"; exit 1; }

            # Install required dependencies for Docker
            echo "Installing dependencies for Docker..."
            sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common || { echo "Dependency installation failed"; exit 1; }

            # Get Docker installation script
            echo "Downloading Docker installation script..."
            curl -fsSL https://get.docker.com -o get-docker.sh || { echo "Docker script download failed"; exit 1; }

            # Run Docker installation script
            echo "Running Docker installation script..."
            sudo sh get-docker.sh || { echo "Docker installation failed"; exit 1; }

            # Add user to docker group
            echo "Adding user to Docker group..."
            sudo usermod -aG docker $(whoami) || { echo "Failed to add user to Docker group"; exit 1; }

            # Enable and start Docker service
            echo "Starting Docker service..."
            sudo systemctl enable docker || { echo "Failed to enable Docker service"; exit 1; }
            sudo systemctl start docker || { echo "Failed to start Docker service"; exit 1; }
          else
            echo "Docker is already installed"
          fi

          # Check Docker version to ensure it's installed
          echo "Checking Docker version..."
          docker --version || { echo "Docker version check failed"; exit 1; }

          # Pull the Docker image from Docker Hub
          echo "Pulling the Docker image ${{ secrets.DOCKER_USERNAME }}/simple-reactjs-app:latest"
          docker pull ${{ secrets.DOCKER_USERNAME }}/simple-reactjs-app:latest || { echo "Docker pull failed"; exit 1; }

          # Stop and remove any running container with the same name
          echo "Stopping and removing any existing container..."
          docker stop simple-reactjs-app || true
          docker rm simple-reactjs-app || true

          # Run the Docker container with the latest image
          echo "Running the Docker container on port 80..."
          docker run -d --name simple-reactjs-app -p 80:80 ${{ secrets.DOCKER_USERNAME }}/simple-reactjs-app:latest || { echo "Docker run failed"; exit 1; }

          # Check running Docker containers
          echo "Checking running Docker containers..."
          docker ps

          # Confirm successful deployment
          echo "Deployment completed successfully at $(date)"

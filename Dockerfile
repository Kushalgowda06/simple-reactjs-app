name: Build, Push, and Deploy React App on EC2

on:
  push:
    branches:
      - master  # Change to your default branch if it's different

jobs:
  build_and_deploy:
    runs-on: ubuntu-latest

    steps:
    # Checkout the repo
    - name: Checkout code
      uses: actions/checkout@v2

    # Set up Docker Buildx
    - name: Set up Docker Buildx
      uses: docker/setup-buildx-action@v2

    # Log in to Docker Hub
    - name: Log in to Docker Hub
      uses: docker/login-action@v2
      with:
        username: ${{ secrets.DOCKER_USERNAME }}
        password: ${{ secrets.DOCKER_PASSWORD }}

    # Build the Docker image and push it to Docker Hub
    - name: Build and push Docker image
      run: |
        # Build the Docker image with tag as 'latest'
        docker build -t ${{ secrets.DOCKER_USERNAME }}/simple-reactjs-app:latest .
        # Push the image to Docker Hub
        docker push ${{ secrets.DOCKER_USERNAME }}/simple-reactjs-app:latest

    # Deploy to EC2 via SSH
    - name: Deploy to EC2
      uses: appleboy/ssh-action@v0.1.10
      with:
        host: ${{ secrets.DEPLOY_HOST }}
        username: ${{ secrets.DEPLOY_USER }}
        key: ${{ secrets.DEPLOY_KEY }}
        script: |
          echo "Starting deployment process on EC2..."
          
          # Pull the latest Docker image from Docker Hub
          docker pull ${{ secrets.DOCKER_USERNAME }}/simple-reactjs-app:latest || { echo "Docker pull failed"; exit 1; }
          
          # Stop and remove any running container if exists
          docker stop simple-reactjs-app || true
          docker rm simple-reactjs-app || true

          # Run the container on port 80
          docker run -d --name simple-reactjs-app -p 80:80 ${{ secrets.DOCKER_USERNAME }}/simple-reactjs-app:latest || { echo "Docker run failed"; exit 1; }
          
          echo "Deployment completed successfully!"

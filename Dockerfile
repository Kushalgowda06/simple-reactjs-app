name: Deploy React App on EC2

on:
  push:
    branches:
      - master

jobs:
  build_and_push:
    name: Build and Push Docker Image
    runs-on: ubuntu-latest

    steps:
      # Checkout the repository code
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

      # Build and push Docker image
      - name: Build and push Docker image
        run: |
          docker build -t ${{ secrets.DOCKER_USERNAME }}/simple-reactjs-app:latest .
          docker push ${{ secrets.DOCKER_USERNAME }}/simple-reactjs-app:latest

  deploy:
    name: Deploy Docker Container to EC2
    runs-on: ubuntu-latest
    needs: build_and_push

    steps:
      # Deploy using SSH and pull the Docker image on EC2
      - name: Deploy on EC2 via SSH
        uses: appleboy/ssh-action@v0.1.10
        with:
          host: ${{ secrets.DEPLOY_HOST }}
          username: ${{ secrets.DEPLOY_USER }}
          key: ${{ secrets.DEPLOY_KEY }}
          script: |
            # Pull the Docker image from Docker Hub
            docker pull ${{ secrets.DOCKER_USE_

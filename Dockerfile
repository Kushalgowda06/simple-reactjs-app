jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout repository
        uses: actions/checkout@v2

      - name: Deploy with SSH
        uses: appleboy/ssh-action@v0.1.10
        with:
          host: ${{ secrets.HOST }}
          username: ${{ secrets.USERNAME }}
          key: ${{ secrets.SSH_KEY }}
          script: |
            echo "Starting the deployment process at $(date)"
            echo "Checking disk space..."
            df -h

            # Install Docker if not installed
            if ! command -v docker &> /dev/null
            then
              echo "Docker not found. Installing Docker..."
              sudo apt-get update
              sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common
              curl -fsSL https://get.docker.com -o get-docker.sh
              sudo sh get-docker.sh
              sudo usermod -aG docker $(whoami)
              sudo systemctl enable docker
              sudo systemctl start docker
            else
              echo "Docker is already installed"
            fi

            # Pull the Docker image
            echo "Pulling the Docker image kushalgowda06/simple-reactjs-app:latest"
            docker pull kushalgowda06/simple-reactjs-app:latest

            # Stop and remove any existing container
            echo "Stopping and removing any existing container..."
            sudo docker stop simple-reactjs-app || true
            sudo docker rm simple-reactjs-app || true

            # Run the Docker container
            echo "Running the Docker container on port 80..."
            sudo docker run -d --name simple-reactjs-app -p 80:80 kushalgowda06/simple-reactjs-app:latest

            # Check Docker container status
            echo "Checking running Docker containers..."
            sudo docker ps

            echo "Deployment completed successfully at $(date)"

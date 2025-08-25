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
              sudo apt-get update || { echo "apt-get update failed"; exit 1; }
              sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common || { echo "Docker dependencies installation failed"; exit 1; }
              curl -fsSL https://get.docker.com -o get-docker.sh || { echo "Docker script download failed"; exit 1; }
              sudo sh get-docker.sh || { echo "Docker installation failed"; exit 1; }
              sudo usermod -aG docker $(whoami) || { echo "Failed to add user to Docker group"; exit 1; }
              sudo systemctl enable docker || { echo "Failed to enable Docker service"; exit 1; }
              sudo systemctl start docker || { echo "Failed to start Docker service"; exit 1; }
            else
              echo "Docker is already installed"
            fi

            # Docker login (for private images)
            echo "Logging into Docker..."
            echo ${{ secrets.DOCKER_PASSWORD }} | docker login -u ${{ secrets.DOCKER_USERNAME }} --password-stdin || { echo "Docker login failed"; exit 1; }

            # Pull the Docker image
            echo "Pulling the Docker image kushalgowda06/simple-reactjs-app:latest"
            docker pull kushalgowda06/simple-reactjs-app:latest || { echo "Docker pull failed"; exit 1; }

            # Stop and remove any existing container
            echo "Stopping and removing any existing container..."

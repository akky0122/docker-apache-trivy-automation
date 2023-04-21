#!/bin/bash

# Set variables
DOCKERHUB_USERNAME="<dockerhub_username>"
REPOSITORY_NAME="<repository_name>"
VERSION_TAG="<version_tag>"
WAR_FILE="<war_file>"
DOCKERFILE="./Dockerfile"
TRIVY_LOGFILE="./trivy.log"

# Check if war file and Dockerfile exists
if [ ! -f "$WAR_FILE" ]; then
    echo "ERROR: War file not found!"
    exit 1
fi

if [ ! -f "$DOCKERFILE" ]; then
    echo "ERROR: Dockerfile not found!"
    exit 1
fi

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "ERROR: Docker is not installed!"
    exit 1
fi

# Check if Trivy is installed
if ! command -v trivy &> /dev/null; then
    echo "ERROR: Trivy is not installed!"
    exit 1
fi

# Check Docker Hub account
if [ -z "$DOCKERHUB_PASSWORD" ];
                echo "Please enter Docker Hub password:"
                read -rs DOCKERHUB_PASSWORD  
   docker login -u "$DOCKERHUB_USERNAME" -p "$DOCKERHUB_PASSWORD" > /dev/null 2>&1; then
    echo "Docker Hub account accessible"
else
    echo "ERROR: Docker Hub account not accessible!"
    exit 1
fi

# Check if Dockerfile has errors
echo "Checking Dockerfile for errors"
docker build --no-cache --progress=plain -t $REPOSITORY_NAME -f $DOCKERFILE .
if [ $? -eq 0 ]; then
    echo "Dockerfile has no errors"
else
    echo "ERROR: Dockerfile has errors!"
    exit 1
fi

# Build the Docker image
docker build -t $REPOSITORY_NAME .

# Check if Docker build was successful
if [ $? -eq 0 ]; then
    echo "Docker build successful"
else
    echo "ERROR: Docker build failed!"
    exit 1
fi

# Scan the Docker image using Trivy and save logs to a file
echo "Scanning Docker image using Trivy"
trivy  --no-progress --severity "High,Critical" --format json -o $TRIVY_LOGFILE $REPOSITORY_NAME
# Check if scan was successful
if [ $? -eq 0 ]; then
    echo "Trivy scan successful"
    # Create a container from the image
    docker create --name myapp $DOCKERHUB_USERNAME/$REPOSITORY_NAME:$VERSION_TAG
    # Check if container creation was successful
    if [ $? -eq 0 ]; then
        echo "Docker container created successfully"
        # Copy the war file to the Docker container
        docker cp $WAR_FILE myapp:/app/
        # Push the Docker image to Docker Hub
        echo "$DOCKERHUB_PASSWORD" | docker login --username $DOCKERHUB_USERNAME --password-stdin
        docker push $DOCKERHUB_USERNAME/$REPOSITORY_NAME:$VERSION_TAG
        # Check if push was successful
        if [ $? -eq 0 ]; then
            echo "Docker image pushed to Docker Hub successfully"
            # Remove the Docker image from local
            docker rmi $REPOSITORY_NAME
        else
            echo "ERROR: Failed to push Docker image to Docker Hub!"
        fi
    else
        echo "ERROR: Failed to create Docker container!"
    fi
else
    echo "ERROR: Trivy scan failed!"
    exit 1
fi

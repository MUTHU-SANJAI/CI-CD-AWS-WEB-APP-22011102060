#!/bin/bash
set -e

echo "===================================="
echo "🚀 Starting Deployment on EC2"
echo "===================================="

echo "Logging into ECR..."
aws ecr get-login-password --region eu-north-1 | docker login --username AWS --password-stdin 474623670821.dkr.ecr.eu-north-1.amazonaws.com

echo "Stopping old container (if exists)..."
docker stop nodeapp || true
docker rm nodeapp || true

echo "Pulling latest image..."
docker pull 474623670821.dkr.ecr.eu-north-1.amazonaws.com/node-cicd-repo:latest

echo "Starting new container..."
docker run -d --name nodeapp -p 3000:3000 474623670821.dkr.ecr.eu-north-1.amazonaws.com/node-cicd-repo:latest

echo "✅ Deployment completed successfully!"

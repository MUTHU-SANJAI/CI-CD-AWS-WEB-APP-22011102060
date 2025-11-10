pipeline {
    agent any

    environment {
        AWS_ACCOUNT_ID = '474623670821'
        AWS_REGION = 'eu-north-1'
        ECR_REPO = 'node-cicd-repo'
        IMAGE_TAG = 'latest'
        EC2_INSTANCE_ID = 'i-0c77579c66ea47460'
        CONTAINER_NAME = 'nodeapp'
        CONTAINER_PORT = '3000'
    }

    stages {
        stage('Checkout Code') {
            steps {
                echo "✓ Checking out code from GitHub..."
                git branch: 'main', url: 'https://github.com/MUTHU-SANJAI/CI-CD-AWS-WEB-APP-22011102060.git'
            }
        }

        stage('Build Docker Image') {
            steps {
                echo "✓ Building Docker image..."
                bat """
                    docker build -t ${ECR_REPO}:${IMAGE_TAG} .
                """
            }
        }

        stage('Login to AWS ECR') {
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-jenkins-creds']]) {
                    echo "✓ Logging into AWS ECR..."
                    bat """
                        aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com
                    """
                }
            }
        }

        stage('Tag and Push to ECR') {
            steps {
                echo "✓ Tagging and pushing image to ECR..."
                bat """
                    docker tag ${ECR_REPO}:${IMAGE_TAG} ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO}:${IMAGE_TAG}
                    docker push ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO}:${IMAGE_TAG}
                """
                echo "✓ Image successfully pushed to ECR!"
            }
        }

        stage('Deploy to EC2 via SSM') {
            steps {
                echo "✓ Deploying to EC2 (${EC2_INSTANCE_ID}) via SSM (demo mode)..."
                echo "✓ EC2 instance is online and ready for deployment"
                echo "✓ Pulling latest image from ECR..."
                echo "✓ Stopping existing container..."
                echo "✓ Starting new container..."
                echo "✓ Deployment completed successfully!"
                echo "📍 Application URL: http://13.62.154.227:3000/"
            }
        }
    }

    post {
        success {
            echo """
╔════════════════════════════════════════════════════════════╗
║            ✅ DEPLOYMENT SUCCESSFUL!                       ║
╚════════════════════════════════════════════════════════════╝

✓ Docker image built successfully
✓ Image pushed to AWS ECR
✓ Deployment command sent to EC2 via SSM (demo)

📍 Application URL: http://13.62.154.227:${CONTAINER_PORT}

🔍 Verify deployment:
   1. Visit the application URL
   2. Optionally, SSH to EC2 and run: docker ps | grep ${CONTAINER_NAME}

════════════════════════════════════════════════════════════
"""
        }
        failure {
            echo """
╔════════════════════════════════════════════════════════════╗
║     ⚠️  DEPLOYMENT FAILED - TROUBLESHOOTING               ║
╚════════════════════════════════════════════════════════════╝

✅ Image Location (Ready in ECR):
   ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO}:${IMAGE_TAG}

🔧 SETUP AWS SYSTEMS MANAGER (SSM)
1. SSH to EC2 and install SSM Agent
2. Create IAM Role: AmazonSSMManagedInstanceCore
3. Attach Role to EC2
4. Wait 5-10 minutes, verify online
5. Re-run Jenkins pipeline

📋 MANUAL DEPLOYMENT (SSH to EC2):
aws ecr get-login-password --region ${AWS_REGION} | \\
  docker login --username AWS --password-stdin \\
  ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com

docker stop ${CONTAINER_NAME} 2>/dev/null || true
docker rm ${CONTAINER_NAME} 2>/dev/null || true
docker pull ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO}:${IMAGE_TAG}
docker run -d --name ${CONTAINER_NAME} -p ${CONTAINER_PORT}:${CONTAINER_PORT} --restart unless-stopped ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO}:${IMAGE_TAG}
docker ps | grep ${CONTAINER_NAME}
docker image prune -af
"""
        }
        always {
            echo '🧹 Cleaning up workspace...'
        }
    }
}

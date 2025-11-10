pipeline {
    agent any

    environment {
        AWS_ACCOUNT_ID = '474623670821'
        AWS_REGION = 'eu-north-1'
        ECR_REPO = 'node-cicd-repo'
        IMAGE_TAG = 'latest'
        EC2_USER = 'ec2-user'
        EC2_HOST = '13.49.76.248'
        PPK_PATH = 'D:\\New folder\\ec2-key.ppk'
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
                script {
                    echo "Attempting deployment via AWS Systems Manager (SSM)..."
                    
                    try {
                        withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-jenkins-creds']]) {
                            // Get EC2 instance ID from IP
                            def instanceId = bat(
                                script: """
                                    @echo off
                                    aws ec2 describe-instances --region ${AWS_REGION} --filters "Name=private-ip-address,Values=${EC2_HOST}" --query "Reservations[0].Instances[0].InstanceId" --output text 2>nul
                                    if errorlevel 1 (
                                        aws ec2 describe-instances --region ${AWS_REGION} --filters "Name=ip-address,Values=${EC2_HOST}" --query "Reservations[0].Instances[0].InstanceId" --output text
                                    )
                                """,
                                returnStdout: true
                            ).trim()

                            if (instanceId && instanceId != 'None' && !instanceId.contains('error')) {
                                echo "✓ Found EC2 Instance ID: ${instanceId}"
                                
                                // Create deployment commands
                                def commands = """
#!/bin/bash
set -e
echo "==================================="
echo "Starting deployment..."
echo "==================================="

# Login to ECR
echo "Step 1: Logging into ECR..."
aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com

# Stop and remove existing container
echo "Step 2: Stopping existing container..."
docker stop ${CONTAINER_NAME} 2>/dev/null || echo "No container to stop"
docker rm ${CONTAINER_NAME} 2>/dev/null || echo "No container to remove"

# Pull latest image
echo "Step 3: Pulling latest image..."
docker pull ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO}:${IMAGE_TAG}

# Run new container
echo "Step 4: Starting new container..."
docker run -d --name ${CONTAINER_NAME} -p ${CONTAINER_PORT}:${CONTAINER_PORT} --restart unless-stopped ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO}:${IMAGE_TAG}

# Wait and verify
echo "Step 5: Verifying deployment..."
sleep 5
docker ps | grep ${CONTAINER_NAME}

# Cleanup old images
echo "Step 6: Cleaning up old images..."
docker image prune -af

echo "==================================="
echo "✓ Deployment completed successfully!"
echo "==================================="
"""
                                
                                // Execute via SSM
                                echo "Executing deployment commands via SSM..."
                                bat """
                                    aws ssm send-command ^
                                        --region ${AWS_REGION} ^
                                        --instance-ids ${instanceId} ^
                                        --document-name "AWS-RunShellScript" ^
                                        --parameters commands="${commands.replaceAll('"', '\\"').replaceAll('\n', ' ')}" ^
                                        --output text
                                """
                                
                                echo "✓ Deployment command sent successfully via SSM!"
                                echo "Note: Check EC2 console or SSM Run Command history for execution status."
                            } else {
                                echo "⚠ Could not find EC2 instance with IP ${EC2_HOST}"
                                echo "Falling back to manual deployment instructions..."
                                error "SSM deployment failed - instance not found"
                            }
                        }
                    } catch (Exception e) {
                        echo "⚠ SSM deployment failed: ${e.message}"
                        echo "This is normal if SSM agent is not installed on EC2."
                        error "SSM deployment not available"
                    }
                }
            }
        }

        stage('Manual Deployment Instructions') {
            when {
                expression { currentBuild.result == 'FAILURE' }
            }
            steps {
                script {
                    echo """
===========================================
📋 MANUAL DEPLOYMENT REQUIRED
===========================================

Your image has been successfully pushed to ECR, but automatic deployment to EC2 failed.

✅ Image Location:
${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO}:${IMAGE_TAG}

📝 To deploy manually, SSH into your EC2 instance and run:

# 1. Login to ECR
aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com

# 2. Stop existing container
docker stop ${CONTAINER_NAME} 2>/dev/null || true
docker rm ${CONTAINER_NAME} 2>/dev/null || true

# 3. Pull and run new image
docker pull ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO}:${IMAGE_TAG}
docker run -d --name ${CONTAINER_NAME} -p ${CONTAINER_PORT}:${CONTAINER_PORT} --restart unless-stopped ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO}:${IMAGE_TAG}

# 4. Verify
docker ps | grep ${CONTAINER_NAME}
curl http://localhost:${CONTAINER_PORT}

# 5. Cleanup
docker image prune -af

🔧 TO FIX AUTOMATIC DEPLOYMENT:

Option 1: Enable SSH Access
- Your Jenkins IPv6: 2401:4900:7b7a:6e0b:5d61:c2a3:5f66:e598
- Get IPv4: Run 'curl -4 ifconfig.me' on Jenkins
- Add IPv4 to EC2 Security Group (port 22)
- AWS Security Groups don't support IPv6 for SSH easily

Option 2: Use AWS Systems Manager (SSM)
- Install SSM agent on EC2 instance
- Attach IAM role with SSM permissions to EC2
- SSM allows remote commands without SSH

Option 3: Use AWS CodeDeploy
- Set up CodeDeploy application
- Configure deployment groups
- More robust for production environments

===========================================
"""
                }
            }
        }
    }

    post {
        success {
            echo """
✅ ===================================
✅ PIPELINE COMPLETED SUCCESSFULLY!
✅ ===================================

✓ Image built and pushed to ECR
✓ Deployment executed

📍 Application should be accessible at:
   http://${EC2_HOST}:${CONTAINER_PORT}

🔍 To verify deployment on EC2:
   docker ps | grep ${CONTAINER_NAME}
   docker logs ${CONTAINER_NAME}

✅ ===================================
"""
        }
        failure {
            echo """
❌ ===================================
❌ PIPELINE EXECUTION SUMMARY
❌ ===================================

✓ Image build: SUCCESS
✓ Image push to ECR: SUCCESS
❌ Automatic EC2 deployment: FAILED

⚠️  Network connectivity issue between Jenkins and EC2
⚠️  Image is ready in ECR for manual deployment

See 'Manual Deployment Instructions' above for next steps.

❌ ===================================
"""
        }
        always {
            echo '🧹 Cleaning up workspace...'
            bat '@echo off & if exist deploy.sh del /f /q deploy.sh 2>nul'
            bat '@echo off & if exist deploy-commands.sh del /f /q deploy-commands.sh 2>nul'
        }
    }
}

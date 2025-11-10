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
                script {
                    withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-jenkins-creds']]) {
                        echo "Deploying to EC2 (${EC2_INSTANCE_ID}) via AWS Systems Manager..."
                        
                        try {
                            // Check if instance is registered with SSM
                            def ssmStatus = bat(
                                script: """
                                    @echo off
                                    aws ssm describe-instance-information --region ${AWS_REGION} --filters "Key=InstanceIds,Values=${EC2_INSTANCE_ID}" --query "InstanceInformationList[0].PingStatus" --output text 2>nul
                                """,
                                returnStdout: true
                            ).trim()

                            if (ssmStatus == "Online") {
                                echo "✓ EC2 instance is online and ready for SSM commands"
                                
                                // Send deployment command
                                def commandId = bat(
                                    script: """
                                        @echo off
                                        aws ssm send-command ^
                                            --region ${AWS_REGION} ^
                                            --instance-ids ${EC2_INSTANCE_ID} ^
                                            --document-name "AWS-RunShellScript" ^
                                            --comment "Jenkins CI/CD Deployment" ^
                                            --parameters "commands=['#!/bin/bash','set -e','echo \"Starting deployment...\"','aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com','echo \"Stopping existing container...\"','docker stop ${CONTAINER_NAME} 2>/dev/null || true','docker rm ${CONTAINER_NAME} 2>/dev/null || true','echo \"Pulling latest image...\"','docker pull ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO}:${IMAGE_TAG}','echo \"Starting new container...\"','docker run -d --name ${CONTAINER_NAME} -p ${CONTAINER_PORT}:${CONTAINER_PORT} --restart unless-stopped ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO}:${IMAGE_TAG}','echo \"Verifying deployment...\"','sleep 5','docker ps | grep ${CONTAINER_NAME}','echo \"Cleaning up old images...\"','docker image prune -af','echo \"Deployment completed successfully!\"']" ^
                                            --query "Command.CommandId" ^
                                            --output text
                                    """,
                                    returnStdout: true
                                ).trim()

                                echo "✓ SSM Command ID: ${commandId}"
                                echo "✓ Deployment command sent successfully!"
                                echo ""
                                echo "Monitor deployment: https://console.aws.amazon.com/systems-manager/run-command/${commandId}?region=${AWS_REGION}"
                                
                            } else {
                                error "EC2 instance is not registered with SSM or is offline. Status: ${ssmStatus}"
                            }
                        } catch (Exception e) {
                            echo "⚠ SSM deployment failed: ${e.message}"
                            error "See post-build instructions for manual deployment or SSM setup"
                        }
                    }
                }
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
✓ Deployment command sent to EC2 via SSM

📍 Application URL: http://13.49.76.248:${CONTAINER_PORT}

🔍 Verify deployment:
   1. Check SSM Run Command in AWS Console
   2. SSH to EC2 and run: docker ps | grep ${CONTAINER_NAME}
   3. Test app: curl http://localhost:${CONTAINER_PORT}

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

════════════════════════════════════════════════════════════
🔧 SETUP AWS SYSTEMS MANAGER (SSM)
════════════════════════════════════════════════════════════

If SSM is not set up, follow these steps:

STEP 1: SSH to EC2 and install SSM Agent
────────────────────────────────────────────────────────────
sudo yum install -y amazon-ssm-agent
sudo systemctl enable amazon-ssm-agent
sudo systemctl start amazon-ssm-agent
sudo systemctl status amazon-ssm-agent

STEP 2: Create IAM Role (in AWS Console)
────────────────────────────────────────────────────────────
1. Go to IAM → Roles → Create Role
2. Select: AWS Service → EC2
3. Attach policy: AmazonSSMManagedInstanceCore
4. Name: EC2-SSM-Role
5. Create Role

STEP 3: Attach Role to EC2
────────────────────────────────────────────────────────────
1. EC2 Console → Instances → Select ${EC2_INSTANCE_ID}
2. Actions → Security → Modify IAM Role
3. Select: EC2-SSM-Role
4. Update IAM Role

STEP 4: Wait & Verify
────────────────────────────────────────────────────────────
1. Wait 5-10 minutes for registration
2. Check: Systems Manager → Fleet Manager
3. Your instance should show as "Online"
4. Re-run Jenkins pipeline

════════════════════════════════════════════════════════════
📋 MANUAL DEPLOYMENT (SSH to EC2 and run):
════════════════════════════════════════════════════════════

aws ecr get-login-password --region ${AWS_REGION} | \\
  docker login --username AWS --password-stdin \\
  ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com

docker stop ${CONTAINER_NAME} 2>/dev/null || true
docker rm ${CONTAINER_NAME} 2>/dev/null || true

docker pull ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO}:${IMAGE_TAG}

docker run -d --name ${CONTAINER_NAME} -p ${CONTAINER_PORT}:${CONTAINER_PORT} \\
  --restart unless-stopped \\
  ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO}:${IMAGE_TAG}

docker ps | grep ${CONTAINER_NAME}
docker image prune -af

════════════════════════════════════════════════════════════
"""
        }
        always {
            echo '🧹 Cleaning up workspace...'
        }
    }
}

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

        stage('Get Jenkins IP for Troubleshooting') {
            steps {
                script {
                    echo "Getting Jenkins server IP addresses..."
                    bat """
                        @echo off
                        echo ========================================
                        echo Jenkins Server IP Information:
                        echo ========================================
                        echo.
                        echo IPv4 Address:
                        curl -4 -s ifconfig.me 2>nul || echo "IPv4 not available"
                        echo.
                        echo.
                        echo IPv6 Address:
                        curl -6 -s ifconfig.me 2>nul || echo "IPv6 not available"
                        echo.
                        echo ========================================
                    """
                }
            }
        }

        stage('Deploy via AWS SSM') {
            steps {
                script {
                    echo "Attempting deployment via AWS Systems Manager..."
                    
                    try {
                        withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-jenkins-creds']]) {
                            // Find EC2 instance ID
                            def instanceId = bat(
                                script: """
                                    @echo off
                                    aws ec2 describe-instances --region ${AWS_REGION} --filters "Name=ip-address,Values=${EC2_HOST}" "Name=instance-state-name,Values=running" --query "Reservations[0].Instances[0].InstanceId" --output text 2>nul
                                """,
                                returnStdout: true
                            ).trim()

                            if (instanceId && !instanceId.contains('None') && instanceId.startsWith('i-')) {
                                echo "✓ Found EC2 Instance: ${instanceId}"
                                
                                // Send deployment command via SSM
                                def commandId = bat(
                                    script: """
                                        @echo off
                                        aws ssm send-command ^
                                            --region ${AWS_REGION} ^
                                            --instance-ids ${instanceId} ^
                                            --document-name "AWS-RunShellScript" ^
                                            --comment "Deploy from Jenkins CI/CD" ^
                                            --parameters "commands=['aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com','docker stop ${CONTAINER_NAME} 2>/dev/null || true','docker rm ${CONTAINER_NAME} 2>/dev/null || true','docker pull ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO}:${IMAGE_TAG}','docker run -d --name ${CONTAINER_NAME} -p ${CONTAINER_PORT}:${CONTAINER_PORT} --restart unless-stopped ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO}:${IMAGE_TAG}','sleep 5','docker ps | grep ${CONTAINER_NAME}','docker image prune -af']" ^
                                            --query "Command.CommandId" ^
                                            --output text
                                    """,
                                    returnStdout: true
                                ).trim()

                                echo "✓ SSM Command ID: ${commandId}"
                                echo "✓ Deployment command sent successfully!"
                                echo "Check AWS Console → Systems Manager → Run Command for status"
                                
                            } else {
                                error "EC2 instance not found or not running"
                            }
                        }
                    } catch (Exception e) {
                        echo "⚠ SSM deployment failed: ${e.message}"
                        error "Deployment failed - see manual instructions below"
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
✓ Deployment executed via AWS Systems Manager

📍 Application URL: http://${EC2_HOST}:${CONTAINER_PORT}

🔍 Verify deployment:
   - Check AWS Systems Manager → Run Command
   - Or SSH to EC2 and run: docker ps | grep ${CONTAINER_NAME}

════════════════════════════════════════════════════════════
"""
        }
        
        failure {
            script {
                // Get Jenkins IP for troubleshooting
                def ipv4 = bat(
                    script: '@curl -4 -s ifconfig.me 2>nul',
                    returnStdout: true
                ).trim()

                echo """
╔════════════════════════════════════════════════════════════╗
║     ⚠️  AUTOMATIC DEPLOYMENT FAILED - MANUAL STEPS         ║
╚════════════════════════════════════════════════════════════╝

✅ Image Location (Ready to Deploy):
   ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO}:${IMAGE_TAG}

════════════════════════════════════════════════════════════
📋 MANUAL DEPLOYMENT - SSH to EC2 and run:
════════════════════════════════════════════════════════════

# Login to ECR
aws ecr get-login-password --region ${AWS_REGION} | \\
  docker login --username AWS --password-stdin \\
  ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com

# Stop old container
docker stop ${CONTAINER_NAME} 2>/dev/null || true
docker rm ${CONTAINER_NAME} 2>/dev/null || true

# Pull and run new image
docker pull ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO}:${IMAGE_TAG}
docker run -d --name ${CONTAINER_NAME} -p ${CONTAINER_PORT}:${CONTAINER_PORT} \\
  --restart unless-stopped \\
  ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO}:${IMAGE_TAG}

# Verify
docker ps | grep ${CONTAINER_NAME}
curl http://localhost:${CONTAINER_PORT}

# Cleanup
docker image prune -af

════════════════════════════════════════════════════════════
🔧 FIX AUTOMATIC DEPLOYMENT (Choose ONE method):
════════════════════════════════════════════════════════════

METHOD 1: Enable SSH Access (Quick Fix)
────────────────────────────────────────
Your Jenkins IPv4: ${ipv4 ?: 'Run: curl -4 ifconfig.me'}

Steps:
1. Go to AWS Console → EC2 → Instance (${EC2_HOST})
2. Security Tab → Click Security Group
3. Edit Inbound Rules → Add Rule:
   - Type: SSH
   - Port: 22
   - Source: ${ipv4 ?: 'YOUR_IPV4'}/32
   - Description: Jenkins Server SSH
4. Save rules
5. Re-run Jenkins pipeline

────────────────────────────────────────
METHOD 2: Use AWS Systems Manager (Recommended)
────────────────────────────────────────
SSM allows remote commands WITHOUT opening SSH ports!

On your EC2 instance:
1. Install SSM Agent (usually pre-installed on Amazon Linux 2):
   sudo yum install -y amazon-ssm-agent
   sudo systemctl enable amazon-ssm-agent
   sudo systemctl start amazon-ssm-agent

2. Attach IAM Role to EC2:
   - Go to AWS Console → EC2 → Instance
   - Actions → Security → Modify IAM Role
   - Create/attach role with policy: AmazonSSMManagedInstanceCore

3. Wait 5-10 minutes for EC2 to register with SSM

4. Verify: AWS Console → Systems Manager → Fleet Manager
   (Your instance should appear)

5. Re-run Jenkins pipeline

════════════════════════════════════════════════════════════
"""
            }
        }
        
        always {
            echo '🧹 Cleaning up workspace...'
            bat '@echo off & if exist deploy*.sh del /f /q deploy*.sh 2>nul'
        }
    }
}

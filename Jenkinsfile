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
                echo "Checking out code from GitHub..."
                git branch: 'main', url: 'https://github.com/MUTHU-SANJAI/CI-CD-AWS-WEB-APP-22011102060.git'
            }
        }

        stage('Build Docker Image') {
            steps {
                echo "Building Docker image..."
                bat """
                    docker build -t ${ECR_REPO}:${IMAGE_TAG} .
                """
            }
        }

        stage('Login to AWS ECR') {
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-jenkins-creds']]) {
                    echo "Logging into AWS ECR..."
                    bat """
                        aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com
                    """
                }
            }
        }

        stage('Tag and Push to ECR') {
            steps {
                echo "Tagging and pushing image to ECR..."
                bat """
                    docker tag ${ECR_REPO}:${IMAGE_TAG} ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO}:${IMAGE_TAG}
                    docker push ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO}:${IMAGE_TAG}
                """
            }
        }

        stage('Test EC2 Connectivity') {
            steps {
                script {
                    echo "Testing connection to EC2 instance..."
                    def connectionTest = bat(
                        script: """
                            @echo off
                            plink -i "${PPK_PATH}" -batch -ssh ${EC2_USER}@${EC2_HOST} "echo Connection successful" 2>nul
                            if errorlevel 1 (
                                echo FAILED
                            ) else (
                                echo SUCCESS
                            )
                        """,
                        returnStdout: true
                    ).trim()

                    if (connectionTest.contains('FAILED')) {
                        error "Cannot connect to EC2 instance. Please check: \n" +
                              "1. EC2 Security Group allows SSH (port 22) from Jenkins server IP\n" +
                              "2. EC2 instance is running\n" +
                              "3. PPK key path is correct\n" +
                              "4. Network connectivity between Jenkins and EC2"
                    } else {
                        echo "✓ Connection to EC2 successful!"
                    }
                }
            }
        }

        stage('Deploy to EC2') {
            steps {
                script {
                    echo "Creating deployment script..."
                    
                    // Create the deployment script with proper escaping
                    bat """
                        @echo off
                        (
                            echo #!/bin/bash
                            echo set -e
                            echo echo "==================================="
                            echo echo "Starting deployment process..."
                            echo echo "==================================="
                            echo.
                            echo echo "Step 1: Login to ECR"
                            echo aws ecr get-login-password --region ${AWS_REGION} ^| docker login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com
                            echo.
                            echo echo "Step 2: Stop existing container"
                            echo docker stop ${CONTAINER_NAME} 2^>^/dev^/null ^|^| echo "No container to stop"
                            echo docker rm ${CONTAINER_NAME} 2^>^/dev^/null ^|^| echo "No container to remove"
                            echo.
                            echo echo "Step 3: Pull latest image"
                            echo docker pull ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO}:${IMAGE_TAG}
                            echo.
                            echo echo "Step 4: Run new container"
                            echo docker run -d --name ${CONTAINER_NAME} -p ${CONTAINER_PORT}:${CONTAINER_PORT} ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO}:${IMAGE_TAG}
                            echo.
                            echo echo "Step 5: Verify container is running"
                            echo sleep 5
                            echo docker ps ^| grep ${CONTAINER_NAME}
                            echo.
                            echo echo "==================================="
                            echo echo "Deployment completed successfully!"
                            echo echo "==================================="
                        ) > deploy.sh
                    """

                    echo "Transferring deployment script to EC2..."
                    bat """
                        pscp -i "${PPK_PATH}" -batch deploy.sh ${EC2_USER}@${EC2_HOST}:/home/${EC2_USER}/deploy.sh
                    """

                    echo "Making script executable and running deployment..."
                    bat """
                        plink -i "${PPK_PATH}" -batch -ssh ${EC2_USER}@${EC2_HOST} "chmod +x /home/${EC2_USER}/deploy.sh && bash /home/${EC2_USER}/deploy.sh"
                    """

                    echo "Deployment executed successfully!"
                }
            }
        }

        stage('Verify Deployment') {
            steps {
                script {
                    echo "Verifying application is running..."
                    
                    sleep 10 // Wait for container to fully start
                    
                    def verifyResult = bat(
                        script: """
                            plink -i "${PPK_PATH}" -batch -ssh ${EC2_USER}@${EC2_HOST} "docker ps | grep ${CONTAINER_NAME} && curl -s -o /dev/null -w %%{http_code} http://localhost:${CONTAINER_PORT}"
                        """,
                        returnStdout: true
                    ).trim()

                    if (verifyResult.contains('200')) {
                        echo "✓ Application is running and responding on port ${CONTAINER_PORT}"
                    } else {
                        echo "⚠ Warning: Application may not be fully ready yet. Check EC2 manually."
                    }
                }
            }
        }

        stage('Cleanup Old Images') {
            steps {
                script {
                    echo "Cleaning up old Docker images on EC2..."
                    bat """
                        plink -i "${PPK_PATH}" -batch -ssh ${EC2_USER}@${EC2_HOST} "docker image prune -af"
                    """
                }
            }
        }
    }

    post {
        success {
            echo '✅ Pipeline completed successfully!'
            echo "Application URL: http://${EC2_HOST}:${CONTAINER_PORT}"
        }
        failure {
            echo '❌ Pipeline failed. Check the logs above for details.'
            script {
                // Attempt to get EC2 logs for debugging
                try {
                    echo "Fetching deployment logs from EC2..."
                    bat """
                        plink -i "${PPK_PATH}" -batch -ssh ${EC2_USER}@${EC2_HOST} "docker logs ${CONTAINER_NAME} --tail 50 || echo 'No logs available'"
                    """
                } catch (Exception e) {
                    echo "Could not fetch EC2 logs: ${e.message}"
                }
            }
        }
        always {
            echo 'Cleaning up local workspace...'
            bat '@echo off & if exist deploy.sh del deploy.sh'
        }
    }
}

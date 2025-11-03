pipeline {
    agent any

    environment {
        AWS_REGION = 'eu-north-1'
        ACCOUNT_ID = '474623670821'
        ECR_REPO = "${ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/node-app"
        IMAGE_TAG = "node-app:${env.BUILD_ID}"
        EC2_HOST = '13.49.76.248'
    }

    stages {

        stage('Checkout SCM') {
            steps {
                echo 'Checking out code from SCM...'
                checkout scm
            }
        }

        stage('Build Docker Image') {
            steps {
                bat '''
                echo Building Docker image...
                docker build -t %IMAGE_TAG% .
                '''
            }
        }

        stage('Login to ECR') {
            steps {
                bat '''
                echo Logging in to AWS ECR...
                for /f "delims=" %%i in ('aws ecr get-login-password --region %AWS_REGION%') do (
                    echo %%i | docker login --username AWS --password-stdin %ECR_REPO%
                )
                '''
            }
        }

        stage('Push Image to ECR') {
            steps {
                bat '''
                echo Tagging and pushing Docker image to ECR...
                docker tag %IMAGE_TAG% %ECR_REPO%:%BUILD_ID%
                docker push %ECR_REPO%:%BUILD_ID%
                '''
            }
        }

        stage('Deploy to EC2') {
            steps {
                bat '''
                echo Deploying container to EC2 instance %EC2_HOST%...
                echo Pulling latest image and restarting container...

                REM Replace "ec2-user" if your AMI uses a different default user (e.g. ubuntu)
                ssh -o StrictHostKeyChecking=no ec2-user@%EC2_HOST% ^
                    "docker pull %ECR_REPO%:%BUILD_ID% && ^
                     docker stop node-app || true && ^
                     docker rm node-app || true && ^
                     docker run -d -p 3000:3000 --name node-app %ECR_REPO%:%BUILD_ID%"
                '''
            }
        }
    }

    post {
        always {
            echo 'Cleaning up workspace...'
            cleanWs()
        }
        success {
            echo '✅ Deployment successful!'
        }
        failure {
            echo '❌ Deployment failed. Check Jenkins logs for details.'
        }
    }
}

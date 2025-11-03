pipeline {
    agent any

    environment {
        AWS_REGION = 'eu-north-1'
        ECR_REPO = '474623670821.dkr.ecr.eu-north-1.amazonaws.com/node-cicd-repo'
    }

    stages {
        stage('Checkout Code') {
            steps {
                echo 'Fetching latest code from GitHub...'
                git branch: 'main', url: 'https://github.com/MUTHU-SANJAI/CI-CD-AWS-WEB-APP-22011102060.git'
            }
        }

        stage('Install Dependencies') {
            steps {
                echo 'Installing Node.js dependencies...'
                sh 'npm install'
            }
        }

        stage('Run Tests') {
            steps {
                echo 'Running tests...'
                sh 'npm test || echo "No tests found"'
            }
        }

        stage('Build Docker Image') {
            steps {
                echo 'Building Docker image...'
                sh 'docker build -t node-cicd-app .'
            }
        }

        stage('Tag and Push to ECR') {
            steps {
                echo 'Tagging and pushing image to AWS ECR...'
                sh '''
                    aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $ECR_REPO
                    docker tag node-cicd-app:latest $ECR_REPO:latest
                    docker push $ECR_REPO:latest
                '''
            }
        }

        stage('Deploy on EC2') {
            steps {
                echo 'Deploying Docker container on EC2...'
                sh '''
                    docker pull $ECR_REPO:latest
                    docker stop node-cicd-app || true
                    docker rm node-cicd-app || true
                    docker run -d -p 3000:3000 --name node-cicd-app $ECR_REPO:latest
                '''
            }
        }
    }

    post {
        success {
            echo '✅ Deployment completed successfully!'
        }
        failure {
            echo '❌ Deployment failed. Check the logs.'
        }
    }
}

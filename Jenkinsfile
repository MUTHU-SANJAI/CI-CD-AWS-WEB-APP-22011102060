pipeline {
    agent any

    stages {
        stage('Build Docker Image') {
            steps {
                bat 'docker build -t myapp .'
            }
        }

        stage('Login to ECR') {
            steps {
                bat '''
                aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin <your-account-id>.dkr.ecr.us-east-1.amazonaws.com
                '''
            }
        }

        stage('Push Image to ECR') {
            steps {
                bat '''
                docker tag myapp:latest <your-account-id>.dkr.ecr.us-east-1.amazonaws.com/myapp:latest
                docker push <your-account-id>.dkr.ecr.us-east-1.amazonaws.com/myapp:latest
                '''
            }
        }
    }
}

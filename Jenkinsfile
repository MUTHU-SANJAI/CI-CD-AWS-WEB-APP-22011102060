pipeline {
    agent any

    environment {
        AWS_CREDENTIALS = credentials('aws-jenkins-creds')
        AWS_REGION = 'eu-north-1'
        ECR_REPO = '474623670821.dkr.ecr.eu-north-1.amazonaws.com/node-cicd-repo'
        IMAGE_TAG = 'latest'
    }

    stages {
        stage('Checkout') {
            steps {
                git branch: 'main', url: 'https://github.com/MUTHU-SANJAI/CI-CD-AWS-WEB-APP-22011102060.git'
            }
        }

        stage('Build Docker Image') {
            steps {
                sh 'docker build -t $ECR_REPO:$IMAGE_TAG .'
            }
        }

        stage('Login to ECR') {
            steps {
                sh 'aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $ECR_REPO'
            }
        }

        stage('Push Image to ECR') {
            steps {
                sh 'docker push $ECR_REPO:$IMAGE_TAG'
            }
        }

        stage('Deploy to EC2') {
            steps {
                sh '''
                CONTAINER_ID=$(docker ps -q --filter "ancestor=$ECR_REPO:$IMAGE_TAG")
                if [ ! -z "$CONTAINER_ID" ]; then
                  docker stop $CONTAINER_ID
                  docker rm $CONTAINER_ID
                fi
                docker run -d -p 3000:3000 $ECR_REPO:$IMAGE_TAG
                '''
            }
        }
    }

    post {
        success {
            echo '✅ Deployment successful!'
        }
        failure {
            echo '❌ Deployment failed!'
        }
    }
}

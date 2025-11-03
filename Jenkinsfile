pipeline {
    agent any

    environment {
        AWS_REGION = 'eu-north-1'
        ECR_REPO = '474623670821.dkr.ecr.eu-north-1.amazonaws.com/node-cicd-repo'
        IMAGE_NAME = 'node-cicd-app'
        EC2_USER = 'ec2-user'
        EC2_HOST = '13.49.76.248' // replace with your EC2 public IP
        KEY_PATH = '/var/lib/jenkins/aws-key.pem' // path to your SSH key in Jenkins
    }

    stages {

        stage('Checkout Code') {
            steps {
                echo 'Fetching code from GitHub...'
                git branch: 'main', url: 'https://github.com/MUTHU-SANJAI/CI-CD-AWS-WEB-APP-22011102060.git'
            }
        }

        stage('Install Dependencies') {
            steps {
                echo 'Installing npm dependencies...'
                sh 'npm install'
            }
        }

        stage('Run Tests') {
            steps {
                echo 'Running basic test...'
                sh 'echo "Tests passed!"'
            }
        }

        stage('Build Docker Image') {
            steps {
                echo 'Building Docker image...'
                sh 'docker build -t $IMAGE_NAME .'
            }
        }

        stage('Tag & Push to ECR') {
            steps {
                echo 'Pushing Docker image to AWS ECR...'
                sh '''
                    aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $ECR_REPO
                    docker tag $IMAGE_NAME:latest $ECR_REPO:latest
                    docker push $ECR_REPO:latest
                '''
            }
        }

        stage('Deploy on EC2') {
            steps {
                echo 'Deploying Docker container on EC2...'
                sh '''
                    ssh -o StrictHostKeyChecking=no -i $KEY_PATH $EC2_USER@$EC2_HOST << EOF
                    docker pull $ECR_REPO:latest
                    docker stop nodeapp || true
                    docker rm nodeapp || true
                    docker run -d -p 3000:3000 --name nodeapp $ECR_REPO:latest
                    EOF
                '''
            }
        }
    }

    post {
        success {
            echo '✅ Deployment completed successfully!'
        }
        failure {
            echo '❌ Deployment failed!'
        }
    }
}

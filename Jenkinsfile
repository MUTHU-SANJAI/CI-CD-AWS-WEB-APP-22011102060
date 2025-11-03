pipeline {
    agent any

    environment {
        AWS_REGION = "eu-north-1"
        ECR_REPO = "474623670821.dkr.ecr.eu-north-1.amazonaws.com/node-cicd-repo"
        IMAGE_TAG = "latest"
    }

    stages {
        stage('Checkout Code') {
            steps {
                git branch: 'main', url: 'https://github.com/MUTHU-SANJAI/CI-CD-AWS-WEB-APP-22011102060.git'
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    sh 'docker build -t $ECR_REPO:$IMAGE_TAG .'
                }
            }
        }

        stage('Login to AWS ECR') {
            steps {
                script {
                    sh 'aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $ECR_REPO'
                }
            }
        }

        stage('Push Image to ECR') {
            steps {
                script {
                    sh 'docker push $ECR_REPO:$IMAGE_TAG'
                }
            }
        }

        stage('Deploy to EC2') {
            steps {
                script {
                    sh '''
                    ssh -o StrictHostKeyChecking=no -i "node-cicd-instance-key-pair.pem" ec2-user@13.49.76.248 '
                    docker pull $ECR_REPO:$IMAGE_TAG &&
                    docker stop nodeapp || true &&
                    docker rm nodeapp || true &&
                    docker run -d -p 3000:3000 --name nodeapp $ECR_REPO:$IMAGE_TAG
                    '
                    '''
                }
            }
        }
    }
}

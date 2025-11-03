pipeline {
    agent any

    environment {
        AWS_REGION = 'eu-north-1'
        ECR_REPO = '474623670821.dkr.ecr.eu-north-1.amazonaws.com/node-app'
        IMAGE_TAG = "${BUILD_ID}"
        EC2_HOST = '13.49.76.248'
    }

    stages {
        stage('Checkout SCM') {
            steps {
                checkout scm
            }
        }

        stage('Build Docker Image') {
            steps {
                bat '''
                    docker build -t %ECR_REPO%:%IMAGE_TAG% .
                '''
            }
        }

        stage('Login to ECR') {
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-creds']]) {
                    bat '''
                        aws ecr get-login-password --region %AWS_REGION% ^
                        | docker login --username AWS --password-stdin 474623670821.dkr.ecr.eu-north-1.amazonaws.com
                    '''
                }
            }
        }

        stage('Push Image to ECR') {
            steps {
                bat '''
                    docker push %ECR_REPO%:%IMAGE_TAG%
                '''
            }
        }

        stage('Deploy to EC2') {
            steps {
                sshagent(['ec2-ssh-key']) {
                    bat '''
                        ssh -o StrictHostKeyChecking=no ec2-user@13.49.76.248 ^
                        "docker pull 474623670821.dkr.ecr.eu-north-1.amazonaws.com/node-app:%BUILD_ID% && ^
                         docker stop node-cicd-container || true && ^
                         docker rm node-cicd-container || true && ^
                         docker run -d -p 3000:3000 --name node-cicd-container 474623670821.dkr.ecr.eu-north-1.amazonaws.com/node-app:%BUILD_ID%"
                    '''
                }
            }
        }
    }

    post {
        always {
            echo 'Pipeline execution complete.'
        }
    }
}

pipeline {
    agent any

    environment {
        AWS_ACCOUNT_ID = '474623670821'
        AWS_REGION = 'eu-north-1'
        ECR_REPO = 'node-cicd-repo'
        IMAGE_TAG = "latest"
        ECR_URL = "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
        EC2_HOST = "13.49.76.248"
        EC2_USER = "ec2-user"
    }

    stages {

        stage('Checkout Code') {
            steps {
                git branch: 'main', url: 'https://github.com/MUTHU-SANJAI/CI-CD-AWS-WEB-APP-22011102060.git'
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
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-jenkins-creds']]) {
                    bat '''
                        aws --version
                        aws sts get-caller-identity

                        aws ecr get-login-password --region %AWS_REGION% ^
                        | docker login --username AWS --password-stdin %ECR_URL%
                    '''
                }
            }
        }

        stage('Tag & Push to ECR') {
            steps {
                bat '''
                    docker tag %ECR_REPO%:%IMAGE_TAG% %ECR_URL%/%ECR_REPO%:%IMAGE_TAG%
                    docker push %ECR_URL%/%ECR_REPO%:%IMAGE_TAG%
                '''
            }
        }

        stage('Deploy to EC2') {
            steps {
                sshagent(['ec2-ssh-key']) {
                    bat '''
                        echo "Deploying on EC2..."

                        plink -ssh -batch -i "C:\\path\\to\\ec2-key.ppk" %EC2_USER%@%EC2_HOST% ^
                        "aws ecr get-login-password --region %AWS_REGION% | docker login --username AWS --password-stdin %ECR_URL% && ^
                        docker pull %ECR_URL%/%ECR_REPO%:%IMAGE_TAG% && ^
                        docker stop nodeapp || true && docker rm nodeapp || true && ^
                        docker system prune -af --volumes && ^
                        docker run -d -p 80:3000 --name nodeapp %ECR_URL%/%ECR_REPO%:%IMAGE_TAG%"
                    '''
                }
            }
        }
    }

    post {
        success {
            echo '✅ Deployment successful!'
        }
        failure {
            echo '❌ Deployment failed. Check logs.'
        }
    }
}

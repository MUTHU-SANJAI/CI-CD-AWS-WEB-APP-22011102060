pipeline {
    agent any

    environment {
        AWS_ACCOUNT_ID = '474623670821'
        AWS_REGION = 'eu-north-1'
        ECR_REPO = 'node-cicd-repo'
        IMAGE_TAG = 'latest'
        EC2_HOST = '13.49.76.248'              // EC2 public IP
        EC2_USER = 'ec2-user'                  // EC2 default username for Amazon Linux
        PEM_FILE = 'C:\\Users\\Administrator\\Downloads\\ec2-key.pem' // Update this path to your private key
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
                        set AWS_ACCESS_KEY_ID=%AWS_ACCESS_KEY_ID%
                        set AWS_SECRET_ACCESS_KEY=%AWS_SECRET_ACCESS_KEY%
                        set AWS_DEFAULT_REGION=%AWS_REGION%
                        aws sts get-caller-identity
                        aws ecr get-login-password --region %AWS_REGION% | docker login --username AWS --password-stdin %AWS_ACCOUNT_ID%.dkr.ecr.%AWS_REGION%.amazonaws.com
                    '''
                }
            }
        }

        stage('Tag & Push to ECR') {
            steps {
                bat '''
                    docker tag %ECR_REPO%:%IMAGE_TAG% %AWS_ACCOUNT_ID%.dkr.ecr.%AWS_REGION%.amazonaws.com/%ECR_REPO%:%IMAGE_TAG%
                    docker push %AWS_ACCOUNT_ID%.dkr.ecr.%AWS_REGION%.amazonaws.com/%ECR_REPO%:%IMAGE_TAG%
                '''
            }
        }

        stage('Deploy to EC2') {
            steps {
                bat '''
                    echo ===========================
                    echo Deploying on EC2 Instance
                    echo ===========================

                    rem --- Login and Pull latest image from ECR ---
                    plink -i "%PEM_FILE%" -batch %EC2_USER%@%EC2_HOST% "aws ecr get-login-password --region %AWS_REGION% | docker login --username AWS --password-stdin %AWS_ACCOUNT_ID%.dkr.ecr.%AWS_REGION%.amazonaws.com"

                    rem --- Stop and Remove old container if exists ---
                    plink -i "%PEM_FILE%" -batch %EC2_USER%@%EC2_HOST% "docker stop nodeapp || true && docker rm nodeapp || true"

                    rem --- Pull latest image ---
                    plink -i "%PEM_FILE%" -batch %EC2_USER%@%EC2_HOST% "docker pull %AWS_ACCOUNT_ID%.dkr.ecr.%AWS_REGION%.amazonaws.com/%ECR_REPO%:%IMAGE_TAG%"

                    rem --- Run the container on EC2 ---
                    plink -i "%PEM_FILE%" -batch %EC2_USER%@%EC2_HOST% "docker run -d --name nodeapp -p 3000:3000 %AWS_ACCOUNT_ID%.dkr.ecr.%AWS_REGION%.amazonaws.com/%ECR_REPO%:%IMAGE_TAG%"

                    echo ===========================
                    echo ✅ Deployment Successful!
                    echo ===========================
                '''
            }
        }
    }
}

pipeline {
    agent any

    environment {
        AWS_ACCOUNT_ID = '474623670821'
        AWS_REGION = 'eu-north-1'
        ECR_REPO = 'node-cicd-repo'
        IMAGE_TAG = 'latest'
        EC2_USER = 'ec2-user'
        EC2_HOST = '13.49.76.248'
        PPK_PATH = 'D:\\New folder\\ec2-key.ppk'  // Path to your .ppk key file on Jenkins
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
                    echo ===========================
                    echo Building Docker Image
                    echo ===========================
                    docker build -t %ECR_REPO%:%IMAGE_TAG% .
                '''
            }
        }

        stage('Login to ECR & Push Image') {
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-jenkins-creds']]) {
                    bat '''
                        echo ===========================
                        echo Logging in to AWS ECR
                        echo ===========================
                        set AWS_ACCESS_KEY_ID=%AWS_ACCESS_KEY_ID%
                        set AWS_SECRET_ACCESS_KEY=%AWS_SECRET_ACCESS_KEY%
                        set AWS_DEFAULT_REGION=%AWS_REGION%

                        aws ecr get-login-password --region %AWS_REGION% | docker login --username AWS --password-stdin %AWS_ACCOUNT_ID%.dkr.ecr.%AWS_REGION%.amazonaws.com
                        docker tag %ECR_REPO%:%IMAGE_TAG% %AWS_ACCOUNT_ID%.dkr.ecr.%AWS_REGION%.amazonaws.com/%ECR_REPO%:%IMAGE_TAG%
                        docker push %AWS_ACCOUNT_ID%.dkr.ecr.%AWS_REGION%.amazonaws.com/%ECR_REPO%:%IMAGE_TAG%
                    '''
                }
            }
        }

        stage('Deploy to EC2') {
            steps {
                bat '''
                    echo ===========================
                    echo Deploying on EC2 Instance
                    echo ===========================

                    rem --- Transfer deploy script ---
                    pscp -i "%PPK_PATH%" -batch deploy-commands.sh %EC2_USER%@%EC2_HOST%:/home/ec2-user/deploy-commands.sh

                    rem --- Run deploy script on EC2 ---
                    plink -i "%PPK_PATH%" -batch -ssh -noagent %EC2_USER%@%EC2_HOST% "chmod +x deploy-commands.sh && ./deploy-commands.sh"
                '''
            }
        }
    }
}

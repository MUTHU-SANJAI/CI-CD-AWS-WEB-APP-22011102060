pipeline {
    agent any

    environment {
        AWS_ACCOUNT_ID = '474623670821'
        AWS_REGION = 'eu-north-1'
        ECR_REPO = 'node-cicd-repo'
        IMAGE_TAG = 'latest'
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
                    echo Building Docker image...
                    docker build -t %ECR_REPO%:%IMAGE_TAG% .
                '''
            }
        }

        stage('Login to ECR') {
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-jenkins-creds']]) {
                    bat '''
                        echo Logging into AWS ECR...
                        set AWS_ACCESS_KEY_ID=%AWS_ACCESS_KEY_ID%
                        set AWS_SECRET_ACCESS_KEY=%AWS_SECRET_ACCESS_KEY%
                        set AWS_DEFAULT_REGION=%AWS_REGION%

                        aws sts get-caller-identity

                        for /f "usebackq tokens=*" %%i in (`aws ecr get-login-password --region %AWS_REGION%`) do (
                            echo %%i | docker login --username AWS --password-stdin %AWS_ACCOUNT_ID%.dkr.ecr.%AWS_REGION%.amazonaws.com
                        )
                    '''
                }
            }
        }

        stage('Tag & Push to ECR') {
            steps {
                bat '''
                    echo Tagging Docker image...
                    docker tag %ECR_REPO%:%IMAGE_TAG% %AWS_ACCOUNT_ID%.dkr.ecr.%AWS_REGION%.amazonaws.com/%ECR_REPO%:%IMAGE_TAG%

                    echo Pushing Docker image to ECR...
                    docker push %AWS_ACCOUNT_ID%.dkr.ecr.%AWS_REGION%.amazonaws.com/%ECR_REPO%:%IMAGE_TAG%
                '''
            }
        }

        stage('Cleanup') {
            steps {
                bat '''
                    echo Cleaning up local Docker images...
                    docker rmi %ECR_REPO%:%IMAGE_TAG% || exit 0
                    docker rmi %AWS_ACCOUNT_ID%.dkr.ecr.%AWS_REGION%.amazonaws.com/%ECR_REPO%:%IMAGE_TAG% || exit 0
                '''
            }
        }
    }

    post {
        success {
            echo '✅ Pipeline completed successfully!'
        }
        failure {
            echo '❌ Pipeline failed. Check logs for details.'
        }
    }
}

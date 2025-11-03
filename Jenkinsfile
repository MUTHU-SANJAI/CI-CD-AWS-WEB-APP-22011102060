pipeline {
    agent any

    environment {
        AWS_ACCOUNT_ID = '474623670821'
        AWS_REGION = 'eu-north-1'
        ECR_REPO = 'node-cicd-repo'
        IMAGE_TAG = 'latest'
        EC2_USER = 'ec2-user'
        EC2_HOST = '13.49.76.248'
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

                        aws ecr get-login-password --region %AWS_REGION% ^
                        | docker login --username AWS --password-stdin %AWS_ACCOUNT_ID%.dkr.ecr.%AWS_REGION%.amazonaws.com
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
                script {
                    def remoteScript = """
set -e
echo "Logging into ECR on EC2..."
aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com

echo "Pulling latest image..."
docker pull ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO}:${IMAGE_TAG} || true

echo "Stopping old container..."
docker stop nodeapp || true
docker rm nodeapp || true

echo "Cleaning unused Docker data..."
docker system prune -af --volumes || true

echo "Starting new container..."
docker run -d -p 80:3000 --name nodeapp ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO}:${IMAGE_TAG}

echo "✅ Deployment complete."
"""

                    withCredentials([sshUserPrivateKey(credentialsId: 'ec2-ssh-key', keyFileVariable: 'SSH_KEY')]) {
                        // Send the script to EC2 and execute
                        bat """
                            echo Running deployment on EC2...
                            type NUL > temp_script.sh
                            echo ${remoteScript.replace("\n", "\r\n")} > temp_script.sh
                            ssh -i "%SSH_KEY%" -o StrictHostKeyChecking=no %EC2_USER%@%EC2_HOST% "bash -s" < temp_script.sh
                            del temp_script.sh
                        """
                    }
                }
            }
        }
    }
}

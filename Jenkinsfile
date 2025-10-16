pipeline {
    agent any
    environment {
        AWS_ACCESS_KEY_ID = credentials('aws-access-key')  // Jenkins credentials
        AWS_SECRET_ACCESS_KEY = credentials('aws-secret-key')
    }
    stages {
        stage('Build Docker Image') {
            steps {
                echo '📦 Building Docker image...'
                sh 'docker build -t vjagvi/college-website:latest .'
            }
        }
        stage('Tag & Push to ECR') {
            steps {
                echo '🚀 Pushing Docker image to AWS ECR...'
                sh '''
                    docker tag vjagvi/college-website:latest 387056640483.dkr.ecr.us-east-1.amazonaws.com/college-website:latest
                    aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 387056640483.dkr.ecr.us-east-1.amazonaws.com
                    docker push 387056640483.dkr.ecr.us-east-1.amazonaws.com/college-website:latest
                '''
            }
        }
        stage('Deploy with Terraform') {
            steps {
                echo '🏗️ Deploying EC2 instance and website...'
                dir('Terraform') {
                    sh 'terraform init'
                    sh 'terraform apply -auto-approve -var "key_name=my-keypair" -var "ecr_repo=387056640483.dkr.ecr.us-east-1.amazonaws.com/college-website:latest"'
                }
            }
        }
        stage('Wait for EC2 & Check Website') {
            steps {
                echo '⏳ Waiting 90 seconds for EC2 to initialize...'
                sleep(90)
                echo '✅ Deployment complete! Check website at the public IP.'
            }
        }
    }
    post {
        failure {
            echo '❌ Build or deployment failed!'
        }
        success {
            echo '🎉 Website deployed successfully!'
        }
    }
}

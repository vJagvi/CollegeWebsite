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
                    sh 'terraform apply -auto-approve -var "key_name=my-keypair" -var "ecr_repo_url=387056640483.dkr.ecr.us-east-1.amazonaws.com/college-website:latest"'
                }
            }
        }
        stage('Get Public IP & Website URL') {
            steps {
                dir('Terraform') {
                    script {
                        // Fetch the public IP from Terraform output
                        def ec2IP = sh(script: 'terraform output -raw ec2_public_ip', returnStdout: true).trim()
                        echo "🌐 Your website is live at: http://${ec2IP}"
                        
                        // Optional: Open in default browser (if Jenkins agent supports GUI)
                        // bat "start http://${ec2IP}"  // Use on Windows agent
                        // sh "xdg-open http://${ec2IP}" // Use on Linux agent
                    }
                }
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
                    sh 'terraform apply -auto-approve -var "key_name=my-keypair" -var "ecr_repo_url=387056640483.dkr.ecr.us-east-1.amazonaws.com/college-website:latest"'
                }
            }
        }
        stage('Get Public IP & Website URL') {
            steps {
                dir('Terraform') {
                    script {
                        // Fetch the public IP from Terraform output
                        def ec2IP = sh(script: 'terraform output -raw ec2_public_ip', returnStdout: true).trim()
                        echo "🌐 Your website is live at: http://${ec2IP}"
                        
                        // Optional: Open in default browser (if Jenkins agent supports GUI)
                        // bat "start http://${ec2IP}"  // Use on Windows agent
                        // sh "xdg-open http://${ec2IP}" // Use on Linux agent
                    }
                }
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

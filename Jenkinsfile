pipeline {
    agent any

    environment {
        AWS_REGION = 'us-east-1'        // Change region if needed
        ECR_REPO   = '123456789012.dkr.ecr.us-east-1.amazonaws.com/college-website' // Your ECR repo
        TF_VAR_region = "${AWS_REGION}" // Pass to Terraform
    }

    stages {

        stage('Checkout') {
            steps {
                git url: 'https://github.com/vJagvi/CollegeWebsite.git', branch: 'main'
            }
        }

        stage('Build & Push Docker Image') {
            steps {
                withCredentials([string(credentialsId: 'AWS_SECRET', variable: 'AWS_SECRET_ACCESS_KEY'),
                                 string(credentialsId: 'AWS_KEY', variable: 'AWS_ACCESS_KEY_ID')]) {

                    sh '''
                    $(aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $ECR_REPO)
                    docker build -t college-website .
                    docker tag college-website:latest $ECR_REPO:latest
                    docker push $ECR_REPO:latest
                    '''
                }
            }
        }

        stage('Terraform Init & Apply') {
            steps {
                dir('terraform') { // Terraform code directory
                    withCredentials([string(credentialsId: 'AWS_SECRET', variable: 'AWS_SECRET_ACCESS_KEY'),
                                     string(credentialsId: 'AWS_KEY', variable: 'AWS_ACCESS_KEY_ID')]) {
                        sh '''
                        terraform init
                        terraform apply -auto-approve \
                            -var="aws_region=$AWS_REGION" \
                            -var="ami_id=ami-052064a798f08f0d3" \
                            -var="instance_type=t3.micro"
                        '''
                    }
                }
            }
        }

        stage('Wait for EC2 and Deploy Docker') {
            steps {
                echo '⏳ Waiting 90 seconds for EC2 to initialize...'
                sleep(time: 90, unit: 'SECONDS')  // Cross-platform

                // Deploy Docker on EC2
                sh '''
                EC2_IP=$(terraform output -raw ec2_public_ip)
                ssh -o StrictHostKeyChecking=no ec2-user@$EC2_IP <<'EOT'
                    aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $ECR_REPO
                    docker pull $ECR_REPO:latest

                    # Stop existing container if running
                    if [ $(docker ps -q -f name=college-website) ]; then
                        docker stop college-website
                        docker rm college-website
                    fi

                    # Run container
                    docker run -d --name college-website -p 80:80 $ECR_REPO:latest
                EOT
                '''
            }
        }
    }

    post {
        success {
            echo "✅ Deployment completed successfully!"
        }
        failure {
            echo "❌ Build or deployment failed!"
        }
    }
}

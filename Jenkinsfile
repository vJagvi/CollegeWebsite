pipeline {
    agent any

    environment {
        IMAGE_NAME = "vjagvi/college-website"
        ECR_REPO   = "387056640483.dkr.ecr.us-east-1.amazonaws.com/college-website"
        REGION     = "us-east-1"
        AWS_CLI    = "C:\\Program Files\\Amazon\\AWSCLIV2\\aws.exe"
        TERRAFORM  = "C:\\terraform_1.13.3_windows_386\\terraform.exe"
    }

    stages {
        stage('Clone Repository') {
            steps {
                echo '📦 Cloning repository...'
                git branch: 'main', url: 'https://github.com/vJagvi/CollegeWebsite.git'
            }
        }

        stage('Build Docker Image') {
            steps {
                echo '🐳 Building Docker image...'
                bat 'docker build -t %IMAGE_NAME%:latest .'
            }
        }

        stage('Push to AWS ECR') {
            steps {
                echo '🚀 Pushing image to AWS ECR...'
                withCredentials([usernamePassword(credentialsId: 'aws-ecr-creds', usernameVariable: 'AWS_ACCESS_KEY_ID', passwordVariable: 'AWS_SECRET_ACCESS_KEY')]) {
                    bat """
                    set AWS_ACCESS_KEY_ID=%AWS_ACCESS_KEY_ID%
                    set AWS_SECRET_ACCESS_KEY=%AWS_SECRET_ACCESS_KEY%
                    "%AWS_CLI%" ecr get-login-password --region %REGION% | docker login --username AWS --password-stdin %ECR_REPO%
                    docker tag %IMAGE_NAME%:latest %ECR_REPO%:latest
                    docker push %ECR_REPO%:latest
                    """
                }
            }
        }

        stage('Deploy with Terraform') {
            steps {
                echo '🏗️ Deploying EC2 instance and running Docker container...'
                withCredentials([usernamePassword(credentialsId: 'aws-ecr-creds', usernameVariable: 'AWS_ACCESS_KEY_ID', passwordVariable: 'AWS_SECRET_ACCESS_KEY')]) {
                    dir('terraform') {
                        bat """
                        set AWS_ACCESS_KEY_ID=%AWS_ACCESS_KEY_ID%
                        set AWS_SECRET_ACCESS_KEY=%AWS_SECRET_ACCESS_KEY%
                        "%TERRAFORM%" init
                        "%TERRAFORM%" apply -auto-approve
                        """
                    }
                }
            }
        }

        stage('Run Monitoring Containers') {
            steps {
                echo '📊 Starting Prometheus, Node Exporter, and cAdvisor...'
                bat """
                REM Stop existing monitoring containers if running
                docker rm -f prometheus || exit 0
                docker rm -f node_exporter || exit 0
                docker rm -f cadvisor || exit 0

                REM Run Node Exporter
                docker run -d --name node_exporter --network=host prom/node-exporter

                REM Run cAdvisor
                docker run -d --name cadvisor ^
                    --volume=/:/rootfs:ro ^
                    --volume=/var/run:/var/run:rw ^
                    --volume=/sys:/sys:ro ^
                    --volume=/var/lib/docker/:/var/lib/docker:ro ^
                    -p 8080:8080 gcr.io/cadvisor/cadvisor:latest

                REM Run Prometheus
                docker run -d --name prometheus ^
                    -p 9090:9090 ^
                    -v %WORKSPACE%\\prometheus\\prometheus.yml:/etc/prometheus/prometheus.yml ^
                    prom/prometheus
                """
            }
        }
    }

    post {
        success {
            echo '✅ Docker image pushed, EC2 deployed, website and monitoring stack are running!'
            echo '🎉 Access Prometheus at http://<EC2_PUBLIC_IP>:9090'
            echo '🎉 Access cAdvisor at http://<EC2_PUBLIC_IP>:8080'
        }
        failure {
            echo '❌ Build or deployment failed!'
        }
    }
}

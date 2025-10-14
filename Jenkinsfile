pipeline {
    agent any

    environment {
        IMAGE_NAME = "vjagvi/college-website"
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
                echo '🐳 Building Docker image.... .'
                bat 'docker build -t %IMAGE_NAME%:latest .'
            }
        }

        stage('Push to Docker Hub') {
            steps {
                echo '🚢 Pushing image to Docker Hub... .'
                withCredentials([string(credentialsId: 'dockerhub-token', variable: 'DOCKERHUB_TOKEN')]) {
                    bat """
                    echo %DOCKERHUB_TOKEN% | docker login -u vjagvi --password-stdin
                    docker push %IMAGE_NAME%:latest
                    """
                }
            }
        }
    }

    post {
        success {
            echo '✅ Docker image built and pushed successfully!'
        }
        failure {
            echo '❌ Build failed!'
        }
    }
}

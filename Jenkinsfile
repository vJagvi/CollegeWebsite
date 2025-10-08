// Jenkinsfile for a Static HTML/CSS Website
pipeline {
    // 1. AGENT: Use any available Jenkins agent
    agent any

    // 💡 NEW DIRECTIVE: Defines parameters for the user to select when building the job.
    parameters {
        choice(
            name: 'TARGET_ENVIRONMENT',
            choices: ['dev', 'staging', 'prod'],
            description: 'Select the environment for deployment (e.g., dev for testing, prod for live).'
        )
    }

    // Optional: Define environment variables if needed (e.g., file extensions)
    environment {
        // Defines the folder where all website files are located (assuming the root)
        WEBSITE_SOURCE = '.' 
        // Define a variable to hold the deployment path, using the selected parameter
        DEPLOY_PATH = "/var/www/static-sites/${params.TARGET_ENVIRONMENT}"
    }

    // 2. STAGES: Defines the workflow phases
    stages {
        stage('Checkout Source Code') {
            steps {
                // Fetches the files from the configured Git repository branch
                checkout scm 
                echo 'Source code checked out successfully.'
            }
        }
        
        stage('Validate Content') {
            steps {
                // For static sites, the "Build" is often a simple check or cleanup.
                script {
                    if (fileExists("${WEBSITE_SOURCE}/index.html")) {
                        echo 'Index.html found. Static website structure is valid.'
                    } else {
                        error 'FATAL: index.html is missing! Cannot proceed.'
                    }
                }
            }
        }
        
        stage('Archive Files') {
            steps {
                // Archives the essential website files, making them available in the Jenkins job history.
                archiveArtifacts artifacts: '**/*.html, **/*.css, **/*.js, **/*.jpg, **/*.png', fingerprint: true
                echo 'Website assets archived and ready for deployment.'
            }
        }

        // 💡 NEW STAGE: Handles the deployment logic
        stage('Deploy Site') {
            // Deployments often require caution, especially for production
            options {
                // Timeout the deployment if it takes longer than 10 minutes
                timeout(time: 10, unit: 'MINUTES')
            }
            steps {
                echo "Starting deployment to the target environment: ${params.TARGET_ENVIRONMENT}"
                echo "Deployment Path: ${DEPLOY_PATH}"
                
                // --- Conditional logic based on the selected parameter ---
                script {
                    if (params.TARGET_ENVIRONMENT == 'prod') {
                        // Production deployments should ideally require a manual approval step
                        // input(message: "Deploying to PRODUCTION. Click 'Proceed' to confirm.", submitter: 'admin,ops-team')
                        echo "!!! Production deployment is commencing. This would be your real SCP/S3 sync command."
                    } else {
                        echo "Deploying to non-production environment."
                    }
                }
                
                // Example deployment step (replace with your actual rsync/scp/S3 command):
                // This simulates copying the files using rsync/ssh to the DEPLOY_PATH
                sh "echo rsync -avz ${WEBSITE_SOURCE}/* user@webserver.com:${DEPLOY_PATH}/"
                sh "echo 'Deployment simulation complete for ${params.TARGET_ENVIRONMENT}'"
            }
        }
    }
    
    // 3. POST: Defines actions that run after the pipeline is complete
    post {
        success {
            echo "✅ Pipeline for ${params.TARGET_ENVIRONMENT} completed successfully."
        }
        failure {
            echo "❌ Pipeline failed during validation, archiving, or deployment to ${params.TARGET_ENVIRONMENT}."
        }
        always {
            // Clean up the workspace on the agent machine
            cleanWs() 
        }
    }
}

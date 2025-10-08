// Jenkinsfile for a Static HTML/CSS Website
pipeline {
    // 1. AGENT: Use any available Jenkins agent
    agent any

    // Optional: Define environment variables if needed (e.g., file extensions)
    environment {
        // Defines the folder where all website files are located (assuming the root)
        WEBSITE_SOURCE = '.' 
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
                // This step confirms the necessary files exist (e.g., index.html).
                script {
                    if (fileExists("${WEBSITE_SOURCE}/index.html")) {
                        echo 'Index.html found. Static website structure is valid.'
                    } else {
                        error 'FATAL: index.html is missing! Cannot proceed.'
                    }
                }
                // Optional: Run a linter (e.g., stylelint for CSS, htmlhint) if set up on the agent
                // sh 'npx htmlhint ${WEBSITE_SOURCE}' 
            }
        }
        
        stage('Archive Files') {
            steps {
                // Archives the essential website files, making them available in the Jenkins job history.
                archiveArtifacts artifacts: '**/*.html, **/*.css, **/*.js, **/*.jpg, **/*.png', fingerprint: true
                echo 'Website assets archived and ready for deployment.'
            }
        }

        // 📝 Add a 'Deploy' stage here based on your deployment method:
        // * FTP/SCP using the "sh" step and appropriate credentials/tools
        // * Pushing to an S3 bucket (requires AWS CLI or S3 plugin)
        // * Copying files to a web server directory
    }
    
    // 3. POST: Defines actions that run after the pipeline is complete
    post {
        success {
            echo '✅ Static website pipeline completed successfully.'
        }
        failure {
            echo '❌ Pipeline failed during validation or archiving.'
        }
        always {
            cleanWs() // Cleans up the workspace on the agent machine
        }
    }
}
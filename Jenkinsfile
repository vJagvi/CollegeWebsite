// Jenkinsfile for a Static HTML/CSS Website

// FINAL UPDATE: Using the Shared Library
// 💡 STEP 1: Load the shared library configured globally in Jenkins.
// Syntax: @Library('<LibraryName>@<Version/Branch>') _
@Library('my-cicd-library@main') _ 

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
                echo 'hi hi Source code checked out successfully now.'
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

        // 💡 UPDATED STAGE: Now calls the reusable function from the shared library
        stage('Deploy Site via Library') {
            steps {
                echo "Delegating deployment to reusable 'customDeploy' function from the Shared Library."
                
                // 💡 STEP 2: Call the customDeploy function, passing environment and path.
                // The actual complex deployment logic is now hidden inside the library file.
                customDeploy(params.TARGET_ENVIRONMENT, DEPLOY_PATH)
            }
        }
    }
    
    // 3. POST: Defines actions that run after the pipeline is complete
    post {
        success {
            echo "✅ CI Pipeline completed successfully. Triggering Downstream CD Job..."
            
            // Trigger the Downstream job named 'ClgWebs-Deployment-Job'
            build job: 'ClgWebs-Deployment-Job', 
                     wait: true, 
                     propagate: true
                     
            echo "Downstream job triggered successfully."
        }
        failure {
            echo "❌ Pipeline failed during execution."
        }
        always {
            // Clean up the workspace on the agent machine
            cleanWs() 
        }
    }
}

pipeline {
    agent any

    environment {
        REPO_DATA_URL = 'https://github.com/blackgolyb/cv.git'
        REPO_DATA_BRANCH = 'main'
    }

    triggers {
        pollSCM('* * * * *')
    }

    stages {
        stage('Checkout Repo DATA') {
            steps {
                dir('.__src__') {
                    git branch: "${REPO_DATA_BRANCH}", url: "${REPO_DATA_URL}"
                }
            }
        }
        stage('Fill cv template') {
            steps {
                dir('scripts') {
                    sh('chmod +x ./fill_template.sh')
                    sh('./fill_template.sh')
                }
            }
        }
        stage('Publish new cv version') {
            steps {
                dir('scripts') {
                    sh('chmod +x ./publish_target.sh')
                    sh('./publish_target.sh')
                }
            }
        }
    }

    post {
        success {
            echo 'Pipeline completed successfully.'
        }
        failure {
            echo 'Pipeline failed.'
        }
    }
}
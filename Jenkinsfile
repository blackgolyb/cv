pipeline {
    agent any

    environment {
        REPO_SOURCE_URL = 'https://github.com/blackgolyb/about_me.git'
        REPO_SOURCE_BRANCH = 'main'
    }

    triggers {
        pollSCM('* * * * *')
    }

    stages {
        stage('test') {
            steps {
                script {
                    sh 'ls -la'
                }
            }
        }
        stage('Checkout Repo SOURCE') {
            steps {
                dir('.src') {
                    git branch: "${REPO_SOURCE_BRANCH}", url: "${REPO_SOURCE_URL}"
                }
            }
        }
        stage('Build new cv vervion') {
            steps {
                script {
                    sh 'ls -la'
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
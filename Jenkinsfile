pipeline {
    agent any

    environment {
        REPO_DATA_URL = 'git@github.com:blackgolyb/about_me.git'
        REPO_DATA_BRANCH = 'main'
    }

    triggers {
        pollSCM('* * * * *')
    }

    stages {
        stage('Checkout Repo DATA') {
            steps {
                dir('.__src__') {
                    git credentialsId: "github-ssh-key", branch: "${REPO_DATA_BRANCH}", url: "${REPO_DATA_URL}"
                }
            }
        }
        stage('Fill cv template') {
            steps {
                script {
                    sh './scripts/fill_template.sh'
                }
            }
        }
        stage('Publish new cv version') {
            steps {
                script {
                    sh './scripts/publish_target.sh'
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
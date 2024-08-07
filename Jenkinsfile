pipeline {
    agent any

    options {
        buildDiscarder(logRotator(numToKeepStr: '3', artifactNumToKeepStr: '3'))
    }

    triggers {
        pollSCM('H/5 * * * *')
    }

    environment {
        REPO_DATA = 'https://github.com/blackgolyb/about_me.git'
        REPO_SRC = 'https://github.com/blackgolyb/cv.git'
    }

    stages {
        stage('Check Repositories') {
            steps {
                script {
                    def changesInRepo1 = false
                    def changesInRepo2 = false
                    
                    // Перевіряємо зміни в першому репозиторії
                    dir('__data__') {
                        git url: "${REPO_DATA}", branch: 'main'
                        changesInRepo1 = sh(returnStatus: true, script: 'git diff --name-only HEAD~1') != 0
                    }
                    
                    // Перевіряємо зміни в другому репозиторії
                    dir('__src__') {
                        git url: "${REPO_SRC}", branch: 'main'
                        changesInRepo2 = sh(returnStatus: true, script: 'git diff --name-only HEAD~1') != 0
                    }
                    
                    // Якщо змін немає, завершуємо пайплайн
                    if (!changesInRepo1 && !changesInRepo2) {
                        echo "No changes detected. Stopping pipeline."
                        currentBuild.result = 'SUCCESS'
                        return
                    }
                }
            }
        }
        
        stage('Fill cv template') {
            steps {
                dir('__src__/scripts') {
                    sh('chmod +x ./fill_template.sh')
                    sh('./fill_template.sh')
                }
            }
        }

        stage('Publish new cv version') {
            steps {
                dir('__src__/scripts') {
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

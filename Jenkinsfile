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
        REPO_SRC = 'git@github.com:blackgolyb/cv.git'
    }

    stages {
        stage('Check Repositories') {
            steps {
                script {
                    // Перевіряємо зміни в першому репозиторії
                    dir('__data__') {
                        checkout([$class: 'GitSCM', branches: [[name: '*/main']], userRemoteConfigs: [[url: "${REPO_DATA}"]]])
                    }

                    // Перевіряємо зміни в другому репозиторії
                    dir('__src__') {
                        checkout([$class: 'GitSCM', branches: [[name: '*/main']], userRemoteConfigs: [[url: "${REPO_SRC}"]], credentialsId: 'github-ssh-key'])
                    }

                    def changesInData = currentBuild.changeSets[0]?.items?.length > 0
                    def changesInSrc = currentBuild.changeSets[1]?.items?.length > 0

                    // Якщо змін немає, завершуємо пайплайн
                    if (!changesInData && !changesInSrc) {
                        echo 'No changes detected. Stopping pipeline.'
                        currentBuild.result = 'ABORTED'
                        error('No changes detected. Stopping pipeline.')
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
                    sshagent(credentials: ['github-ssh-key']) {
                        sh('./publish_target.sh')
                    }
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

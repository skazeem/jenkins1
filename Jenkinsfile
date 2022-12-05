pipeline {
    agent { docker { image 'jenkins/jenkins:lts' } }
    stages {
        stage('build') {
            steps {
                sh 'mvn --version'
            }
        }
    }
}

pipeline {
    agent any
    stages {
        stage('build image') {
            steps {
                 sh """docker build -f Dockerfile -t demoimage ."""
            }
        }
     }
  }

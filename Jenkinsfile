pipeline {
    agent any
    stages {
        stage('build image') {
            steps {
                 sh """ docker build -t demoimage /var/jenkins_home/workspace/jenkins_demo/cirrus_jenkins ."""
            }
        }
     }
  }

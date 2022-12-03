node{
    properties(
        [
            parameters(
                [extendedChoice(defaultPropertyFile: '/var/lib/jenkins/global_pipeline_parameters/master.properties', defaultPropertyKey: 'Hostname', description: 'testing pipeline', multiSelectDelimiter: ',', name: 'hostname', quoteValue: false, saveJSONParameterToFile: false, type: 'PT_TEXTBOX', visibleItemCount: 1), ]
                )
            ]
        )
}
pipeline {
    agent { label 'master' }
    stages {
        stage('build') {
            steps {
                echo "Hello World!"
            }
        }
    }
}

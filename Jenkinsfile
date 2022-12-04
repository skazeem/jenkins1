node {
    properties(
        [
            parameters(
                [extendedChoice(defaultPropertyFile: '/var/lib/jenkins/global_pipeline_parameters/master.properties', defaultPropertyKey: 'Hostname', description: 'testing pipeline', multiSelectDelimiter: ',', name: 'hostname', quoteValue: false, saveJSONParameterToFile: false, type: 'PT_TEXTBOX', visibleItemCount: 1), ]
                )
            ]
        )
    def app
    stage ('clone repo'){
        checkout scm
    }
    stage ('build image'){
        app = docker.build("localhost:5000/jenkins")
    }
    stage ('test image'){
        app.inside{
            sh 'echo "test"'
        }
    }    
    stage ('push image'){
    docker.withRegistry('https://registry.localhost:5000'){
        app.push("latest")
    }
    }
}

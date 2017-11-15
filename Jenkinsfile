#!/usr/bin/env groovy

pipeline {
  agent { label 'executor-v2' }

  options {
    timestamps()
    buildDiscarder(logRotator(numToKeepStr: '30'))
  }

  stages {
    stage('Test') {
      steps {
        sh './jenkins.sh'

        junit 'spec/reports/*.xml'
        junit 'features/reports/*.xml'
      }
    }
  }

  post {
    always {
      sh 'docker run -i --rm -v $PWD:/src -w /src alpine/git clean -fxd'
      deleteDir()
    }
    failure {
      slackSend(color: 'danger', message: "${env.JOB_NAME} #${env.BUILD_NUMBER} FAILURE (<${env.BUILD_URL}|Open>)")
    }
    unstable {
      slackSend(color: 'warning', message: "${env.JOB_NAME} #${env.BUILD_NUMBER} UNSTABLE (<${env.BUILD_URL}|Open>)")
    }
  }
}

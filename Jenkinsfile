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
        sh './test.sh'

        junit 'spec/reports/*.xml'
        junit 'features/reports/*.xml'
      }
    }
    
    stage('Publish to RubyGems') {
      when {
        branch 'possum'
      }
      steps {
        build job: 'release-rubygems',
        parameters: [string(name: 'GEM_NAME', value: 'conjur-api'),
                     string(name: 'GEM_BRANCH', value: 'possum')]
      }
    }
  }

  post {
    always {
      sh 'docker run -i --rm -v $PWD:/src -w /src alpine/git clean -fxd'
    }
    failure {
      slackSend(color: 'danger', message: "${env.JOB_NAME} #${env.BUILD_NUMBER} FAILURE (<${env.BUILD_URL}|Open>)")
    }
    unstable {
      slackSend(color: 'warning', message: "${env.JOB_NAME} #${env.BUILD_NUMBER} UNSTABLE (<${env.BUILD_URL}|Open>)")
    }
  }
}

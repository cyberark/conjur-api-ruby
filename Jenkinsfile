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
        milestone(1)
        sh './test.sh'

        junit 'spec/reports/*.xml'
        junit 'features/reports/*.xml'
      }
    }

    stage('Publish to RubyGems?') {
      when {
        branch 'master'
      }
      steps {
        milestone(2)
        input(
          message: 'Publish to RubyGems?',
          ok: 'PUBLISH',
          parameters: [
            booleanParam(defaultValue: false, description: 'Approve and publish this gem to RubyGems', name: 'PUBLISH')
          ],
          submitterParameter: 'PUBLISHER'
        )
        milestone(3)
      }
    }
    
    stage('Publishing to RubyGems') {
      steps {
        echo 'publishing!'
        // build(job: 'release-rubygems', parameters: [
        //   string(name: 'GEM_NAME', value: 'conjur-api'),
        //   string(name: 'GEM_BRANCH', value: "${env.BRANCH_NAME}")
        // ])
        milestone(4)
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

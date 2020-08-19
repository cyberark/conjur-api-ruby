#!/usr/bin/env groovy

pipeline {
  agent { label 'executor-v2' }

  options {
    timestamps()
    buildDiscarder(logRotator(numToKeepStr: '30'))
  }

  triggers {
    cron(getDailyCronString())
  }

  stages {
    stage('Validate') {
      parallel {
        stage('Changelog') {
          steps { sh './bin/parse-changelog.sh' }
        }
      }
    }

    stage('Test') {
      steps {
        script {
          ccCoverage.setGitEnvVars();
        }
        milestone(1)
        sh './test.sh'
      }

      post {
        always {
          junit 'spec/reports/*.xml'
          junit 'features/reports/*.xml'
          junit 'features_v4/reports/*.xml'
          cobertura autoUpdateHealth: true, autoUpdateStability: true, coberturaReportFile: 'coverage/coverage.xml', conditionalCoverageTargets: '100, 0, 0', failUnhealthy: true, failUnstable: false, lineCoverageTargets: '99, 0, 0', maxNumberOfBuilds: 0, methodCoverageTargets: '100, 0, 0', onlyStable: false, sourceEncoding: 'ASCII', zoomCoverageChart: false
        }
      }
    }

    // Only publish to RubyGems if the tag begins with 'v' ex) v5.3.2
    stage('Publish to RubyGems?') {
      agent { label 'executor-v2' }

      when { tag "v*" }
      steps {
        // Clean up first
        sh 'docker run -i --rm -v $PWD:/src -w /src alpine/git clean -fxd'

        sh './publish.sh'

        // Clean up again...
        sh 'docker run -i --rm -v $PWD:/src -w /src alpine/git clean -fxd'
        deleteDir()
      }
    }

  }

  post {
    always {
      cleanupAndNotify(currentBuild.currentResult)
    }
  }
}

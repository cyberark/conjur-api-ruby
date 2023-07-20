#!/usr/bin/env groovy

// Automated release, promotion and dependencies
properties([
  release.addParams()
])

if (params.MODE == "PROMOTE") {
  release.promote(params.VERSION_TO_PROMOTE) { sourceVersion, targetVersion, assetDirectory ->
    sh './publish.sh'
  }
  return
}

pipeline {
  agent { label 'executor-v2' }

  options {
    timestamps()
    buildDiscarder(logRotator(numToKeepStr: '30'))
  }

  triggers {
    cron(getDailyCronString())
  }

  environment {
    MODE = release.canonicalizeMode()
  }

  stages {
    stage ("Skip build if triggering job didn't create a release") {
      when {
        expression {
          MODE == "SKIP"
        }
      }
      steps {
        script {
          currentBuild.result = 'ABORTED'
          error("Aborting build because this build was triggered from upstream, but no release was built")
        }
      }
    }
    stage('Validate Changelog and set version') {
      steps {
        parseChangelog()
        updateVersion("CHANGELOG.md", "${BUILD_NUMBER}")
      }
    }

    stage('Prepare CC Report Dir'){
      steps {
        script {
          ccCoverage.dockerPrep()
          sh 'mkdir -p coverage'
        }
      }
    }

    stage('Test Ruby 3.0') {
      environment {
        RUBY_VERSION = '3.0'
      }
      steps {
        sh("./test.sh")
      }
      post {
        always {
          junit 'spec/reports/*.xml'
          junit 'features/reports/*.xml'
          junit 'features_v4/reports/*.xml'
        }
      }
    }

    stage('Test Ruby 3.1') {
      environment {
        RUBY_VERSION = '3.1'
      }
      steps {
        sh("./test.sh")
      }
      post {
        always {
          junit 'spec/reports/*.xml'
          junit 'features/reports/*.xml'
          junit 'features_v4/reports/*.xml'
        }
      }
    }

    stage('Test Ruby 3.2') {
      environment {
        RUBY_VERSION = '3.2'
      }
      steps {
        sh("./test.sh")
      }
      post {
        always {
          junit 'spec/reports/*.xml'
          junit 'features/reports/*.xml'
          junit 'features_v4/reports/*.xml'
        }
      }
    }

    stage('Submit Coverage Report'){
      steps{

        println "NRK: Search files 1"
        sh "find . -name '.resultset.json' || true"
        sh "find . -name 'index.html' || true"
        sh "find . -iname 'coverage*' || true"
        sh "find spec/reports/ -iname '*.xml' || true"
        sh "find features/reports/ -iname '*.xml' || true"
        sh "ls -alh coverage/*/*/*"
        sh "ls -alh coverage/**"


        sh 'ci/submit-coverage'

        println "NRK: Search files 2"
        sh "find . -name '.resultset.json' || true"
        sh "find . -name '.resultset.json' || true"
        sh "find . -name 'index.html' || true"
        sh "find . -iname 'coverage*' || true"
        sh "find spec/reports/ -iname '*.xml' || true"
        sh "find features/reports/ -iname '*.xml' || true"
        sh "ls -alh coverage/*/*/*"
        sh "ls -alh coverage/**"

        publishHTML([reportDir: 'coverage', reportFiles: 'index.html', reportName: 'Coverage Report', reportTitles: '',
          allowMissing: false, alwaysLinkToLastBuild: true, keepAll: true])
      }

      post {
        always {
          archiveArtifacts artifacts: "coverage/.resultset.json", fingerprint: false
        }
      }
    }

    stage('Release') {
      when {
        expression {
          MODE == "RELEASE"
        }
      }

      steps {
        release {
          // Clean up all but the calculated VERSION
          sh '''docker run -i --rm -v $(pwd):/src -w /src --entrypoint /bin/sh alpine/git \
                -c "git config --global --add safe.directory /src && \
                    git clean -fdx \
                      -e VERSION \
                      -e bom-assets/ \
                      -e release-assets" '''
          sh './publish.sh'
          sh 'cp conjur-api-*.gem release-assets/.'
        }
      }
    }
  }

  post {
    always {
      cleanupAndNotify(currentBuild.currentResult)
    }
  }
}

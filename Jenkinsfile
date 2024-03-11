#!/usr/bin/env groovy

@Library("product-pipelines-shared-library") _

// Automated release, promotion and dependencies
properties([
  release.addParams()
])

if (params.MODE == "PROMOTE") {
  release.promote(params.VERSION_TO_PROMOTE) { infrapool, sourceVersion, targetVersion, assetDirectory ->
    infrapool.agentSh './publish.sh'
  }

  // Copy Github Enterprise release to Github
  release.copyEnterpriseRelease(params.VERSION_TO_PROMOTE)
  return
}

pipeline {
  agent { label 'conjur-enterprise-common-agent' }

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

    stage('Scan for internal URLs') {
      steps {
        script {
          detectInternalUrls()
        }
      }
    }

    stage('Get InfraPool Agent') {
      steps {
        script {
          infrapool = getInfraPoolAgent.connected(type: "ExecutorV2", quantity: 1, duration: 1)[0]
        }
      }
    }

    stage('Validate Changelog and set version') {
      steps {
        parseChangelog(infrapool)
        updateVersion(infrapool, "CHANGELOG.md", "${BUILD_NUMBER}")
      }
    }

    stage('Prepare CC Report Dir'){
      steps {
        script {
          infrapool.agentSh 'mkdir -p coverage'
        }
      }
    }

    stage('Test Ruby 3.0') {
      environment {
        RUBY_VERSION = '3.0'
      }
      steps {
        script {
          infrapool.agentSh "./test.sh"
          infrapool.agentStash name: 'reports3.0', includes: '**/reports/*.xml'
        }
      }
      post {
        always {
          unstash 'reports3.0'
        }
      }
    }

    stage('Test Ruby 3.1') {
      environment {
        RUBY_VERSION = '3.1'
      }
      steps {
        script {
          infrapool.agentSh "./test.sh"
          infrapool.agentStash name: 'reports3.1', includes: '**/reports/*.xml'
        }
      }
      post {
        always {
          unstash 'reports3.1'
        }
      }
    }

    stage('Test Ruby 3.2') {
      environment {
        RUBY_VERSION = '3.2'
      }
      steps {
        script {
          infrapool.agentSh "./test.sh"
          infrapool.agentStash name: 'reports3.2', includes: '**/reports/*.xml'
        }
      }
      post {
        always {
          unstash 'reports3.2'
        }
      }
    }

    stage('Submit Coverage Report'){
      steps{
        script {
          infrapool.agentStash name: 'coverage', includes: '**/coverage/**'
        }
        unstash 'coverage'

        cobertura autoUpdateHealth: false,
          autoUpdateStability: false,
          coberturaReportFile: 'coverage/coverage.xml',
          conditionalCoverageTargets: '70, 0, 0',
          failUnhealthy: false,
          failUnstable: false,
          maxNumberOfBuilds: 0,
          lineCoverageTargets: '70, 0, 0',
          methodCoverageTargets: '70, 0, 0',
          onlyStable: false,
          sourceEncoding: 'ASCII',
          zoomCoverageChart: false

        publishHTML([reportDir: 'coverage', reportFiles: 'index.html', reportName: 'Coverage Report', reportTitles: '',
          allowMissing: false, alwaysLinkToLastBuild: true, keepAll: true])
        codacy action: 'reportCoverage', filePath: "coverage/coverage.xml"
      }

      post {
        always {
          // only call junit once to submit all reports, otherwise it will only submit reports
          // from the last junit call as it overwrites the previously submitted reports
          junit '**/reports/*.xml'
          archiveArtifacts artifacts: "coverage/coverage.xml", fingerprint: false
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
        script {
          release(infrapool) {
            // Clean up all but the calculated VERSION
            infrapool.agentSh '''docker run -i --rm -v $(pwd):/src -w /src --entrypoint /bin/sh alpine/git \
                  -c "git config --global --add safe.directory /src && \
                      git clean -fdx \
                        -e VERSION \
                        -e bom-assets/ \
                        -e release-assets" '''
            infrapool.agentSh './publish.sh'
            infrapool.agentSh 'cp conjur-api-*.gem release-assets/.'
          }
        }
      }
    }
  }

  post {
    always {
      releaseInfraPoolAgent(".infrapool/release_agents")
    }
  }
}

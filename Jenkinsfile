#!/usr/bin/env groovy
import hudson.model.*

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
    stage('Validate Changelog') {
      steps { sh './bin/parse-changelog.sh' }
    }

    stage('Prepare CC Report Dir'){
      steps {
        script {
          ccCoverage.dockerPrep()
          sh 'mkdir -p coverage'
        }
      }
    }

    stage('Tests for different ruby versions') {
        parallel {
          stage('Ruby 2.5') {
            environment {
        	  RUBY_VERSION = '2.5'
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

          stage('Ruby 2.6') {
            environment {
              RUBY_VERSION = '2.6'
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

          stage('Ruby 2.7') {
            environment {
              RUBY_VERSION = '2.7'
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

          stage('Ruby 3.0.2') {
            environment {
        	  RUBY_VERSION = '3.0.2'
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
        }
    }

    stage('Submit Coverage Report'){
      steps{
        sh 'ci/submit-coverage'
        publishHTML([reportDir: 'coverage', reportFiles: 'index.html', reportName: 'Coverage Report', reportTitles: '',
          allowMissing: false, alwaysLinkToLastBuild: true, keepAll: true])
      }

      post {
        always {
          archiveArtifacts artifacts: "coverage/.resultset.json", fingerprint: false
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

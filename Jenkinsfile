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

  environment {
    MODE = release.canonicalizeMode()
  }

  triggers {
    // Declarative pipelines allow only one parameterizedCron trigger, so both
    // schedules live in a single multi-line string. The daily build also
    // exercises the cloud authenticators end-to-end; PR builds leave the
    // RUN_*_TESTS params false, so those stages are skipped there.
    parameterizedCron("""
      ${getDailyCronString("%RUN_AWS_TESTS=true;RUN_AZURE_TESTS=true;RUN_GCP_TESTS=true")}
      ${getWeeklyCronString("H(1-5)","%MODE=RELEASE")}
    """)
  }

  parameters {
    booleanParam(name: 'RUN_AWS_TESTS', defaultValue: false,
      description: 'Run the authn-iam integration test on an AWS executor agent')
    booleanParam(name: 'RUN_AZURE_TESTS', defaultValue: false,
      description: 'Run the authn-azure integration test on an Azure executor agent')
    booleanParam(name: 'RUN_GCP_TESTS', defaultValue: false,
      description: 'Run the authn-jwt/gcp integration test (token fetched on a GCP agent)')
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
          // Provision dedicated cloud agents only when the matching cloud test
          // is requested. These are real Azure/GCP VMs whose managed identity /
          // service account the authenticators exercise against the live
          // metadata service. The AWS test reuses the standard ExecutorV2 agent
          // (which itself runs in AWS with an instance profile).
          if (params.RUN_AZURE_TESTS) {
            azureInfrapool = getInfraPoolAgent.connected(type: "AzureExecutorV2", quantity: 1, duration: 1)[0]
          }
          if (params.RUN_GCP_TESTS) {
            gcpInfrapool = getInfraPoolAgent.connected(type: "GcpExecutorV2", quantity: 1, duration: 1)[0]
          }
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

    stage('Test Ruby 3.3') {
      environment {
        INFRAPOOL_RUBY_VERSION = '3.3'
        INFRAPOOL_REGISTRY_URL = "registry.tld"
      }
      steps {
        script {
          infrapool.agentSh "./test.sh"
          infrapool.agentStash name: 'reports3.3', includes: '**/reports/*.xml'
        }
      }
      post {
        always {
          unstash 'reports3.3'
        }
      }
    }

    stage('Test Ruby 3.4') {
      environment {
        INFRAPOOL_RUBY_VERSION = '3.4'
        INFRAPOOL_REGISTRY_URL = "registry.tld"
      }
      steps {
        script {
          infrapool.agentSh "./test.sh"
          infrapool.agentStash name: 'reports3.4', includes: '**/reports/*.xml'
        }
      }
      post {
        always {
          unstash 'reports3.4'
        }
      }
    }

    stage('Test Ruby 4.0') {
      environment {
        INFRAPOOL_RUBY_VERSION = '4.0'
        INFRAPOOL_REGISTRY_URL = "registry.tld"
      }
      steps {
        script {
          infrapool.agentSh "./test.sh"
          infrapool.agentStash name: 'reports4.0', includes: '**/reports/*.xml'
          // Stash coverage from the full suite now. The cloud stages below run
          // ./test.sh again on this agent, and jenkins_init wipes and regenerates
          // coverage/ from a single cloud feature (no rspec) — which would drop
          // the reported coverage well below the quality gate. Capturing it here
          // keeps the submitted coverage that of the complete unit+cucumber run.
          infrapool.agentStash name: 'coverage', includes: '**/coverage/**'
        }
      }
      post {
        always {
          unstash 'reports4.0'
        }
      }
    }

    stage('Run AWS IAM tests') {
      when { expression { params.RUN_AWS_TESTS } }
      environment {
        INFRAPOOL_RUN_AWS_TESTS = 'true'
        INFRAPOOL_RUBY_VERSION  = '3.3'
        INFRAPOOL_REGISTRY_URL  = "registry.tld"
      }
      steps {
        script {
          // authn-iam identifies the Conjur host by the AWS caller identity, so
          // the host id in the policy must be "<account-id>/<role-name>". Derive
          // those from the agent's own instance profile (as conjur-api-java does)
          // and pass them to the feature via env.
          def callerIdentityJson = infrapool.agentSh(script: 'aws sts get-caller-identity', returnStdout: true).trim()
          def awsAccountId = (callerIdentityJson =~ /"Account"\s*:\s*"([^"]+)"/)[0][1]
          def awsArn       = (callerIdentityJson =~ /"Arn"\s*:\s*"([^"]+)"/)[0][1]
          def awsRoleName  = awsArn.tokenize('/')[1]  // arn:...:assumed-role/<role>/<session>
          infrapool.agentSh """
            export INFRAPOOL_AWS_ACCOUNT_ID='${awsAccountId}'
            export INFRAPOOL_AWS_ROLE_NAME='${awsRoleName}'
            ./test.sh
          """
        }
      }
      post {
        always {
          script { infrapool.agentStash name: 'reports-aws', includes: '**/reports/*.xml' }
          unstash 'reports-aws'
        }
      }
    }

    stage('Run Azure tests') {
      when { expression { params.RUN_AZURE_TESTS } }
      environment {
        INFRAPOOL_RUN_AZURE_TESTS = 'true'
        INFRAPOOL_RUBY_VERSION    = '3.3'
        INFRAPOOL_REGISTRY_URL    = "registry.tld"
      }
      steps {
        script {
          // summon injects AZURE_SUBSCRIPTION_ID / AZURE_RESOURCE_GROUP /
          // USER_ASSIGNED_IDENTITY_CLIENT_ID from the CI vault; the test hits
          // the real Azure IMDS on this Azure VM.
          azureInfrapool.agentSh "summon -e azure ./test.sh"
        }
      }
      post {
        always {
          script { azureInfrapool.agentStash name: 'reports-azure', includes: '**/reports/*.xml' }
          unstash 'reports-azure'
        }
      }
    }

    stage('Run GCP tests') {
      when { expression { params.RUN_GCP_TESTS } }
      environment {
        INFRAPOOL_RUN_GCP_TESTS = 'true'
        INFRAPOOL_RUBY_VERSION  = '3.3'
        INFRAPOOL_REGISTRY_URL  = "registry.tld"
        GCP_CTX_DIR = "gcp-ctx"
      }
      steps {
        script {
          // GCP agents lack a Docker runtime, so fetch a real identity token on
          // the GCP VM, stash it, then run the actual test on the AWS agent with
          // the token supplied via GCP_ID_TOKEN.
          gcpInfrapool.agentSh "./ci/get_gcp_token.sh data/test/gcp-apps/test-app cucumber ${GCP_CTX_DIR}"
          gcpInfrapool.agentStash name: 'gcp-token', includes: "${GCP_CTX_DIR}/*"
          infrapool.agentUnstash name: 'gcp-token'
          infrapool.agentSh """
            export GCP_ID_TOKEN="\$(cat ${GCP_CTX_DIR}/token)"
            export GCP_PROJECT_ID="\$(cat ${GCP_CTX_DIR}/project-id)"
            ./test.sh
          """
        }
      }
      post {
        always {
          script { infrapool.agentStash name: 'reports-gcp', includes: '**/reports/*.xml' }
          unstash 'reports-gcp'
        }
      }
    }

    stage('Submit Coverage Report'){
      steps{
        // Coverage was stashed at the end of 'Test Ruby 4.0', before the cloud
        // stages regenerated a partial coverage/ on the agent.
        unstash 'coverage'

        recordCoverage(
          tools: [[parser: 'COBERTURA', pattern: 'coverage/coverage.xml']],
          sourceCodeEncoding: 'UTF-8',
          qualityGates: [
            [threshold: 70.0, metric: 'LINE', baseline: 'PROJECT', unstable: true],
            [threshold: 70.0, metric: 'BRANCH', baseline: 'PROJECT', unstable: true],
            [threshold: 70.0, metric: 'METHOD', baseline: 'PROJECT', unstable: true]
          ],
          skipPublishingChecks: false
        )

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

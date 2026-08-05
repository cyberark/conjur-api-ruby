@authn_gcp
Feature: Authenticate to Conjur using GCP workload identity (authn-gcp)

  This scenario is a live integration test. GCP executor agents typically lack a
  Docker runtime, so the flow is split: ci/get_gcp_token.sh fetches a real GCP
  identity token on the GCP agent, the pipeline hands it to this test via
  GCP_ID_TOKEN, and new_from_gcp exchanges that pre-fetched token with Conjur
  (bypassing the metadata service). Tagged @authn_gcp, gated by RUN_GCP_TESTS.
  See Jenkinsfile and features/README.md.

  authn-gcp is a serviceless authenticator: the host is identified by its
  authn-gcp/project-id annotation (set from GCP_PROJECT_ID), not a service id.

  Scenario: Authenticate with a pre-fetched GCP identity token and retrieve a secret
    Given I enable the authn-gcp authenticator for host "data/test/gcp-apps/test-app"
    And the secret "data/test/gcp-apps/db-password" has value "s3cr3t"
    When I authenticate via authn-gcp as "host/data/test/gcp-apps/test-app" using the pre-fetched token
    Then I receive a Conjur access token
    And I can retrieve the secret "data/test/gcp-apps/db-password" with value "s3cr3t"

@authn_iam
Feature: Authenticate to Conjur using AWS IAM (authn-iam)

  This scenario is a live integration test: it exercises new_from_iam against
  the real AWS STS service using the credentials of the host it runs on. It is
  tagged @authn_iam and is only run in CI on an AWS executor agent, gated by
  RUN_AWS_TESTS. See Jenkinsfile and features/README.md.

  authn-iam identifies the Conjur host by the AWS caller identity, so the host
  id is "<AWS_ACCOUNT_ID>/<AWS_ROLE_NAME>" (derived on the agent from
  `aws sts get-caller-identity` and passed in via env).

  Scenario: Authenticate and retrieve a secret via authn-iam
    Given I enable the authn-iam authenticator "prod" for the AWS caller identity host
    And the secret "test/iam-apps/db-password" has value "s3cr3t"
    When I authenticate via authn-iam as the AWS caller identity host with service id "prod"
    Then I receive a Conjur access token
    And I can retrieve the secret "test/iam-apps/db-password" with value "s3cr3t"

@authn_azure
Feature: Authenticate to Conjur using Azure Managed Identity (authn-azure)

  This scenario is a live integration test: it exercises new_from_azure against
  the real Azure Instance Metadata Service (IMDS). It is tagged @authn_azure and
  is only run in CI on an Azure executor agent, gated by RUN_AZURE_TESTS, which
  also supplies AZURE_SUBSCRIPTION_ID / AZURE_RESOURCE_GROUP / the user-assigned
  identity client id. See Jenkinsfile and features/README.md.

  Scenario: Authenticate with a system-assigned identity and retrieve a secret
    Given I enable the authn-azure authenticator "prod" for host "test/azure-apps/test-app" using Azure environment config
    And the secret "test/azure-apps/db-password" has value "s3cr3t"
    When I authenticate via authn-azure as "host/test/azure-apps/test-app" with service id "prod"
    Then I receive a Conjur access token
    And I can retrieve the secret "test/azure-apps/db-password" with value "s3cr3t"

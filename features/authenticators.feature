Feature: List and manage authenticators

  Background:
    Given I run the code:
    """
    $conjur.load_policy 'root', <<-POLICY
    - !webservice conjur/authn-k8s/my-auth
    POLICY
    """
    And I setup a keycloak authenticator

  Scenario: Authenticator list includes the authenticator status
    When I run the code:
    """
    $conjur.authenticator_list
    """
    Then the JSON should have "installed"
    And the JSON should have "configured"
    And the JSON should have "enabled"
    And the JSON at "enabled" should be ["authn"]

  Scenario: Enable and disable authenticator
    When I run the code:
    """
    $conjur.authenticator_enable("authn-k8s", "my-auth")
    $conjur.authenticator_list
    """
    Then the JSON at "enabled" should be ["authn", "authn-k8s/my-auth"]
    When I run the code:
    """
    $conjur.authenticator_disable("authn-k8s", "my-auth")
    $conjur.authenticator_list
    """
    Then the JSON at "enabled" should be ["authn"]

  Scenario: Get a list of OIDC providers
    When I run the code:
    """
    $conjur.authentication_providers("authn-oidc")
    """
    Then the providers list contains service id "keycloak"

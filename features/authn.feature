Feature: Authenticate with Conjur

  Background:
    Given I setup a keycloak authenticator

  Scenario: Authenticate with OIDC state and code
    When I retrieve the login url for OIDC authenticator "keycloak"
    And I retrieve auth info for the OIDC provider with username: "alice" and password: "alice"
    And I run the code:
    """
    $conjur.authenticator_enable "authn-oidc", "keycloak"
    Conjur::API.authenticator_authenticate("authn-oidc", "keycloak", options: @auth_body)
    """
    Then the JSON should have "payload"

Feature: Authenticate with Conjur

  Background:
    Given I setup a keycloak authenticator

  Scenario: Authenticate with OIDC code
    When I retrieve the provider details for OIDC authenticator "keycloak"
    And I retrieve auth info for the OIDC provider with username: "alice" and password: "alice"
    And I run the code:
    """
    $conjur.authenticator_enable "authn-oidc", "keycloak"
    Conjur::API.authenticator_authenticate("authn-oidc", "keycloak", options: @auth_body)
    """
    Then the JSON should have "payload"

  Scenario: Authenticate with OIDC code requesting unparsed result via GET method
    When I retrieve the provider details for OIDC authenticator "keycloak"
    And I retrieve auth info for the OIDC provider with username: "alice" and password: "alice"
    And I run the code:
    """
    $conjur.authenticator_enable "authn-oidc", "keycloak"
    Conjur::API.authenticator_authenticate_get("authn-oidc", "keycloak", options: @auth_body)
    """
    Then the response body contains: "payload"
    And the response includes headers

  Scenario: Authenticate with OIDC code requesting unparsed result via POST method
    When I retrieve the provider details for OIDC authenticator "keycloak"
    And I retrieve auth info for the OIDC provider with username: "alice" and password: "alice"
    And I run the code:
    """
    $conjur.authenticator_enable "authn-oidc", "keycloak"
    Conjur::API.authenticator_authenticate_post("authn-oidc", "keycloak", options: @auth_body)
    """
    Then the response body contains: "payload"
    And the response includes headers

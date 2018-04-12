Feature: When co-located with the Conjur server, the API can use the authn-local service to authenticate.

  Scenario: authn-local can be used to obtain an access token.
    When I run the code:
    """
    Conjur::API.authenticate_local "alice"
    """
    Then the JSON should have "payload"
    And I run the code:
    """
    JSON.parse(Base64.decode64(@result['payload']))
    """
    Then the JSON should have "sub"
    And the JSON should have "iat"

  Scenario: Conjur API supports construction from authn-local.
    When I run the code:
    """
    @api = Conjur::API.new_from_authn_local "alice"
    @api.token
    """
    Then the JSON should have "payload"

  Scenario: Conjur API will automatically refresh the token.
    When I run the code:
    """
    @api = Conjur::API.new_from_authn_local "alice"
    @api.token
    @api.force_token_refresh
    @api.token
    """
    Then the JSON should have "payload"

  Scenario: Conjur API accepts service_id / authn_type for authn-local
    When I run the code:
    """
    Conjur::API.authenticate_local "alice", service_id: "service-id", authn_type: "authn-type"
    """
    Then the JSON should have "payload"

   Scenario: authn_authenticate_local will pass on service_id / authn_type
    When I run the code:
    """
    JSON.parse(Conjur::API.url_for(:authn_authenticate_local, "alice", nil, nil, nil, "service-id", "authn-type"))
    """
    Then the JSON at "service_id" should be "service-id"
    And the JSON at "authn_type" should be "authn-type"

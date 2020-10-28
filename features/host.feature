Feature: Host object

  Scenario: API key of a newly created host is available and valid
    Given a new host
    Then I can run the code:
    """
    expect(@host.exists?).to be(true)
    expect(@host.api_key).to be
    Conjur::API.new_from_key(@host.login, @host.api_key).token
    """

  # Rotation of own API key should be done via `Conjur::API.rotate_api_key()`
  Scenario: Host's own API key cannot be rotated with an API key
    Given a new host
    Then this code should fail with "You cannot rotate your own API key via this method"
    """
    host = Conjur::API.new_from_key(@host.login, @host.api_key).resource(@host.id)
    host.rotate_api_key
    """

  # Rotation of own API key should be done via `Conjur::API.rotate_api_key()`
  Scenario: Host's own API key cannot be rotated with a token
    Given a new host
    Then this code should fail with "You cannot rotate your own API key via this method"
    """
    token = Conjur::API.new_from_key(@host.login, @host.api_key).token

    host = Conjur::API.new_from_token(token).resource(@host.id)
    host.rotate_api_key
    """

  Scenario: Delegated host's API key can be rotated with an API key
    Given a new delegated host
    Then I can run the code:
    """
    delegated_host_resource = Conjur::API.new_from_key(@host_owner.login, @host_owner_api_key).resource(@host.id)
    api_key = delegated_host_resource.rotate_api_key
    Conjur::API.new_from_key(delegated_host_resource.login, api_key).token
    """

  Scenario: Delegated host's API key can be rotated with a token
    Given a new delegated host
    Then I can run the code:
    """
    token = Conjur::API.new_from_key(@host_owner.login, @host_owner_api_key).token

    delegated_host_resource = Conjur::API.new_from_token(token).resource(@host.id)
    api_key = delegated_host_resource.rotate_api_key
    Conjur::API.new_from_key(delegated_host_resource.login, api_key).token
    """

Feature: Display Host object fields.

  Background:
    Given I run the code:
    """
    $conjur.load_policy 'bootstrap', <<-POLICY
    - !policy
      id: myapp
      body:
      - !layer
      
      - !host-factory
        layers: [ !layer ]
    POLICY
    hf = $conjur.resource('cucumber:host_factory:myapp')
    token = hf.create_token (Time.now+1.hour)
    host_id = "app-#{random_hex}"
    @host = Conjur::API.host_factory_create_host token.token, host_id
    """

  Scenario: API key of a newly created host is available and valid.
    Then I run the code:
    """
    expect(@host.api_key).to be
    Conjur::API.new_from_key(@host.login, @host.api_key).token
    """

  Scenario: API key of a a host can be rotated.
    Then I run the code:
    """
    host = Conjur::API.new_from_key(@host.login, @host.api_key).resource(@host.id)
    api_key = host.rotate_api_key
    Conjur::API.new_from_key(@host.login, api_key).token
    """

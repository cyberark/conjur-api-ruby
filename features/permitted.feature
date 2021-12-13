Feature: Check if a role has permission on a resource.

  Background:
    Given I run the code:
    """
    @host_id = "app-#{random_hex}"
    @test_user = "user$#{random_hex}"
    @test_host = "host?#{random_hex}"
    response = $conjur.load_policy 'root', <<-POLICY
    - !variable db-password

    - !layer myapp

    - !host #{@host_id}

    - !permit
      role: !layer myapp
      privilege: execute
      resource: !variable db-password

    - !policy
      id: test
      body:
        - !user #{@test_user}
        - !host #{@test_host}

    - !permit
      role: !user #{@test_user}@test
      privilege: execute
      resource: !variable db-password
    POLICY
    @host_api_key = response.created_roles["cucumber:host:#{@host_id}"]['api_key']
    expect(@host_api_key).to be
    """

  Scenario: Check if the current user has the privilege.
    When I run the code:
    """
    $conjur.resource('cucumber:variable:db-password').permitted? 'execute'
    """
    Then the result should be "true"

  Scenario: Check if a different user has the privilege.
    When I run the code:
    """
    $conjur.resource('cucumber:variable:db-password').permitted? 'execute', role: "cucumber:host:#{@host_id}"
    """
    Then the result should be "false"

  Scenario: Check if a different user from subpolicy has the privilege.
    When I run the code:
    """
    $conjur.resource('cucumber:variable:db-password').permitted? 'execute', role: "cucumber:user:#{@test_user}@test"
    """
    Then the result should be "true"

  Scenario: Check if a different host from subpolicy has the privilege.
    When I run the code:
    """
    $conjur.resource('cucumber:variable:db-password').permitted? 'execute', role: "cucumber:host:test/#{@test_host}"
    """
    Then the result should be "false"

  Scenario: Check if a different user has the privilege, while logged in as that user.
    When I run the code:
    """
    host_api = Conjur::API.new_from_key "host/#{@host_id}", @host_api_key
    host_api.resource('cucumber:variable:db-password').permitted? 'execute'
    """
    Then the result should be "false"

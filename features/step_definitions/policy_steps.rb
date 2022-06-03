Given(/^a new user$/) do
  @user_id = "user-#{random_hex}"
  @public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDd/PAcCL9rW/zAS7DRns/KYiAvRAEKxBu/0IF32z7x6YiMFcA2hmH4DMYaIY45Xlj7L9uTZamUlRZNjSS9Xm6Lhh7XGceIX2067/MDnH+or9xh5LZs6gb3x7QVtNz26Au5h5kP0xoJ+wpVxvY707BeSax/WQZI8akqd0fD1IqOoafWkcX0ucu5iIgDh08R7zq3vrDHEK7+SoYo9ncHfmOUJ5lmImGiU/WMqM0OzN3RsgxJi/aaHjW1IASTY8TmAtTtjEsxbQXxRVUCAP9vWUZg7p3aqIB6sEP8skgncCUtHBQxUtE1XN8Q8NeFOzau6+9sQTXlPl8c/L4Jc4K96C75 #{@user_id}@example.com"
  response = $conjur.load_policy 'root', <<-POLICY
  - !user
    id: #{@user_id}
    uidnumber: 1000
    public_keys:
    - #{@public_key}
  POLICY
  @user = $conjur.resource("cucumber:user:#{@user_id}")
  @user_api_key = response.created_roles["cucumber:user:#{@user_id}"]['api_key']
  expect(@user_api_key).to be
end

Given(/^a new delegated user$/) do
  # Create a new host that is owned by that user
  step 'a new user'
  @user_owner = @user
  @user_owner_id = @user_id
  @user_owner_api_key = @user_api_key

  # Create a new user that is owned by the user created earlier
  @user_id = "user-#{random_hex}"
  response = $conjur.load_policy 'root', <<-POLICY
  - !user
    id: #{@user_id}
    owner: !user #{@user_owner_id}
  POLICY
  @user = $conjur.resource("cucumber:user:#{@user_id}")
  @user_api_key = response.created_roles["cucumber:user:#{@user_id}"]['api_key']
  expect(@user_api_key).to be
end

Given(/^a new group$/) do
  @group_id = "group-#{random_hex}"
  response = $conjur.load_policy 'root', <<-POLICY
  - !group
    id: #{@group_id}
    gidnumber: 1000
  POLICY
  @group = $conjur.resource("cucumber:group:#{@group_id}")
end

Given(/^a new host$/) do
  @host_id = "app-#{random_hex}"
  response = $conjur.load_policy 'root', <<-POLICY
  - !host #{@host_id}
  POLICY
  @host_api_key = response.created_roles["cucumber:host:#{@host_id}"]['api_key']
  expect(@host_api_key).to be
  @host = $conjur.resource("cucumber:host:#{@host_id}")
  @host.attributes['api_key'] = @host_api_key
end

Given(/^a new delegated host$/) do
  # Create an owner user
  step 'a new user'
  @host_owner = @user
  @host_owner_id = @user_id
  @host_owner_api_key = @user_api_key

  # Create a new host that is owned by that user
  @host_id = "app-#{random_hex}"
  response = $conjur.load_policy 'root', <<-POLICY
  - !host
    id: #{@host_id}
    owner: !user #{@host_owner_id}
  POLICY

  @host_api_key = response.created_roles["cucumber:host:#{@host_id}"]['api_key']
  expect(@host_api_key).to be
  @host = $conjur.resource("cucumber:host:#{@host_id}")
  @host.attributes['api_key'] = @host_api_key
end

Given(/^I setup a keycloak authenticator$/) do
    $conjur.load_policy 'root', <<-POLICY
    - !policy 
      id: conjur/authn-oidc/keycloak
      body: 
      - !webservice  
     
      - !variable provider-uri 
      - !variable client-id 
      - !variable client-secret 
      - !variable name
     
      - !variable claim-mapping 
       
      - !variable scope 
       
      - !variable nonce 
      - !variable state
    POLICY
    @provider_uri = $conjur.resource("cucumber:variable:conjur/authn-oidc/keycloak/provider-uri")
    @client_id = $conjur.resource("cucumber:variable:conjur/authn-oidc/keycloak/client-id")
    @client_secret = $conjur.resource("cucumber:variable:conjur/authn-oidc/keycloak/client-secret")
    @name = $conjur.resource("cucumber:variable:conjur/authn-oidc/keycloak/name")
    @claim_mapping = $conjur.resource("cucumber:variable:conjur/authn-oidc/keycloak/claim-mapping")
    @scope = $conjur.resource("cucumber:variable:conjur/authn-oidc/keycloak/scope")
    @nonce = $conjur.resource("cucumber:variable:conjur/authn-oidc/keycloak/nonce")
    @state = $conjur.resource("cucumber:variable:conjur/authn-oidc/keycloak/state")

    @provider_uri.add_value "https://keycloak:8443/auth/realms/master"
    @client_id.add_value "conjurClient"
    @client_secret.add_value "1234"
    @claim_mapping.add_value "map"
    @scope.add_value "openid"
    @nonce.add_value "dont-use-this-again"
    @state.add_value "test-state"
    @name.add_value "keycloak"
end

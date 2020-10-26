Feature: User object

  Background:

  Scenario: User has a uidnumber
    Given a new user
    Then I can run the code:
    """
    @user.uidnumber
    """
    Then the result should be "1000"

  Scenario: Logged-in user is the current_role
    Given a new user
    Then I can run the code:
    """
    expect($conjur.current_role(Conjur.configuration.account).id.to_s).to eq("cucumber:user:admin")
    """

  # Rotation of own API key should be done via `Conjur::API.rotate_api_key()`
  Scenario: User's own API key cannot be rotated with an API key
    Given a new user
    Then this code should fail with "You cannot rotate your own API key via this method"
    """
    user = Conjur::API.new_from_key(@user.login, @user_api_key).resource(@user.id)
    user.rotate_api_key
    """

  # Rotation of own API key should be done via `Conjur::API.rotate_api_key()`
  Scenario: User's own API key cannot be rotated with a token
    Given a new user
    Then this code should fail with "You cannot rotate your own API key via this method"
    """
    token = Conjur::API.new_from_key(@user.login, @user_api_key).token

    user = Conjur::API.new_from_token(token).resource(@user.id)
    user.rotate_api_key
    """

  Scenario: Delegated user's API key can be rotated with an API key
    Given a new delegated user
    Then I can run the code:
    """
    delegated_user_resource = Conjur::API.new_from_key(@user_owner.login, @user_owner_api_key).resource(@user.id)
    api_key = delegated_user_resource.rotate_api_key
    Conjur::API.new_from_key(delegated_user_resource.login, api_key).token
    """

  Scenario: Delegated user's API key can be rotated with a token
    Given a new delegated user
    Then I can run the code:
    """
    token = Conjur::API.new_from_key(@user_owner.login, @user_owner_api_key).token

    delegated_user_resource = Conjur::API.new_from_token(token).resource(@user.id)
    api_key = delegated_user_resource.rotate_api_key
    Conjur::API.new_from_key(delegated_user_resource.login, api_key).token
    """

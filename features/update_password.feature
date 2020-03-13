Feature: Change a user's password.
  Background:
    Given a new user

  Scenario: A user can set/change her password using the current API key.
    When I run the code:
    """
    Conjur::API.update_password @user_id, @user_api_key, 'SEcret12!!!!'
    @new_api_key = Conjur::API.login @user_id, 'SEcret12!!!!'
    """
    Then I can run the code:
    """
    Conjur::API.new_from_key(@user_id, @new_api_key).token
    """

Feature: Check if a resource exists.

  Background:
    Given I run the code:
    """
    $conjur.load_policy 'bootstrap', <<-POLICY
    - !group developers
    POLICY
    """

  Scenario: A created group exists
    When I run the code:
    """
    $conjur.resource('cucumber:group:developers').exists?
    """
    Then the result should be "true"

  Scenario: An un-created resource doesn't exist
    When I run the code:
    """
    $conjur.resource('cucumber:food:bacon').exists?
    """
    Then the result should be "false"

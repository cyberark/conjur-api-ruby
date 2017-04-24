Feature: Work with Variable values.

  Background:
    Given I run the code:
    """
    @variable_id = "password-#{random_hex}"
    $conjur.load_policy 'bootstrap', <<-POLICY
    - !variable #{@variable_id}
    POLICY
    @variable = $conjur.resource("cucumber:variable:#{@variable_id}")
    """

  Scenario: Initially the variable has no values
    When I run the code:
    """
    @variable.version_count
    """
    Then the result should be "0"

  Scenario: Add a value, retrieve the variable metadata and the value.
    Given I run the code:
    """
    @variable.add_value 'value-0'
    """
    When I run the code:
    """
    @variable.version_count
    """
    Then the result should be "1"
    And I run the code:
    """
    @variable.value
    """
    Then the result should be "value-0"

  Scenario: Retrieve a historical value.
    Given I run the code:
    """
    @variable.add_value 'value-0'
    @variable.add_value 'value-1'
    @variable.add_value 'value-2'
    """
    When I run the code:
    """
    @variable.value(1)
    """
    Then the result should be "value-0"

Feature: Work with Variable values.

  Background:
    Given I run the code:
    """
    @variable_id = "password"
    $conjur.load_policy 'root', <<-POLICY
    - !variable #{@variable_id}
    - !variable #{@variable_id}-2
    POLICY
    @variable = $conjur.resource("cucumber:variable:#{@variable_id}")
    @variable_2 = $conjur.resource("cucumber:variable:#{@variable_id}-2")
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

  Scenario: Retrieve multiple values in a batch
    Given I run the code:
    """
    @variable.add_value 'value-0'
    @variable_2.add_value 'value-2'
    """
    When I run the code:
    """
    $conjur.variable_values([ @variable, @variable_2 ].map(&:id))
    """
    Then the JSON should be:
    """
    {
      "cucumber:variable:password": "value-0",
      "cucumber:variable:password-2": "value-2"
    }
    """

Feature: audit with additional resources

  Background:
    Given I create the variable "$ns_foo"

  Scenario: with one additional resource
    When I create an api with the additional audit role "user:auditor1"
    And I check to see if I'm permitted to "read" variable "$ns_foo"
    Then an audit event for variable "$ns_foo" with action "check" and role "user:auditor1" is generated

  Scenario: with more than one additional resource
    When I create an api with the additional audit roles "user:auditor2,group:auditors"
    And I check to see if I'm permitted to "read" variable "$ns_foo"
    Then an audit event for variable "$ns_foo" with action "check" and roles "user:auditor2,group:auditors" is generated


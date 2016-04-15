Feature: audit with additional resources

  Background:
    Given I create the variable "$ns_foo"

  Scenario: with one additional resource
    When I create an api with the additional audit resource "webservice:ws1"
    And I check to see if I'm permitted to "read" variable "$ns_foo"
    Then an audit event for variable "$ns_foo" with action "check" and resource "webservice:ws1" is generated

  Scenario: with more than one additional resource
    When I create an api with the additional audit resources "webservice:ws1, webservice:ws2"
    And I check to see if I'm permitted to "read" variable "$ns_foo"
    Then an audit event for variable "$ns_foo" with action "check" and resources "webservice:ws1, webservice:ws2" is generated


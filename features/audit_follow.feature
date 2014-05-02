Feature: I can stream audit events in real time.

  Background:
    Given a role and resource

  Scenario: A permission check is audited
    When I follow the audit feed
    And I perform a permission check
    Then the permission check appears in the audit feed

Feature: Display audit entities list.

  Scenario: Audit show should have following properties
    Then I run the code:
    """
    $conjur.audit_show
    """

    Then the JSON should have the following:
      | 0/facility  |
      | 0/severity  |
      | 0/timestamp |
      | 0/hostname  |
      | 0/appname   |
      | 0/procid    |
      | 0/msgid     |
      | 0/sdata     |
      | 0/message   |

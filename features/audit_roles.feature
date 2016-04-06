Feature: audit with additional roles

  Scenario: with one additional role
    Given I successfully run `conjur variable create $ns_foo bar`

    When I evaluate the expression
    """
    $conjur.with_audit_roles('user:auditor1').resource('variable:$ns_foo').permitted?('read')
    """

    Then expression "true" is equal to
    """
    $conjur.audit_resource($conjur.resource('variable:$ns_foo')).any? do |e|
      e['action'] == 'check' && 
        e['roles'].include?('cucumber:user:auditor1')
    end
    """


  Scenario: with more than one additional role
    Given I successfully run `conjur variable create $ns_foo bar`

    When I evaluate the expression 
    """
    $conjur.with_audit_roles(['user:auditor2','group:auditors'])
      .resource('variable:$ns_foo')
      .permitted?('read')
    """

    Then expression "true" is equal to 
    """
    $conjur.audit_resource($conjur.resource('variable:$ns_foo')).any? do |e|
      e['action'] == 'check' && 
        Set.new(e['roles']).superset?(Set.new(['cucumber:user:auditor2','cucumber:group:auditors']))
    end
    """

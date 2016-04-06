Feature: audit with additional resources

  Scenario: with one additional resource
    Given I successfully run `conjur variable create $ns_foo bar`

    When I evaluate the expression
    """
    $conjur.with_audit_resources('webservice:ws1').resource('variable:$ns_foo').permitted?('read')
    """

    Then expression "true" is equal to
    """
    $conjur.audit_resource($conjur.resource('variable:$ns_foo')).any? do |e|
      e['action'] == 'check' && 
         e['resources'].include?('cucumber:webservice:ws1')
    end
    """

  Scenario: with more than one additional resource
    Given I successfully run `conjur variable create $ns_foo bar`

    When I evaluate the expression 
    """
    $conjur.with_audit_resources(['webservice:ws1','webservice:ws2'])
      .resource('variable:$ns_foo')
      .permitted?('read')
    """

    Then expression "true" is equal to 
    """
    $conjur.audit_resource($conjur.resource('variable:$ns_foo'))
      .any? do |e|
        e['action'] == 'check' && 
          Set.new(e['resources']).superset?(Set.new(['cucumber:webservice:ws1','cucumber:webservice:ws2']))
      end
    """

Feature: conjur bootstrap

	Background: Bootstrap
		Given I bootstrap

	Scenario: Expected resources exist
		Then expressions "$conjur.group('security_admin').exists?" and "true" are equal
		Then expressions "$conjur.group('auditors').exists?" and "true" are equal
		Then expressions "$conjur.group('pubkeys-1.0/key-managers').exists?" and "true" are equal
		Then expressions "$conjur.resource('webservice:conjur/authn-tv').exists?" and "true" are equal
		Then expressions "$conjur.resource('webservice:conjur/policy-loader').exists?" and "true" are equal
		Then expressions "$conjur.resource('webservice:conjur/policy-loader').ownerid" and "'cucumber:group:security_admin'" are equal
		Then expressions "$conjur.host('conjur/policy-loader').exists?" and "true" are equal
		Then expressions "$conjur.host('conjur/secrets-rotator').exists?" and "true" are equal
		Then expressions "$conjur.host('conjur/ldap-sync').exists?" and "true" are equal
		
	Scenario: security_admin group has the expected members
		Then expressions "$conjur.role('group:security_admin').members.map(&:member).map(&:roleid).sort.join(',')" and "'cucumber:host:conjur/authn-tv,cucumber:host:conjur/expiration,cucumber:host:conjur/ldap-sync,cucumber:host:conjur/policy-loader,cucumber:host:conjur/secrets-rotator,cucumber:user:admin'" are equal

	Scenario: security_admin can 'elevate' and 'reveal'
		Then expression "$conjur.resource('!:!:conjur').permitted_roles('elevate')" includes "$conjur.group('security_admin').roleid"
		Then expression "$conjur.resource('!:!:conjur').permitted_roles('reveal')" includes "$conjur.group('security_admin').roleid"

	Scenario: auditors can 'reveal'
		Then expression "$conjur.resource('!:!:conjur').permitted_roles('reveal')" includes "$conjur.group('auditors').roleid"

	Scenario: API keys are saved in variables
		Then expression "$conjur.resources(kind: 'variable').map(&:resourceid)" includes "'cucumber:variable:conjur/hosts/conjur/secrets-rotator/api-key'"

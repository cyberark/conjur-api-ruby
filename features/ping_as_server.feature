Feature: Ping

Background:
	Given I login with my username and password
	And I receive an API key
	And I enroll a server
	And I switch to the server role

Scenario: Ping using the server enrollment key
	When I ping
	Then the request succeeds

Scenario: Server credentials do not work from a different host 
	Given I force the request IP address to 127.0.0.1
	When I ping
	Then the request fails with error 401

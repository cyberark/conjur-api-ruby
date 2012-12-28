Feature: Ping

Background:
	When I login with my username and password
	And I receive an API key

Scenario: Ping using an API key
	When I ping
	Then the request succeeds

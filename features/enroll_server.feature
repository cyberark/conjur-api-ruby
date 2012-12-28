Feature: Server enrollment

Background:
	When I login with my username and password
	And I receive an API key

Scenario: Enroll this server
	When I enroll a server
	Then the request succeeds
	Then I receive an enrollment key

Scenario: The server is granted no other roles by default
	Given I enroll a server
	And I switch to the server role
	When I list my roles
	Then the result contains 1 item

Scenario: The server can be granted other roles
	Given I enroll a server
	And I create a role
	And I grant the role to the server
	And I switch to the server role
	And I list my roles
	Then the result contains 2 items

	
Feature: Login

Scenario: Login with my username and password
	When I login with my username and password
	Then the request succeeds
	And I receive an API key

Scenario: Login with my username and password
	When I login with my username and invalid password
	Then the request fails with error 401
	



# v4.13.0

* Add GID handling utilities

# v4.12.0

* Add the API method `role_graph` for retrieving role relationships in bulk

# v4.11.2

* Patch rest-client's patch of mime-types to support lazy loading
* Remove 'wrong' dependency for faster loading

# v4.11.0

* Fixed bug retrieving `Variable#version_count`
* Include CONJUR_ENV in `Conjur.configuration`
* Add `cert_file` option to `Conjur.configuration`


# v.4.10.2
* Authn token is refetched before the expiration
* Support for configuration `sticky` option is discarded
* Resource#exists? refactored -- no overloading, code from exists.rb used
* Tests use Rspec v3 and reset configuration between test cases


# v.4.10.1 
* Resource#exists? returns true if access to resource is forbidden
* Thread-local configuration for working with different endpoints

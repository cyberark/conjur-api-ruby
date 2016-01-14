# v4.20.1

* Support ISO8601 duration strings as arguments in variable expiration methods.

# v4.20.0

* Add support for Host Factory functionality (replaces conjur-asset-host-factory plugin).
* Add support for sending audit events (replaces conjur-asset-audit-send plugin).
* Add support for variable expiration. Variable expiration is available in version 4.6 of the Conjur server.

# v4.19.1

* BUGFIX: Allow Configuration to parse several certs in a string

# v4.19.0

* Rename `sudo` to `elevate` throughout the spec and docstrings. This is an incompatible change, but it
occurs before the Conjur 4.5 server that implements `elevate` is released.

# v4.18.0

* Add method `global_privilege_permitted?` to facilitate working with Conjur 4.5 global privileges.

# v4.17.0

* Add handling for `X-Forwarded-For` and `X-Conjur-Privilege` ("conjur sudo")
* Transform embedded whitespace in certificate string into newlines

# v4.16.0
  * Add ssl_certificate option to allow certs to be provided as strings (helpful in heroku)
  * Add `Conjur::Configuration#apply_cert_config!` method to add certs from `#cert_file` and `#ssl_certificate` 
     to the default cert store.
# v4.15.0
 * Extensive documentation improvements
 * A few additional methoods, for example `Conjur::API#public_key_names`.

# v4.14.0

* Bump rest-client version, remove the troublesome mime-types patch
* Make sure SSL certificate verification is enabled
* Bugfix: Don't escape ids twice when listing records
* Add a stub so that require 'conjur-api' works
* Lots of doc updates

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

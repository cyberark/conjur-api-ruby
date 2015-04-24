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

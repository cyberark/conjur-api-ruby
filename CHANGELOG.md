# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](http://semver.org/spec/v2.0.0.html).

## Unreleased
### Changed
- Nothing should go in this section, please add to the latest unreleased version
  (and update the corresponding date), or add a new version.

## [5.4.1] - 2023-03-29
### Added
- Added authenticate wrapper to access unparsed response object (including headers).
  [cyberark/conjur-api-ruby#213](https://github.com/cyberark/conjur-api-ruby/pull/213)
- Support Ruby v3.1 and v3.2.
  [cyberark/conjur-api-ruby#220](https://github.com/cyberark/conjur-api-ruby/pull/220)

## [5.4.0] - 2022-08-16

### Added
- Added support for OIDC V2 authentication endpoint.
  [cyberark/conjur-api-ruby#207](https://github.com/cyberark/conjur-api-ruby/pull/207)
- Added support for OIDC authenticator providers endpoint.
  [cyberark/conjur-api-ruby#207](https://github.com/cyberark/conjur-api-ruby/pull/207)

### Changed
- Remove support for Ruby versions <2.7 which are [end of life](https://endoflife.date/ruby).
  [cyberark/conjur-api-ruby#206](https://github.com/cyberark/conjur-api-ruby/pull/206)
- Adding operation call to fetch authentication providers
  [cyberark/conjur-api-ruby#206](https://github.com/cyberark/conjur-api-ruby/pull/206)

## [5.3.7] - 2021-12-28

### Changed
- Change addressable gem dependency.
  [cyberark/conjur-api-ruby#199](https://github.com/cyberark/conjur-api-ruby/pull/199)
- Update to use automated release process

## [5.3.6] - 2021-12-09

### Changed
- Support ruby-3.0.2.
  [cyberark/conjur-api-ruby#197](https://github.com/cyberark/conjur-api-ruby/pull/197)

## [5.3.5] - 2021-05-04

### Added
- Add `rest_client_options` option to `Conjur.configuration`. This allows users to
  configure the RestClient instance used by Conjur API to communicate with the Conjur 
  server.
  [cyberark/conjur-api-ruby#188](https://github.com/cyberark/conjur-api-ruby/issues/188)

### Changed
- Replace monkey patching `RestClient::Request` with defaults on `Conjur.configuration.rest_client_options`
  in order to limit the scope of the default `:ssl_cert_store` option only to inside
  Conjur API. 
  [cyberark/conjur-api-ruby#188](https://github.com/cyberark/conjur-api-ruby/issues/188)

## [5.3.4] - 2020-10-29

### Changed
- When rotating the currently logged in user's/host's API key, we now explictily
  prevent use of `resource({own_id}).rotate_api_key` for that action as the
  `Conjur::API.rotate_api_key` should be used instead for that. This change is a
  downstream enforcement of the stricter key rotation requirements on the server
  covered by [this](https://github.com/cyberark/conjur/security/advisories/GHSA-qhjf-g9gm-64jq)
  security bulletin.
  [cyberark/conjur-api-ruby#181](https://github.com/cyberark/conjur-api-ruby/issues/181)

## [5.3.3] - 2020-08-18
### Changed
- Release process is updated to ensure that the published Ruby Gem matches a tag in this repository,
  so that consumers of this gem can always reference the correct source code included in any given version.
  [cyberark/conjur-api-ruby#173](https://github.com/cyberark/conjur-api-ruby/issues/173)

## 5.3.2 - 2018-09-24
### Added
- Add `Conjur::API.authenticator_list`, `Conjur::API.authenticator_enable`, and
  ``Conjur::API.authenticator_disable` to inspect and manage authenticator status.

## [5.3.1] - 2018-09-24
### Added
- Updates URI path parameter escaping to consistently encode resource ids

## [5.3.0] - 2018-06-19
### Added
- Add `Conjur::API.ldap_sync_policy` for fetching the LDAP sync policy.

## 5.2.1 - 0000-00-00
### Fixed
- Fix `Conjur::BuildObject#build_object` so it only tries to create
  instances of objects for classes that inherit from BaseObject.

### Added
- require `openssl` before using it.

## 5.2.0 - 0000-00-00
### Added
- Adds support for the Role endpoint for searching and paging Role Members
- Adds additional escaping to URL parameters on requests to handle special characters (e.g. spaces)

## [5.1.0] - 2017-12-19
### Added
- Introduces backwards compatibility with Conjur 4.x for most API methods.
- Adds the configuration setting `version`, which is auto-populated from the environment variable `CONJUR_VERSION`.
- Adds support for the `authn-local` service, which can be used when the API client runs on the server.

## [5.0.0] - 2017-09-19
### Added
- Provides compatibility with [cyberark/conjur](https://github.com/cyberark/conjur), Conjur 5 CE.

### Changed
- Changed license to Apache 2.0
- *5.0.0-beta.4*
- - Support for batch secret retrieval.
- *v5.0.0-beta.3*
- - Removed hard dependency on older version of `rest-client` gem.
- *v5.0.0-beta.1*
- - Migrated to be compatible with Conjur 5 API.

## [4.31.0] - 2017-03-27
### Added
- Internal refactor to improve performance and facilitate caching.

## [4.30.0] - 2017-03-07
### Added
- The following enhancements require Conjur server 4.9.1.0 or later:
- Supports filter and pagination of role-listing methods.
- Supports non-recursive retrieval of role memberships.
- Supports the +role+ field on `Conjur::RoleGrant`.
- On older server versions, the new options will be ignored by the server.

## [4.29.2] - 2017-02-22
### Added
- `Conjur::API#resources` now supports `:owner` to retrieve all resources owned (directly or indirectly) by the indicated role. This capability has always been provided by the service, but was not exposed by the Ruby API.

## 4.29.1 - 0000-00-00
### Added
-  `Conjur::API#audit` now supports `:has_annotation` to retrieve audit events for resources annotated with the given name.

## [4.29.0] - 2017-02-01
### Added
- Add `Conjur::API#new_from_token_file` to create an API instance from a file which contains an access token, which should be periodically updated by another process.

## 4.28.2 - 0000-00-00
### Added
- Make sure certificate file is readable before trying to use it.

## [4.28.1] - 2016-11-30
### Added
- `Conjur::API#ldap_sync_policy` now returns log events generated when
  showing a policy.

## [4.28.0] - 2016-11-16
### Added
- Add `Conjur::API#ldap_sync_policy` to fetch the policy to use to
  bring Conjur and the LDAP server into sync.

### Removed
- Remove `Conjur::API#ldap_sync_now` and `Conjur::API#ldap_sync_jobs`

## 4.27.0 - 0000-00-00
### Added
- Add `Conjur::API#resources_permitted?"
- `Conjur::API#ldap_sync_now` now accepts an options Hash which will
  be passed on to the `/sync` entrypoint. The old argument list is
  maintained for backwards compatibility.
-  `Conjur::Api#resources` now supports `:has_annotation` for
  retrieving Conjur resources that have an annotation with the given
  name.

## [4.26.0] - 2016-07-01
### Added
- expose admin_option in the role graph (only populated by Conjur 4.8 and later)

## [4.25.1] - 2016-06-22
### Fixed
- Fix token refresh when using `with_privilege`, `with_audit_roles`,
  and `with_audit_resources`.

## [4.25.0] - 2016-06-17
### Added
- Add a workaround for a bug in Conjur <4.7 where long-running operations
  (such as policy load) would sometimes fail with 404 after five minutes.

## [4.24.1] - 2016-06-10
### Changed
- Clarify the handling of the dry-run argument to `Conjur::API#ldap_sync_now`.

## [4.24.0] - 2016-05-24
### Added
- Add `Conjur::API#ldap_sync_now` (requires Conjur 4.7 or later).
- Don't trust the system clock and don't check token validity. Rely on the server to verify the token instead, and only try to refresh if enough time has passed locally (using monotonic clock for reference where available).
- Don't try refreshing the token if the required credentials are not available.

## [4.23.0] - 2016-04-22
### Added
- Add `with_audit_roles` and `with_audit_resources` to `Conjur::API`
  to add additional roles and resources to audit records generated by
  requests

### Fixed
- Fix encoding of spaces in some urls.

## [4.22.1] - 2016-04-13
### Added
- `bootstrap` creates host and webservice `conjur/expiration`.

## [4.22.0] - 2016-03-08
### Added
- Add `show_expired` argument to `Conjur::Variable#value` to allow
  retrieval of values of expired variables.
- Properly assign ownership of bootstrap-created webservice resources to the `security_admin` group.

## [4.21.0] - 2016-03-02
### Added
- Add extensible Bootstrap commands as API methods.
- `bootstrap` grants `reveal` and `elevate` to the `security_admin` group.
- `bootstrap` creates `webservice:authn-tv`.
- `bootstrap` creates an `auditors` group and gives `reveal` privilege to it.

## [4.20.1] - 2016-02-18
### Fixed
- BUGFIX: Better handling for unicode and special characters in user ids.

## [4.20.0] - 2016-02-05
### Added
- Add support for Host Factory functionality (replaces conjur-asset-host-factory plugin).
- Add support for sending audit events (replaces conjur-asset-audit-send plugin).
- Add support for variable expiration. Variable expiration is available in version 4.6 of the Conjur server.
- Add `Conjur::API` methods to querying service versions : `service_version`, `service_names`, `appliance_info`.
- Add `Conjur::API` method for querying server health: `appliance_health(remote_host=nil)`
- Support ISO8601 duration strings as arguments in variable expiration methods.
- Add support for CIDR restrictions

## 4.19.1 - 0000-00-00
### Fixed
- BUGFIX: Allow Configuration to parse several certs in a string

## [4.19.0] - 2015-08-28
### Changed
- Rename `sudo` to `elevate` throughout the spec and docstrings. This is an incompatible change, but it occurs before the Conjur 4.5 server that implements `elevate` is released.

## 4.18.0 - 0000-00-00
### Added
- Add method `global_privilege_permitted?` to facilitate working with Conjur 4.5 global privileges.

## 4.17.0 - 0000-00-00
### Added
- Add handling for `X-Forwarded-For` and `X-Conjur-Privilege` ("conjur sudo")
- Transform embedded whitespace in certificate string into newlines

## [4.16.0] - 2015-04-28
### Added
- Add ssl_certificate option to allow certs to be provided as strings (helpful in heroku)
- Add `Conjur::Configuration#apply_cert_config!` method to add certs from `#cert_file` and `#ssl_certificate` to the default cert store.

## [4.15.0] - 2015-04-23
### Added
- Extensive documentation improvements
- A few additional methoods, for example `Conjur::API#public_key_names`.

## [4.14.0] - 2015-03-26
### Added
- Bump rest-client version, remove the troublesome mime-types patch
- Make sure SSL certificate verification is enabled
- Bugfix: Don't escape ids twice when listing records
- Add a stub so that require 'conjur-api' works
- Lots of doc updates

## [4.13.0] - 2015-02-11
### Added
- Add GID handling utilities

## [4.12.0] - 2015-01-27
### Added
- Add the API method `role_graph` for retrieving role relationships in bulk

## 4.11.2 - 0000-00-00
### Added
- Patch rest-client's patch of mime-types to support lazy loading

### Removed
- Remove 'wrong' dependency for faster loading

## 4.11.0 - 0000-00-00
### Fixed
- Fixed bug retrieving `Variable#version_count`
- Include CONJUR_ENV in `Conjur.configuration`

### Added
- Add `cert_file` option to `Conjur.configuration`

## [4.10.2] - 2014-09-22
### Added
- Authn token is refetched before the expiration
- Support for configuration `sticky` option is discarded
- Resource#exists? refactored -- no overloading, code from exists.rb used
- Tests use Rspec v3 and reset configuration between test cases

## [4.10.1] - 2014-09-04
### Added
- Resource#exists? returns true if access to resource is forbidden
- Thread-local configuration for working with different endpoints

## [4.10.0] - 2014-08-15
### Added
- User#update
- Added Users#find_users

## [4.9.2] - 2014-08-05
### Changed
- Always construct Heroku service names that are valid Heroku names
- authz resource#exists? anticipates a result of 403 Forbidden, and interprets this as true
- Provide a method to detect whether each configuration setting has been explicitly set via the environment

## [4.9.1] - 2014-07-17
### Changed
- Require rest-client gem version 1.6.7, as version 1.7 has bugs in SSL certificate trust options

## [4.9.0] - 2014-06-06
### Changed
- Layer and Pubkeys are now part of the core API

## [4.8.0] - 2014-05-23
### Added
- Variable#variable_values, batch fetching of variables to support the new conjur env command

## [4.7.2] - 2014-03-18

## [4.7.1] - 2014-03-13

## [4.6.1] - 2014-02-28

## [4.6.0] - 2014-01-11

## [4.4.1] - 2013-12-23

## [4.4.0] - 2013-12-23

## [4.3.0] - 2013-11-19

## [4.1.1] - 2013-10-24

## [2.7.1] - 2013-10-24

## [4.0.0] - 2013-10-17

## [2.5.1] - 2013-07-26

## [2.4.0] - 2013-06-05

## [2.3.1] - 2013-06-03

## [2.2.3] - 2013-05-31

## [2.2.2] - 2013-05-23

## [2.2.1] - 2013-05-20

## [2.2.0] - 2013-05-16

## [2.1.8] - 2013-05-15

## [2.1.7] - 2013-05-10

## [2.1.6] - 2013-04-30

## [2.1.5] - 2013-04-24

## [2.1.4] - 2013-04-24

## [2.1.3] - 2013-04-12

## [2.1.2] - 2013-04-12

## [2.1.1] - 2013-03-29

## [2.1.0] - 2013-03-25

## [2.0.1] - 2013-03-14

## [2.0.0] - 2013-13-12

[Unreleased]: https://github.com/cyberark/conjur-api-ruby/compare/v5.4.1...HEAD
[5.4.1]: https://github.com/cyberark/conjur-api-ruby/compare/v5.4.0...v5.4.1
[5.4.0]: https://github.com/cyberark/conjur-api-ruby/compare/v5.3.7...v5.4.0
[5.3.7]: https://github.com/cyberark/conjur-api-ruby/compare/v5.3.6...v5.3.7
[5.3.6]: https://github.com/cyberark/conjur-api-ruby/compare/v5.3.5...v5.3.6
[5.3.5]: https://github.com/cyberark/conjur-api-ruby/compare/v5.3.4...v5.3.5
[5.3.4]: https://github.com/cyberark/conjur-api-ruby/compare/v5.3.3...v5.3.4
[5.3.3]: https://github.com/cyberark/conjur-api-ruby/compare/v5.3.1...v5.3.3
[5.3.1]: https://github.com/cyberark/conjur-api-ruby/compare/v5.3.0...v5.3.1
[5.3.0]: https://github.com/cyberark/conjur-api-ruby/compare/v5.1.0...v5.3.0
[5.1.0]: https://github.com/cyberark/conjur-api-ruby/compare/v5.0.0...v5.1.0
[5.0.0]: https://github.com/cyberark/conjur-api-ruby/compare/v4.31.0...v5.0.0
[4.31.0]: https://github.com/cyberark/conjur-api-ruby/compare/v4.30.0...v4.31.0
[4.30.0]: https://github.com/cyberark/conjur-api-ruby/compare/v4.29.2...v4.30.0
[4.29.2]: https://github.com/cyberark/conjur-api-ruby/compare/v4.29.0...v4.29.2
[4.29.0]: https://github.com/cyberark/conjur-api-ruby/compare/v4.28.1...v4.29.0
[4.28.1]: https://github.com/cyberark/conjur-api-ruby/compare/v4.28.0...v4.28.1
[4.28.0]: https://github.com/cyberark/conjur-api-ruby/compare/v4.26.0...v4.28.0
[4.26.0]: https://github.com/cyberark/conjur-api-ruby/compare/v4.25.1...v4.26.0
[4.25.1]: https://github.com/cyberark/conjur-api-ruby/compare/v4.25.0...v4.25.1
[4.25.0]: https://github.com/cyberark/conjur-api-ruby/compare/v4.24.1...v4.25.0
[4.24.1]: https://github.com/cyberark/conjur-api-ruby/compare/v4.24.0...v4.24.1
[4.24.0]: https://github.com/cyberark/conjur-api-ruby/compare/v4.23.0...v4.24.0
[4.23.0]: https://github.com/cyberark/conjur-api-ruby/compare/v4.22.1...v4.23.0
[4.22.1]: https://github.com/cyberark/conjur-api-ruby/compare/v4.22.0...v4.22.1
[4.22.0]: https://github.com/cyberark/conjur-api-ruby/compare/v4.21.0...v4.22.0
[4.21.0]: https://github.com/cyberark/conjur-api-ruby/compare/v4.20.1...v4.21.0
[4.20.1]: https://github.com/cyberark/conjur-api-ruby/compare/v4.20.0...v4.20.1
[4.20.0]: https://github.com/cyberark/conjur-api-ruby/compare/v4.19.1...v4.20.0
[4.19.1]: https://github.com/cyberark/conjur-api-ruby/compare/v4.19.0...v4.19.1
[4.19.0]: https://github.com/cyberark/conjur-api-ruby/compare/v4.16.0...v4.19.0
[4.16.0]: https://github.com/cyberark/conjur-api-ruby/compare/v4.15.0...v4.16.0
[4.15.0]: https://github.com/cyberark/conjur-api-ruby/compare/v4.14.0...v4.15.0
[4.14.0]: https://github.com/cyberark/conjur-api-ruby/compare/v4.13.0...v4.14.0
[4.13.0]: https://github.com/cyberark/conjur-api-ruby/compare/v4.12.0...v4.13.0
[4.12.0]: https://github.com/cyberark/conjur-api-ruby/compare/v4.10.2...v4.12.0
[4.10.2]: https://github.com/cyberark/conjur-api-ruby/compare/v4.10.1...v4.10.2
[4.10.1]: https://github.com/cyberark/conjur-api-ruby/compare/v4.10.0...v4.10.1
[4.10.0]: https://github.com/cyberark/conjur-api-ruby/compare/v4.9.2...v4.10.0
[4.9.2]: https://github.com/cyberark/conjur-api-ruby/compare/v4.9.1...v4.9.2
[4.9.1]: https://github.com/cyberark/conjur-api-ruby/compare/v4.9.0...v4.9.1
[4.9.0]: https://github.com/cyberark/conjur-api-ruby/compare/v4.8.0...v4.9.0
[4.8.0]: https://github.com/cyberark/conjur-api-ruby/compare/v4.7.2...v4.8.0
[4.7.2]: https://github.com/cyberark/conjur-api-ruby/compare/v4.7.1...v4.7.2
[4.7.1]: https://github.com/cyberark/conjur-api-ruby/compare/v4.6.1...v4.7.1
[4.6.1]: https://github.com/cyberark/conjur-api-ruby/compare/v4.6.0...v4.6.1
[4.6.0]: https://github.com/cyberark/conjur-api-ruby/compare/v4.4.1...v4.6.0
[4.4.1]: https://github.com/cyberark/conjur-api-ruby/compare/v4.4.0...v4.4.1
[4.4.0]: https://github.com/cyberark/conjur-api-ruby/compare/v4.3.0...v4.4.0
[4.3.0]: https://github.com/cyberark/conjur-api-ruby/compare/v4.1.1...v4.3.0
[4.1.1]: https://github.com/cyberark/conjur-api-ruby/compare/v2.7.1...v4.1.1
[2.7.1]: https://github.com/cyberark/conjur-api-ruby/compare/v4.0.0...v2.7.1
[4.0.0]: https://github.com/cyberark/conjur-api-ruby/compare/v2.5.1...v4.0.0
[2.5.1]: https://github.com/cyberark/conjur-api-ruby/compare/v2.4.0...v2.5.1
[2.4.0]: https://github.com/cyberark/conjur-api-ruby/compare/v2.3.1...v2.4.0
[2.3.1]: https://github.com/cyberark/conjur-api-ruby/compare/v2.2.3...v2.3.1
[2.2.3]: https://github.com/cyberark/conjur-api-ruby/compare/v2.2.2...v2.2.3
[2.2.2]: https://github.com/cyberark/conjur-api-ruby/compare/v2.2.1...v2.2.2
[2.2.1]: https://github.com/cyberark/conjur-api-ruby/compare/v2.2.0...v2.2.1
[2.2.0]: https://github.com/cyberark/conjur-api-ruby/compare/v2.1.8...v2.2.0
[2.1.8]: https://github.com/cyberark/conjur-api-ruby/compare/v2.1.7...v2.1.8
[2.1.7]: https://github.com/cyberark/conjur-api-ruby/compare/v2.1.6...v2.1.7
[2.1.6]: https://github.com/cyberark/conjur-api-ruby/compare/v2.1.5...v2.1.6
[2.1.5]: https://github.com/cyberark/conjur-api-ruby/compare/v2.1.4...v2.1.5
[2.1.4]: https://github.com/cyberark/conjur-api-ruby/compare/v2.1.3...v2.1.4
[2.1.3]: https://github.com/cyberark/conjur-api-ruby/compare/v2.1.2...v2.1.3
[2.1.2]: https://github.com/cyberark/conjur-api-ruby/compare/v2.1.1...v2.1.2
[2.1.1]: https://github.com/cyberark/conjur-api-ruby/compare/v2.1.0...v2.1.1
[2.1.0]: https://github.com/cyberark/conjur-api-ruby/compare/v2.0.1...v2.1.0
[2.0.1]: https://github.com/cyberark/conjur-api-ruby/compare/v2.0.0...v2.0.1
[2.0.0]: https://github.com/cyberark/conjur-api-ruby/releases/tag/v2.0.0

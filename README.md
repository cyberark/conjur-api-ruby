# Conjur::API

Programmatic Ruby access to the Conjur API.

RDocs are available from the through the [Ruby Gem details page](https://rubygems.org/gems/conjur-api)

# Server Versions

The Conjur server comes in two major versions:

* **4.x** Conjur 4 is a commercial, non-open-source product, which is documented at [https://developer.conjur.net/](https://developer.conjur.net/).
* **5.x** Conjur 5 is open-source software, hosted and documented at [https://www.conjur.org/](https://www.conjur.org/).

You can use the `master` branch of this project, which is `conjur-api` version `5.x`, to do all of the following things against either type of Conjur server:

* Authenticate
* Fetch secrets
* Check permissions
* List roles, resources, members, memberships and permitted roles.
* Create hosts using host factory
* Rotate API keys

Use the configuration setting `Conjur.configuration.version` to select your server version, or set the environment variable `CONJUR_VERSION`. In either case, the valid values are `4` and `5`; the default is `5`.

If you are using Conjur server version `4.x`, you can also choose to use the `conjur-api` version `4.x`. In this case, the `Configuration.version` setting is not required (actually, it doesn't exist).

# Installation

Add this line to your application's Gemfile:

    gem 'conjur-api'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install conjur-api

# Usage

Connecting to Conjur is a two-step process:

* **Configuration** Instruct the API where to find the Conjur endpoint and how to secure the connection.
* **Authentication** Provide the API with credentials that it can use to authenticate.

## Configuration

The simplest way to configure the Conjur API is to use the configuration file stored on the machine.
If you have configured the machine with [conjur init](http://developer.conjur.net/reference/tools/init.html),
its default location is `~/.conjurrc`.

The Conjur configuration process also checks `/etc/conjur.conf` for global settings. This is typically used
in server environments.

For custom scenarios, the location of the file can be overridden using the `CONJURRC` environment variable.

You can load the Conjur configuration file using the following Ruby code:

```ruby
require 'conjur/cli'
Conjur::Config.load
Conjur::Config.apply
```

**Note** this code requires the [conjur-cli](https://github.com/conjurinc/cli-ruby) gem, which should also be in your
gemset or bundle.

## Authentication

Once Conjur is configured, the connection can be established like this:

```
conjur = Conjur::Authn.connect nil, noask: true
```

To [authenticate](http://developer.conjur.net/reference/services/authentication/authenticate.html), the API client must
provide a `login` name and `api_key`. The `Conjur::Authn.connect` will attempt the following, in order:

1. Look for `login` in environment variable `CONJUR_AUTHN_LOGIN`, and `api_key` in `CONJUR_AUTHN_API_KEY`
2. Look for credentials on disk. The default credentials file is `~/.netrc`. The location of the credentials file
can be overridden using the configuration file `netrc_path` option.
3. Prompt for credentials. This can be disabled using the option `noask: true`.

## Connecting Without Files

It's possible to configure and authenticate the Conjur connection without using any files, and without requiring
the `conjur-cli` gem.

To accomplish this, apply the configuration settings directly to the [Conjur::Configuration](https://github.com/conjurinc/api-ruby/blob/master/lib/conjur/configuration.rb)
object.

For example, specify the `account` and `appliance_url` (both of which are required) like this:

```
Conjur.configuration.account = 'my-account'
Conjur.configuration.appliance_url = 'https://conjur.mydomain.com/api'
```

You can also specify these values using environment variables, which is often a bit more convenient.
Environment variables are mapped to configuration variables by prepending `CONJUR_` to the all-caps name of the
configuration variable. For example, `appliance_url` is `CONJUR_APPLIANCE_URL`, `account` is `CONJUR_ACCOUNT`.

In either case, you will also need to configure certificate trust. For example:

```
OpenSSL::SSL::SSLContext::DEFAULT_CERT_STORE.add_file "/etc/conjur-yourorg.pem"
```

Once Conjur is configured, you can create a new API client by providing a `login` and `api_key`:

```
Conjur::API.new_from_key login, api_key
```

Note that if you are connecting as a [Host](http://developer.conjur.net/reference/services/directory/host), the login should be
prefixed with `host/`. For example: `host/myhost.example.com`, not just `myhost.example.com`.

## Contributing

We welcome contributions of all kinds to this repository. For instructions on how to get started and descriptions of our development workflows, please see our [contributing
guide][contrib].

[contrib]: https://github.com/cyberark/conjur-api-ruby/blob/master/CONTRIBUTING.md

## License

This repository is licensed under Apache License 2.0 - see [`LICENSE`](LICENSE) for more details.


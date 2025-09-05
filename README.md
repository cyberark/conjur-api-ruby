# CyberArk Secrets Manager API for Ruby

Programmatic Ruby access to the Secrets Manager API.

RDocs are available from the through the [Ruby Gem details page](https://rubygems.org/gems/conjur-api)

## Using conjur-api-ruby with Conjur Open Source 

Are you using this project with [Conjur Open Source](https://github.com/cyberark/conjur)? Then we 
**strongly** recommend choosing the version of this project to use from the latest [Conjur OSS 
suite release](https://docs.conjur.org/Latest/en/Content/Overview/Conjur-OSS-Suite-Overview.html). 
Conjur maintainers perform additional testing on the suite release versions to ensure 
compatibility. When possible, upgrade your Conjur version to match the 
[latest suite release](https://docs.conjur.org/Latest/en/Content/ReleaseNotes/ConjurOSS-suite-RN.htm); 
when using integrations, choose the latest suite release that matches your Conjur version. For any 
questions, please contact us on [Discourse](https://discuss.cyberarkcommons.org/).

# Installation

Add this line to your application's Gemfile:

    gem 'conjur-api'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install conjur-api

# Usage

Connecting to Secrets Manager is a two-step process:

* **Configuration** Instruct the API where to find the Secrets Manager endpoint and how to secure the connection.
* **Authentication** Provide the API with credentials that it can use to authenticate.

## Configuration

The simplest way to configure the Secrets Manager API is to use the configuration file stored on the machine.
If you have configured the machine with [Secrets Manager CLI](https://github.com/cyberark/conjur-cli-go),
its default location is `~/.conjurrc`.

For custom scenarios, the location of the file can be overridden using the `CONJURRC` environment variable.

You can load the Secrets Manager configuration file using the following Ruby code:

```ruby
require 'conjur/cli'
Conjur::Config.load
Conjur::Config.apply
```

## Authentication

Once Secrets Manager is configured, the connection can be established like this:

```
conjur = Conjur::Authn.connect nil, noask: true
```

To authenticate, the API client must
provide a `login` name and `api_key`. The `Conjur::Authn.connect` will attempt the following, in order:

1. Look for `login` in environment variable `CONJUR_AUTHN_LOGIN`, and `api_key` in `CONJUR_AUTHN_API_KEY`
2. Look for credentials on disk. The default credentials file is `~/.netrc`. The location of the credentials file
can be overridden using the configuration file `netrc_path` option.
3. Prompt for credentials. This can be disabled using the option `noask: true`.

## Connecting Without Files

It's possible to configure and authenticate the Secrets Manager connection without using any files, and without requiring
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

Once Secrets Manager is configured, you can create a new API client by providing a `login` and `api_key`:

```
Conjur::API.new_from_key login, api_key
```

Note that if you are connecting as a Host, the login should be
prefixed with `host/`. For example: `host/myhost.example.com`, not just `myhost.example.com`.

## Configuring RestClient

[Conjur::Configuration](https://github.com/conjurinc/api-ruby/blob/master/lib/conjur/configuration.rb)
allows optional configuration of the [RestClient](https://github.com/rest-client/rest-client)
instance used by Secrets Manager API to communicate with the Secrets Manager server, via the options hash
`Conjur.configuration.rest_client_options`.

The default value for the options hash is:
```ruby
{
  ssl_cert_store: OpenSSL::SSL::SSLContext::DEFAULT_CERT_STORE
}
```

For example, here's how you would configure the client to use a proxy and `ssl_ca_file` (instead of the default `ssl_cert_store`).
```ruby
Conjur.configuration.rest_client_options = {
    ssl_ca_file: "ca_certificate.pem",
    proxy: "http://proxy.example.com/"
}
```

## Contributing

We welcome contributions of all kinds to this repository. For instructions on how to get started and descriptions of our development workflows, please see our [contributing
guide][contrib].

[contrib]: https://github.com/cyberark/conjur-api-ruby/blob/main/CONTRIBUTING.md

## License

This repository is licensed under Apache License 2.0 - see [`LICENSE`](LICENSE) for more details.
